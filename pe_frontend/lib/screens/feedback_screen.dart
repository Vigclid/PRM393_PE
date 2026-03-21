import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/feedback_api.dart';
import '../models/cart.dart';
import '../theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  final List<CartItem> items; // Danh sách sản phẩm vừa thanh toán

  const FeedbackScreen({super.key, required this.items});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // Lưu trữ đánh giá cho từng sản phẩm
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      _ratings[item.product.id] = 0; // Mặc định 0 sao
      _controllers[item.product.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Kiểm tra xem đã đủ điều kiện để bấm "Feedback Now" chưa
  // Điều kiện: Tất cả sản phẩm phải có sao > 0 và có comment
  bool get _canSubmit {
    return widget.items.every((item) {
      final productId = item.product.id;
      return _ratings[productId]! > 0 &&
          _controllers[productId]!.text.trim().isNotEmpty;
    });
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      // Gửi feedback cho từng sản phẩm
      for (var item in widget.items) {
        final productId = item.product.id;
        await FeedbackApi.createNewFeedback(
          productId: productId,
          rating: _ratings[productId]!,
          comment: _controllers[productId]!.text.trim(),
        );
      }
      if (!mounted) return;
      _goHome();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false, // Không cho quay lại checkout
        title: const Text(
          'Product Feedback',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final productId = item.product.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Phần chọn sao
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (starIndex) {
                          return IconButton(
                            onPressed: () {
                              setState(
                                () => _ratings[productId] = starIndex + 1.0,
                              );
                            },
                            icon: Icon(
                              starIndex < _ratings[productId]!
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.gold,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Ô nhập comment
                      TextField(
                        controller: _controllers[productId],
                        onChanged: (_) =>
                            setState(() {}), // Rebuild để check nút disable
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Share your thoughts about this product...',
                          hintStyle: TextStyle(
                            color: AppColors.goldMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Nút điều hướng
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_canSubmit && !_isSubmitting)
                  ? _submitFeedback
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Feedback Now'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isSubmitting ? null : _goHome,
              child: const Text(
                'Feedback Later',
                style: TextStyle(color: AppColors.goldMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
