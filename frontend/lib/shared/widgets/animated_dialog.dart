import 'package:flutter/material.dart';

class AnimatedDialog {
  static Future<void> show(BuildContext context, {required String title, required String message, required IconData icon, required Color color}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, a1, a2, child) {
        final curveValue = Curves.elasticOut.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curveValue * 200, 0.0),
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
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
