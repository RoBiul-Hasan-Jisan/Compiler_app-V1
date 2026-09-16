import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A friendly empty state for any screen with no content yet — the app
/// never shows a truly blank screen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IdeMetrics.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: IdeColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: IdeMetrics.iconLg, color: IdeColors.accent),
            ),
            const SizedBox(height: IdeMetrics.spaceMd),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: IdeMetrics.spaceXs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: IdeColors.darkTextSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: IdeMetrics.spaceLg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
