import 'dart:ui';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final String id;

  const Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id'] as String,
      color: Color(map['color'] as int),
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
      isEraser: map['isEraser'] as bool,
      points: (map['points'] as List)
          .map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
    );
  }

  Stroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}
