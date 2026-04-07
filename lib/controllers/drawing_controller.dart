import 'package:flutter/material.dart';
import '../models/stroke.dart';
import 'dart:math';

class DrawingController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final Set<String> _strokeIds = {}; // ✅ prevent duplicates

  List<Offset> _currentPoints = [];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  bool _isEraser = false;

  // ========================
  // GETTERS
  // ========================
  List<Stroke> get strokes => List.unmodifiable(_strokes);
  List<Offset> get currentPoints => List.unmodifiable(_currentPoints);
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  bool get isEraser => _isEraser;

  // ========================
  // DRAWING
  // ========================
  void startStroke(Offset point) {
    _currentPoints = [point];
    notifyListeners();
  }

  void updateStroke(Offset point) {
    _currentPoints.add(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentPoints.isEmpty) return;

    final stroke = Stroke(
      id: _generateId(),
      points: List.from(_currentPoints),
      color: _isEraser ? Colors.white : _selectedColor, // ✅ eraser fix
      strokeWidth: _strokeWidth,
      isEraser: _isEraser,
    );

    _strokes.add(stroke);
    _strokeIds.add(stroke.id);

    _currentPoints = [];
    notifyListeners();
  }

  // ========================
  // REMOTE STROKES
  // ========================
  void addRemoteStroke(Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // ✅ prevent duplicate strokes
    if (_strokeIds.contains(stroke.id)) return;

    _strokes.add(stroke);
    _strokeIds.add(stroke.id);

    notifyListeners();
  }

  // ========================
  // UNDO
  // ========================
  void undo() {
    if (_strokes.isEmpty) return;

    final removed = _strokes.removeLast();
    _strokeIds.remove(removed.id);

    notifyListeners();
  }

  // ========================
  // CLEAR
  // ========================
  void clearCanvas() {
    _strokes.clear();
    _strokeIds.clear();
    _currentPoints = [];

    notifyListeners();
  }

  // ========================
  // TOOLS
  // ========================
  void setColor(Color color) {
    _selectedColor = color;
    _isEraser = false;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void toggleEraser() {
    _isEraser = !_isEraser;
    notifyListeners();
  }

  // ========================
  // ID GENERATOR
  // ========================
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString();
  }
}