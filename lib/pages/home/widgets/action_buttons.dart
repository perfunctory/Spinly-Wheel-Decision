import 'package:flutter/material.dart';
import 'package:lucky_wheel/core/constants/app_strings.dart';

/// Bottom action buttons on the Home page.
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.canSpin,
    required this.onSpin,
    required this.onEdit,
    required this.onTemplates,
  });

  final bool canSpin;
  final VoidCallback onSpin;
  final VoidCallback onEdit;
  final VoidCallback onTemplates;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // SPIN NOW — primary action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canSpin ? onSpin : null,
              icon: const Text('🎡', style: TextStyle(fontSize: 20)),
              label: const Text(AppStrings.spinNow),
            ),
          ),
          const SizedBox(height: 12),
          // EDIT WHEEL + TEMPLATES side by side
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text(AppStrings.editWheel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTemplates,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(AppStrings.templates),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
