import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/stroke.dart';
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

  StreamSubscription? _subscription;

  final int _appStartTime = DateTime.now().millisecondsSinceEpoch;

  // ✅ FIX: Prevent duplicate processing
  final Set<String> _processedIds = {};

  @override
  void initState() {
    super.initState();
    _controller = DrawingController();
    _setup();
  }

  Future<void> _setup() async {
    await _firebaseService.init();

    if (!mounted) return;

    if (_firebaseService.pairId == null) {
      _askPairId();
      return;
    }

    _startListening();
  }

  void _startListening() {
    final stream = _firebaseService.listenToMessages();
    if (stream == null) return;

    _subscription = stream.listen((snapshot) {
      for (var doc in snapshot.docs) {
        // ✅ Prevent duplicate rendering
        if (_processedIds.contains(doc.id)) continue;
        _processedIds.add(doc.id);

        final data = doc.data() as Map<String, dynamic>;

        if ((data['timestamp'] ?? 0) < _appStartTime) continue;
        if (data['sender'] == _firebaseService.deviceId) continue;

        print("🔥 RECEIVED: $data");

        // ✅ STROKE
        if (data['type'] == 'stroke') {
          final stroke = Stroke.fromMap(data);

          if (stroke.points.isEmpty) continue;

          _controller.addRemoteStroke(stroke);
        }

        // ✅ CLEAR
        if (data['type'] == 'clear') {
          _controller.clearCanvas();
        }

        // ✅ POPUP
        if (data['type'] == 'popup') {
          if (!mounted) return;

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('📩 Message'),
              content: Text(data['message'] ?? ''),
            ),
          );
        }
      }
    });
  }

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

              _startListening();
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

    if (result.status == ExportStatus.success) {
      _showSnackBar('Saved', color: Colors.green);
    } else {
      _showSnackBar('Save failed', color: Colors.red);
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
      _showSnackBar('Share failed', color: Colors.red);
    }
  }

  void _showSnackBar(String msg, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
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
      body: Column(
        children: [
          Expanded(
            child: DrawingCanvas(
              controller: _controller,
              repaintKey: _canvasKey,
              firebaseService: _firebaseService,
            ),
          ),
          _BottomControls(controller: _controller),
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
    return Column(
      children: [
        ColorPalette(
          selectedColor: controller.selectedColor,
          onColorSelected: controller.setColor,
        ),
        Slider(
          value: controller.strokeWidth,
          min: 1,
          max: 30,
          onChanged: controller.setStrokeWidth,
        ),
      ],
    );
  }
}