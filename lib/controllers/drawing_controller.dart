import 'package:flutter/material.dart';
import '../models/stroke.dart';
import 'dart:math';

class DrawingController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  bool _isEraser = false;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  List<Offset> get currentPoints => List.unmodifiable(_currentPoints);
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  bool get isEraser => _isEraser;

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
    _strokes.add(Stroke(
      id: _generateId(),
      points: List.from(_currentPoints),
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      isEraser: _isEraser,
    ));
    _currentPoints = [];
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _currentPoints = [];
    notifyListeners();
  }

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

  void addRemoteStroke(Stroke stroke) {
    _strokes.add(stroke);
    notifyListeners();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString();
  }
}
