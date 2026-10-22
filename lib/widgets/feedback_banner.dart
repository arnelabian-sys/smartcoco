import 'package:flutter/material.dart';
import '../theme.dart';

enum FeedbackType { success, error, warning, info, loading }

class FeedbackBanner extends StatelessWidget {
  final FeedbackType type;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const FeedbackBanner({
    super.key,
    required this.type,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    switch (type) {
      case FeedbackType.success:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        icon = Icons.check_circle;
        break;
      case FeedbackType.error:
        bg = const Color(0xFFFDECEA);
        fg = AppColors.error;
        icon = Icons.error_outline;
        break;
      case FeedbackType.warning:
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFFB26A00);
        icon = Icons.warning_amber_rounded;
        break;
      case FeedbackType.info:
        bg = const Color(0xFFE8F1FB);
        fg = const Color(0xFF1565C0);
        icon = Icons.info_outline;
        break;
      case FeedbackType.loading:
        bg = AppColors.grey200;
        fg = AppColors.grey800;
        icon = Icons.hourglass_empty;
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: fg, fontSize: 14)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: fg),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}
