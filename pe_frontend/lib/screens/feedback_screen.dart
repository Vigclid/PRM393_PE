import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/feedback_api.dart';
import '../models/cart.dart';
import '../theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  final List<CartItem> items;

  const FeedbackScreen({super.key, required this.items});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      _ratings[item.product.id] = 0;
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

  bool get _canSubmit {
    return widget.items.every((item) =>
        _ratings[item.product.id]! > 0 &&
        _controllers[item.product.id]!.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Product Review',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.goldMuted),
          onPressed: _goHome,
        ),
      ),
      body: Column(
        children: [
          // Header minh họa
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildFeedbackCard(widget.items[index]);
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 40),
          ),
          const SizedBox(height: 12),
          const Text(
            "How was your experience?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Your feedback helps us improve our service",
            style: TextStyle(color: AppColors.goldMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(CartItem item) {
    final productId = item.product.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.product.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.border,
                    child: const Icon(Icons.image, color: AppColors.goldMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.product.category,
                      style: const TextStyle(color: AppColors.goldMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),
          const Center(
            child: Text(
              "Rate this product",
              style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (starIndex) {
              return GestureDetector(
                onTap: () => setState(() => _ratings[productId] = starIndex + 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starIndex < _ratings[productId]!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controllers[productId],
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tell us more about the product quality...',
              hintStyle: const TextStyle(color: AppColors.goldMuted, fontSize: 13),
              fillColor: AppColors.background.withOpacity(0.5),
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
            ),
          ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton(
              onPressed: (_canSubmit && !_isSubmitting) ? _submitFeedback : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                backgroundColor: AppColors.gold,
                disabledBackgroundColor: AppColors.border,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onGold),
                    )
                  : const Text(
                      'Submit Reviews',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting ? null : _goHome,
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: AppColors.goldMuted, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Giữ nguyên logic cũ
  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      for (var item in widget.items) {
        await FeedbackApi.createNewFeedback(
          productId: item.product.id,
          rating: _ratings[item.product.id]!,
          comment: _controllers[item.product.id]!.text.trim(),
        );
      }
      if (!mounted) return;
      _showSuccess();
      _goHome();
    } catch (e) {
      _showError("Failed to submit feedback. Please try again.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Thank you for your feedback!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}