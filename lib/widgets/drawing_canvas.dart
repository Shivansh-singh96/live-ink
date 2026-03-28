import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/stroke.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingController controller;
  final GlobalKey repaintKey;

  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        color: Colors.white,
        child: GestureDetector(
          onPanStart: (details) {
            final RenderBox box =
                context.findRenderObject() as RenderBox;
            controller.startStroke(
                box.globalToLocal(details.globalPosition));
          },
          onPanUpdate: (details) {
            final RenderBox box =
                context.findRenderObject() as RenderBox;
            controller.updateStroke(
                box.globalToLocal(details.globalPosition));
          },
          onPanEnd: (_) => controller.endStroke(),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: DrawingPainter(
                  strokes: controller.strokes,
                  currentPoints: controller.currentPoints,
                  currentColor: controller.selectedColor,
                  currentWidth: controller.strokeWidth,
                  isEraser: controller.isEraser,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;

  const DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color,
          stroke.strokeWidth, stroke.isEraser);
    }

    if (currentPoints.isNotEmpty) {
      _drawStroke(
          canvas, currentPoints, currentColor, currentWidth, isEraser);
    }

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color,
      double width, bool eraser) {
    if (points.length < 2) return;

    final Paint paint = Paint()
      ..color = eraser ? Colors.transparent : color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..blendMode = eraser ? BlendMode.clear : BlendMode.srcOver;

    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentWidth != currentWidth ||
        oldDelegate.isEraser != isEraser;
  }
}
