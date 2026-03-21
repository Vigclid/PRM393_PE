import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pe_frontend/screens/feedback_screen.dart';
import '../api/bill_api.dart';
import '../models/cart.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isConfirmed = false;
  bool _isProcessing = false;
  bool _isSuccess = false;
  Timer? _paymentTimer;

  late final String _transactionCode;

  @override
  void initState() {
    super.initState();
    _transactionCode = "PAY${DateTime.now().millisecondsSinceEpoch}";
  }

  String get _paymentQRUrl =>
      "https://img.vietqr.io/image/OCB-CASS049204001504-qr-only.png?amount=${widget.total.toInt()}&addInfo=$_transactionCode&accountName=NGUYEN%20VIET%20NGUYEN";

  final String _bankUrl =
      "https://script.google.com/macros/s/AKfycbxHT2rsbazaMghhZJHZdtb1aXDnTmIBEFMN2ndH4cgKRg0JHS_dgVR8sLwJbvqaqWc9/exec";

  @override
  void dispose() {
    _paymentTimer?.cancel();
    super.dispose();
  }

  void _startPaymentPolling() {
    _paymentTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isSuccess) {
        timer.cancel();
        return;
      }
      await _checkPaid();
    });
  }

  Future<void> _checkPaid() async {
    try {
      final response = await http.get(Uri.parse(_bankUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List transactions = data['data'];
        if (transactions.isEmpty) return;

        final lastPaid = transactions.last;
        double paidAmount =
            double.tryParse(lastPaid["Giá trị"].toString()) ?? 0;
        String paidInfo = lastPaid["Mô tả"].toString();

        if (paidAmount >= widget.total && paidInfo.contains(_transactionCode)) {
          _paymentTimer?.cancel();

          setState(() => _isProcessing = true);

          try {
            await BillApi.checkout();
            setState(() {
              _isSuccess = true;
              _isProcessing = false;
            });

            _showSnackBar(
              "Payment and order creation successful!",
              Colors.green,
            );

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackScreen(items: widget.items),
                  ),
                );
              }
            });
          } catch (e) {
            setState(() => _isProcessing = false);
            _showSnackBar(
              "Payment received but order failed: $e",
              Colors.orange,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Payment check error: $e");
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _handleConfirmOrder() {
    setState(() {
      _isConfirmed = true;
    });
    _startPaymentPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.gold,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isConfirmed ? 'QR Payment' : 'Order Review',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isConfirmed ? _buildQRView() : _buildReviewView(),
      bottomNavigationBar: !_isConfirmed ? _buildBottomBar() : null,
    );
  }

  Widget _buildQRView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSuccess ? Icons.check_circle : Icons.pending_actions_rounded,
              color: _isSuccess ? Colors.greenAccent : Colors.amberAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isSuccess ? 'Payment Successful!' : 'Awaiting Payment...',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                _paymentQRUrl,
                width: 250,
                height: 250,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 250,
                  height: 250,
                  child: Center(
                    child: Text(
                      "Could not load QR code",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isSuccess) ...[
              const Text(
                "Please scan the code and keep content intact",
                style: TextStyle(color: AppColors.goldMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _transactionCode,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 8),
              const Text(
                "Confirming your order...",
                style: TextStyle(color: AppColors.gold),
              ),
            ],
            const SizedBox(height: 40),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(
                'Back to Home',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.surface, width: 50, height: 50),
            ),
          ),
          title: Text(
            item.product.name,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Qty: ${item.quantity} x \$${item.priceAtTime}',
            style: const TextStyle(color: AppColors.goldMuted),
          ),
          trailing: Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(color: AppColors.goldMuted, fontSize: 12),
              ),
              Text(
                '\$${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: FilledButton(
              onPressed: _handleConfirmOrder,
              child: const Text('Pay Now'),
            ),
          ),
        ],
      ),
    );
  }
}
