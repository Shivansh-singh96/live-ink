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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AppBar(
          title: const Text(
            'LiveInk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'Undo',
              onPressed: controller.strokes.isEmpty ? null : controller.undo,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Send Message',
              onPressed: () {
                _showSendDialog(context);
              },
            ),
            IconButton(
              icon: Icon(
                controller.isEraser
                    ? Icons.brush_rounded
                    : Icons.auto_fix_high_rounded,
              ),
              tooltip: controller.isEraser ? 'Switch to Brush' : 'Eraser',
              style: controller.isEraser
                  ? IconButton.styleFrom(backgroundColor: Colors.white24)
                  : null,
              onPressed: controller.toggleEraser,
            ),
            IconButton(
              icon: const Icon(Icons.save_alt_rounded),
              tooltip: 'Save Drawing',
              onPressed: onSave,
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Drawing',
              onPressed: onShare,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear Canvas',
              onPressed: controller.strokes.isEmpty
                  ? null
                  : () => _confirmClear(context),
            ),
          ],
        );
      },
    );
  }

  // Custom message 
  void _showSendDialog(BuildContext context) {
    final TextEditingController controllerText = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: TextField(
          controller: controllerText,
          decoration: const InputDecoration(
            hintText: 'Type your message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controllerText.text.trim();

              if (text.isNotEmpty) {
                firebaseService.sendMessage(text);
              }

              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
            'This will erase all strokes. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clear();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}