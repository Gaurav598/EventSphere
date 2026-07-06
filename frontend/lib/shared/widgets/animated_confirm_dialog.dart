import 'package:flutter/material.dart';

class AnimatedConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final curveValue = Curves.easeOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curveValue * 100, 0.0)..scale(a1.value),
          alignment: Alignment.center,
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(height: 16),
                  Text(title, textAlign: TextAlign.center),
                ],
              ),
              content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(cancelText),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}
