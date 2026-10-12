import 'package:flutter/material.dart';

enum FruitCategory {
  apples('Apples', '🍎', Color(0xFFFF5B67)),
  bananas('Bananas', '🍌', Color(0xFFFFD447)),
  berries('Berries', '🍓', Color(0xFFFF79B0)),
  citrus('Citrus', '🍊', Color(0xFFFF9638)),
  tropical('Tropical', '🍍', Color(0xFF64DDA0)),
  melons('Melons', '🍉', Color(0xFF58C7FA)),
  stoneAndMixed('Mixed', '🍒', Color(0xFF9875FF));

  final String label;
  final String emoji;
  final Color themeColor;

  const FruitCategory(this.label, this.emoji, this.themeColor);
}

/// A closed, colorable vector region of a fruit drawing.
class ColorRegion {
  final String id;
  final String name;
  final Path Function(Size size) pathBuilder;
  final int
  zIndex; // Smaller drawn first, higher drawn on top / hit-tested first

  const ColorRegion({
    required this.id,
    required this.name,
    required this.pathBuilder,
    this.zIndex = 0,
  });

  /// Evaluates whether the given point falls inside this closed region.
  bool contains(Offset point, Size size) {
    final path = pathBuilder(size);
    return path.contains(point);
  }
}

/// Represents a complete fruit coloring page with vector regions and outlines.
class ColoringPage {
  final String id;
  final String name;
  final FruitCategory category;
  final String difficulty; // 'Easy', 'Medium', 'Detailed'
  final String funFact;
  final List<Color> suggestedColors;
  final String iconEmoji;
  final List<ColorRegion> regions;
  final void Function(Canvas canvas, Size size, Paint outlinePaint)
  drawOutlines;

  final String? imageAsset;

  const ColoringPage({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.funFact,
    required this.suggestedColors,
    required this.iconEmoji,
    required this.regions,
    required this.drawOutlines,
    this.imageAsset,
  });

  /// Hit-tests a tap point on the canvas to find which closed region was clicked.
  /// Tests higher z-index (smaller/inner details) first.
  ColorRegion? hitTest(Offset point, Size size) {
    // Sort regions by zIndex descending for hit testing
    final sorted = List<ColorRegion>.from(regions)
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (final region in sorted) {
      if (region.contains(point, size)) {
        return region;
      }
    }
    return null;
  }
}
