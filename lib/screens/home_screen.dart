import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../services/export_service.dart';
import '../widgets/color_palette.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DrawingController _controller;
  final ExportService _exportService = ExportService();
  final GlobalKey _canvasKey = GlobalKey();
  bool _isExporting = false;

  final FirebaseService _firebaseService = FirebaseService();

  String? _lastMessageId;
  StreamSubscription? _subscription;

  final int _appStartTime = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _controller = DrawingController();

    _setup(); // ✅ correct flow
  }

  // ✅ Proper async setup
  Future<void> _setup() async {
    await _firebaseService.init();

    if (!mounted) return;

    if (_firebaseService.pairId == null) {
      _askPairId();
      return; // wait until user enters
    }

    _startListening();
  }

  // ✅ Start Firestore listener
  void _startListening() {
    final stream = _firebaseService.listenToMessages();
    if (stream == null) return;

    _subscription = stream.listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      if ((data['timestamp'] ?? 0) < _appStartTime) return;

      if (_lastMessageId == doc.id) return;
      _lastMessageId = doc.id;

      if (data['sender'] == _firebaseService.deviceId) return;

      if (data['type'] == 'popup') {
        if (!mounted) return;

        Future.delayed(Duration.zero, () {
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('📩 New Message'),
              content: Text(data['message'] ?? ''),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    });
  }

  // ✅ Ask for Pair ID
  void _askPairId() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Enter Pair Code"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              final id = controller.text.trim();

              if (id.isEmpty) return;

              await _firebaseService.setPairId(id);

              if (!mounted) return;
              Navigator.pop(context);

              _startListening(); // ✅ start AFTER setting
            },
            child: const Text("Connect"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final result =
        await _exportService.saveDrawing(boundaryKey: _canvasKey);

    setState(() => _isExporting = false);
    if (!mounted) return;

    switch (result.status) {
      case ExportStatus.success:
        _showSnackBar('✅ Drawing saved to Documents',
            color: Colors.green);
        break;

      case ExportStatus.failure:
        _showSnackBar('❌ Save failed: ${result.errorMessage}',
            color: Colors.red);
        break;
    }
  }

  Future<void> _handleShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final result =
        await _exportService.shareDrawing(boundaryKey: _canvasKey);

    setState(() => _isExporting = false);
    if (!mounted) return;

    if (result.status == ExportStatus.failure) {
      _showSnackBar('❌ Share failed: ${result.errorMessage}',
          color: Colors.red);
    }
  }

  void _showSnackBar(String message,
      {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DrawingToolbar(
        controller: _controller,
        onSave: _handleSave,
        onShare: _handleShare,
        firebaseService: _firebaseService,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: DrawingCanvas(
                  controller: _controller,
                  repaintKey: _canvasKey,
                ),
              ),
              _BottomControls(controller: _controller),
            ],
          ),
          if (_isExporting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child:
                      CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final DrawingController controller;

  const _BottomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPalette(
                selectedColor: controller.selectedColor,
                onColorSelected: controller.setColor,
              ),
              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 100),
                      width: controller.strokeWidth,
                      height: controller.strokeWidth,
                      decoration: BoxDecoration(
                        color: controller.isEraser
                            ? Colors.grey
                            : controller.selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: controller.strokeWidth,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: controller.isEraser
                            ? Colors.grey
                            : controller.selectedColor,
                        onChanged:
                            controller.setStrokeWidth,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${controller.strokeWidth.round()}px',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}