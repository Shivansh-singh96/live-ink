import 'dart:ui';

class Stroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  const Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  // ✅ Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color.value, // ✅ FIXED (stable)
      'width': strokeWidth, // ✅ MATCH Firebase key
      'isEraser': isEraser,
      'points': points
          .map((p) => {'dx': p.dx, 'dy': p.dy})
          .toList(),
    };
  }

  // ✅ Convert from Firestore map
  factory Stroke.fromMap(Map<String, dynamic> map) {
    final List pointsData = map['points'] ?? [];

    return Stroke(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      color: Color(map['color'] as int),
      strokeWidth: (map['width'] as num).toDouble(),
      isEraser: map['isEraser'] ?? false,
      points: pointsData.map<Offset>((p) {
        return Offset(
          (p['dx'] as num).toDouble(),
          (p['dy'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  // ✅ Copy helper
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