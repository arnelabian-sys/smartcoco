import 'package:flutter/material.dart';
import '../theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusChip({super.key, required this.label, this.color, this.icon});

  factory StatusChip.ok([String label = 'OK']) =>
      StatusChip(label: label, color: AppColors.primary, icon: Icons.check_circle);

  factory StatusChip.down([String label = 'Down']) =>
      StatusChip(label: label, color: AppColors.error, icon: Icons.cancel);

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.grey600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
