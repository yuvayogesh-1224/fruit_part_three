import 'package:flutter/material.dart';

import 'coloring_page_model.dart';

/// Represents a freehand brush or eraser stroke made by the user.
class BrushStroke {
  final List<Offset> points;
  final int colorValue;
  final double strokeWidth;
  final bool isEraser;

  BrushStroke({
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
    this.isEraser = false,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => [p.dx, p.dy]).toList(),
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
    };
  }

  factory BrushStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((item) {
      final list = item as List<dynamic>;
      return Offset((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }).toList();

    return BrushStroke(
      points: points,
      colorValue: json['colorValue'] as int? ?? 0xFF000000,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 8.0,
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }
}

/// Represents a saved coloring session and its exported image file.
class SavedArtwork {
  final String id;
  final String fruitId;
  final String fruitName;
  final FruitCategory category;
  final DateTime createdAt;
  final DateTime lastEditedAt;
  final String imagePath;
  final Map<String, int> regionColors;
  final List<BrushStroke> strokes;
  final double completionPercentage;
  final int coloredRegionsCount;

  SavedArtwork({
    required this.id,
    required this.fruitId,
    required this.fruitName,
    required this.category,
    required this.createdAt,
    required this.lastEditedAt,
    required this.imagePath,
    required this.regionColors,
    required this.strokes,
    required this.completionPercentage,
    required this.coloredRegionsCount,
  });

  SavedArtwork copyWith({
    String? id,
    String? fruitId,
    String? fruitName,
    FruitCategory? category,
    DateTime? createdAt,
    DateTime? lastEditedAt,
    String? imagePath,
    Map<String, int>? regionColors,
    List<BrushStroke>? strokes,
    double? completionPercentage,
    int? coloredRegionsCount,
  }) {
    return SavedArtwork(
      id: id ?? this.id,
      fruitId: fruitId ?? this.fruitId,
      fruitName: fruitName ?? this.fruitName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      imagePath: imagePath ?? this.imagePath,
      regionColors: regionColors ?? this.regionColors,
      strokes: strokes ?? this.strokes,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      coloredRegionsCount: coloredRegionsCount ?? this.coloredRegionsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fruitId': fruitId,
      'fruitName': fruitName,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'lastEditedAt': lastEditedAt.toIso8601String(),
      'imagePath': imagePath,
      'regionColors': regionColors,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'completionPercentage': completionPercentage,
      'coloredRegionsCount': coloredRegionsCount,
    };
  }

  factory SavedArtwork.fromJson(Map<String, dynamic> json) {
    FruitCategory cat;
    try {
      cat = FruitCategory.values.byName(json['category'] as String);
    } catch (_) {
      cat = FruitCategory.tropical;
    }

    final rawRegionColors = json['regionColors'] as Map<String, dynamic>? ?? {};
    final regionColors = rawRegionColors.map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );

    final rawStrokes = json['strokes'] as List<dynamic>? ?? [];
    final strokes = rawStrokes
        .map((s) => BrushStroke.fromJson(s as Map<String, dynamic>))
        .toList();

    return SavedArtwork(
      id: json['id'] as String,
      fruitId: json['fruitId'] as String,
      fruitName: json['fruitName'] as String? ?? 'Colored Fruit',
      category: cat,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastEditedAt:
          DateTime.tryParse(json['lastEditedAt'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String? ?? '',
      regionColors: regionColors,
      strokes: strokes,
      completionPercentage:
          (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      coloredRegionsCount: json['coloredRegionsCount'] as int? ?? 0,
    );
  }
}
