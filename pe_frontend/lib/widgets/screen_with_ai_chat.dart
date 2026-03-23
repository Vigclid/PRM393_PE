import 'package:flutter/material.dart';
import 'package:pe_frontend/widgets/ai_chat_bubble.dart';

/// Wrapper widget để thêm AI chat bubble vào bất kỳ screen nào
class ScreenWithAIChat extends StatelessWidget {
  final Widget child;
  final String? productId;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  const ScreenWithAIChat({
    Key? key,
    required this.child,
    this.productId,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // FAB positioned
        if (floatingActionButton != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: floatingActionButton!,
          ),
        // AI Chat Bubble (rendered last so it's on top)
        AIChatBubble(productId: productId),
      ],
    );
  }
}
