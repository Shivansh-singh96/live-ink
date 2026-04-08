import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../services/firebase_service.dart';

class DrawingToolbar extends StatelessWidget implements PreferredSizeWidget {
  final DrawingController controller;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final FirebaseService firebaseService;

  const DrawingToolbar({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onShare,
    required this.firebaseService,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('LiveInk'),
      actions: [
        // ✅ UNDO
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed:
              controller.strokes.isEmpty ? null : controller.undo,
        ),

        // ✅ ERASER
        IconButton(
          icon: Icon(
            controller.isEraser
                ? Icons.brush
                : Icons.auto_fix_high,
          ),
          onPressed: controller.toggleEraser,
        ),

        // ✅ SEND MESSAGE
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => _send(context),
        ),

        // ✅ CLEAR CANVAS
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: controller.strokes.isEmpty
              ? null
              : () {
                  controller.clearCanvas();
                  firebaseService.sendClearCanvas(); // sync both devices
                },
        ),

        // ✅ SAVE
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
        ),

        // ✅ SHARE
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: onShare,
        ),
      ],
    );
  }

  void _send(BuildContext context) {
    final textController = TextEditingController(); // ✅ NEW instance

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Message'),
        content: TextField(
          controller: textController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();

              if (text.isEmpty) return;

              firebaseService.sendMessage(text);

              Navigator.pop(context); // ✅ close dialog
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}