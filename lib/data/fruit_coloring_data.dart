import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/coloring_page_model.dart';

/// Helper to scale 400x400 normalized coordinates into target canvas size
class PathBuilderHelper {
  final Size size;
  final double sx;
  final double sy;

  PathBuilderHelper(this.size)
    : sx = size.width / 400.0,
      sy = size.height / 400.0;

  double x(double val) => val * sx;
  double y(double val) => val * sy;
  Offset pt(double px, double py) => Offset(px * sx, py * sy);

  Path oval(
    double cx,
    double cy,
    double rx,
    double ry, [
    double rotationDeg = 0,
  ]) {
    final path = Path();
    final rect = Rect.fromCenter(
      center: pt(cx, cy),
      width: rx * 2 * sx,
      height: ry * 2 * sy,
    );
    if (rotationDeg == 0) {
      path.addOval(rect);
    } else {
      final matrix =
          Matrix4.translationValues(pt(cx, cy).dx, pt(cx, cy).dy, 0.0)
            ..rotateZ(rotationDeg * math.pi / 180)
            ..multiply(
              Matrix4.translationValues(-pt(cx, cy).dx, -pt(cx, cy).dy, 0.0),
            );
      final p = Path()..addOval(rect);
      return p.transform(matrix.storage);
    }
    return path;
  }

  Path circle(double cx, double cy, double r) {
    return oval(cx, cy, r, r);
  }

  Path roundedRect(double left, double top, double w, double h, double r) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x(left), y(top), x(w), y(h)),
        Radius.circular(r * ((sx + sy) / 2)),
      ),
    );
  }

  Path leaf(double bx, double by, double tx, double ty, double width) {
    final path = Path();
    final p0 = pt(bx, by);
    final p1 = pt(tx, ty);
    final mx = (bx + tx) / 2;
    final my = (by + ty) / 2;
    final dx = ty - by;
    final dy = -(tx - bx);
    final len = math.sqrt(dx * dx + dy * dy);
    final normX = len == 0 ? 0 : (dx / len) * width;
    final normY = len == 0 ? 0 : (dy / len) * width;

    path.moveTo(p0.dx, p0.dy);
    path.quadraticBezierTo(x(mx + normX), y(my + normY), p1.dx, p1.dy);
    path.quadraticBezierTo(x(mx - normX), y(my - normY), p0.dx, p0.dy);
    path.close();
    return path;
  }

  Path polygon(List<List<double>> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(x(pts[0][0]), y(pts[0][1]));
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(x(pts[i][0]), y(pts[i][1]));
    }
    path.close();
    return path;
  }

  Path star(double cx, double cy, double outerR, double innerR, int points) {
    final path = Path();
    final angle = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerR : innerR;
      final a = i * angle - math.pi / 2;
      final px = cx + r * math.cos(a);
      final py = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x(px), y(py));
      } else {
        path.lineTo(x(px), y(py));
      }
    }
    path.close();
    return path;
  }

  Path wedge(
    double cx,
    double cy,
    double innerR,
    double outerR,
    double startAngle,
    double sweepAngle,
  ) {
    final p = Path();
    final p0 = pt(
      cx + innerR * math.cos(startAngle),
      cy + innerR * math.sin(startAngle),
    );
    final p1 = pt(
      cx + outerR * math.cos(startAngle),
      cy + outerR * math.sin(startAngle),
    );
    final p2 = pt(
      cx + outerR * math.cos(startAngle + sweepAngle),
      cy + outerR * math.sin(startAngle + sweepAngle),
    );
    final p3 = pt(
      cx + innerR * math.cos(startAngle + sweepAngle),
      cy + innerR * math.sin(startAngle + sweepAngle),
    );

    p.moveTo(p0.dx, p0.dy);
    p.lineTo(p1.dx, p1.dy);
    p.arcToPoint(p2, radius: Radius.circular(outerR * sx), clockwise: true);
    p.lineTo(p3.dx, p3.dy);
    p.arcToPoint(p0, radius: Radius.circular(innerR * sx), clockwise: false);
    p.close();
    return p;
  }

  void drawLeafWithVeins(
    Canvas canvas,
    double bx,
    double by,
    double tx,
    double ty,
    double width,
    Paint outlinePaint,
    Paint finePaint,
  ) {
    canvas.drawPath(leaf(bx, by, tx, ty, width), outlinePaint);
    final midrib = Path()
      ..moveTo(x(bx), y(by))
      ..quadraticBezierTo(x((bx + tx) / 2), y((by + ty) / 2), x(tx), y(ty));
    canvas.drawPath(midrib, finePaint);
    for (int i = 1; i <= 4; i++) {
      final t = i / 5.0;
      final px = bx + (tx - bx) * t;
      final py = by + (ty - by) * t;
      final dx = ty - by;
      final dy = -(tx - bx);
      final len = math.sqrt(dx * dx + dy * dy);
      final normX = len == 0 ? 0.0 : (dx / len) * (width * 0.42);
      final normY = len == 0 ? 0.0 : (dy / len) * (width * 0.42);
      canvas.drawLine(pt(px, py), pt(px + normX, py + normY), finePaint);
      canvas.drawLine(pt(px, py), pt(px - normX, py - normY), finePaint);
    }
  }
}

/// Static catalog containing all 50 unique fruit coloring pages with 100% authentic,
/// beautiful, kid-friendly vector illustrations and distinct colorable regions.
class FruitColoringData {
  static List<ColoringPage> get allPages => _buildAllPages();

  static ColoringPage getById(String id) {
    return allPages.firstWhere((p) => p.id == id, orElse: () => allPages.first);
  }

  static List<ColoringPage> getByCategory(FruitCategory category) {
    return allPages.where((p) => p.category == category).toList();
  }

  static List<ColoringPage> _buildAllPages() {
    return [
      _buildStrawberry(),
      _buildApple(),
      _buildBanana(),
      _buildOrange(),
      _buildMango(),
      _buildWatermelon(),
      _buildPineapple(),
      _buildGrapes(),
      _buildPomegranate(),
      _buildKiwi(),
      _buildAvocado(),
      _buildCherry(),
      _buildLemon(),
      _buildPapaya(),
      _buildGuava(),
      _buildDragonFruit(),
      _buildBlueberry(),
      _buildRaspberry(),
      _buildBlackberry(),
      _buildPeach(),
      _buildPear(),
      _buildPlum(),
      _buildApricot(),
      _buildCoconut(),
      _buildLime(),
      _buildGrapefruit(),
      _buildJackfruit(),
      _buildDurian(),
      _buildLychee(),
      _buildRambutan(),
      _buildPassionFruit(),
      _buildStarFruit(),
      _buildCustardApple(),
      _buildSapodilla(),
      _buildFig(),
      _buildDates(),
      _buildPersimmon(),
      _buildCranberry(),
      _buildMulberry(),
      _buildGooseberry(),
      _buildAmla(),
      _buildMuskmelon(),
      _buildCantaloupe(),
      _buildHoneydew(),
      _buildTangerine(),
      _buildMandarin(),
      _buildNectarine(),
      _buildBreadfruit(),
      _buildMangosteen(),
      _buildLongan(),
    ];
  }

  // ==========================================
  // 1. APPLE (Beautiful indented apple with leaf, stem & shine)
  // ==========================================
  static ColoringPage _buildApple() {
    return ColoringPage(
      id: 'apple',
      name: 'Sweet Apple',
      category: FruitCategory.apples,
      difficulty: 'Easy',
      funFact:
          'Apples float in water because 25% of their volume is actually air!',
      iconEmoji: '🍎',
      imageAsset: 'assets/images/apple.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
        Color(0xFF795548),
        Color(0xFFFFD447),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Apple Body',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(200), h.y(110));
            p.cubicTo(h.x(130), h.y(60), h.x(70), h.y(140), h.x(80), h.y(230));
            p.cubicTo(
              h.x(90),
              h.y(310),
              h.x(150),
              h.y(350),
              h.x(200),
              h.y(340),
            );
            p.cubicTo(
              h.x(250),
              h.y(350),
              h.x(310),
              h.y(310),
              h.x(320),
              h.y(230),
            );
            p.cubicTo(
              h.x(330),
              h.y(140),
              h.x(270),
              h.y(60),
              h.x(200),
              h.y(110),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'stem',
          name: 'Curved Stem',
          zIndex: 2,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(195), h.y(115));
            p.cubicTo(h.x(190), h.y(70), h.x(215), h.y(45), h.x(225), h.y(40));
            p.lineTo(h.x(232), h.y(45));
            p.cubicTo(
              h.x(220),
              h.y(75),
              h.x(203),
              h.y(115),
              h.x(203),
              h.y(115),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(210, 80, 290, 50, 26),
        ),
        ColorRegion(
          id: 'highlight',
          name: 'Gleam Highlight',
          zIndex: 4,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(130, 160, 20, 45, -25),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final finePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = paint.strokeWidth * 0.55;

        final body = Path();
        body.moveTo(h.x(200), h.y(110));
        body.cubicTo(h.x(130), h.y(60), h.x(70), h.y(140), h.x(80), h.y(230));
        body.cubicTo(h.x(90), h.y(310), h.x(150), h.y(350), h.x(200), h.y(340));
        body.cubicTo(
          h.x(250),
          h.y(350),
          h.x(310),
          h.y(310),
          h.x(320),
          h.y(230),
        );
        body.cubicTo(h.x(330), h.y(140), h.x(270), h.y(60), h.x(200), h.y(110));
        body.close();
        canvas.drawPath(body, paint);

        // Apple top cavity crease
        final crease = Path()
          ..moveTo(h.x(180), h.y(118))
          ..quadraticBezierTo(h.x(200), h.y(128), h.x(220), h.y(118));
        canvas.drawPath(crease, finePaint);

        // Apple bottom dimple
        final botDimple = Path()
          ..moveTo(h.x(185), h.y(335))
          ..quadraticBezierTo(h.x(200), h.y(330), h.x(215), h.y(335));
        canvas.drawPath(botDimple, finePaint);

        // Stem
        final stem = Path()
          ..moveTo(h.x(195), h.y(115))
          ..cubicTo(h.x(190), h.y(70), h.x(215), h.y(45), h.x(225), h.y(40))
          ..lineTo(h.x(232), h.y(45))
          ..cubicTo(h.x(220), h.y(75), h.x(203), h.y(115), h.x(203), h.y(115))
          ..close();
        canvas.drawPath(stem, paint);

        // Leaf with realistic branching veins
        h.drawLeafWithVeins(canvas, 210, 80, 290, 50, 26, paint, finePaint);

        // Specular gleam highlight
        canvas.drawPath(h.oval(130, 160, 20, 45, -25), finePaint);
      },
    );
  }

  // ==========================================
  // 2. BANANA (Playful curved banana with 3 peel facets & tips)
  // ==========================================
  static ColoringPage _buildBanana() {
    return ColoringPage(
      id: 'banana',
      name: 'Happy Banana',
      category: FruitCategory.bananas,
      difficulty: 'Easy',
      funFact: 'Bananas are naturally curved because they grow towards the sun against gravity!',
      iconEmoji: '🍌',
      imageAsset: 'assets/images/banana.jpg',
      suggestedColors: const [
        Color(0xFFFFD447),
        Color(0xFFFF9638),
        Color(0xFF64DDA0),
        Color(0xFF8D6E63),
      ],
      regions: [
        ColorRegion(
          id: 'peel_top',
          name: 'Top Peel Ridge',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(90), h.y(90));
            p.cubicTo(
              h.x(180),
              h.y(70),
              h.x(290),
              h.y(120),
              h.x(330),
              h.y(280),
            );
            p.cubicTo(
              h.x(280),
              h.y(160),
              h.x(180),
              h.y(120),
              h.x(90),
              h.y(130),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'peel_center',
          name: 'Center Peel Body',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(90), h.y(130));
            p.cubicTo(
              h.x(180),
              h.y(120),
              h.x(280),
              h.y(160),
              h.x(330),
              h.y(280),
            );
            p.cubicTo(
              h.x(270),
              h.y(220),
              h.x(170),
              h.y(180),
              h.x(90),
              h.y(170),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'peel_bottom',
          name: 'Under Belly',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(90), h.y(170));
            p.cubicTo(
              h.x(170),
              h.y(180),
              h.x(270),
              h.y(220),
              h.x(330),
              h.y(280),
            );
            p.cubicTo(
              h.x(260),
              h.y(280),
              h.x(160),
              h.y(250),
              h.x(90),
              h.y(200),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'stem',
          name: 'Stem Cap',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [90, 90],
            [60, 70],
            [55, 95],
            [90, 130],
          ]),
        ),
        ColorRegion(
          id: 'tip',
          name: 'Bottom Tip',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(335, 290, 15, 12, 30),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final p = Path();
        p.moveTo(h.x(90), h.y(90));
        p.cubicTo(h.x(180), h.y(70), h.x(290), h.y(120), h.x(335), h.y(280));
        p.lineTo(h.x(342), h.y(295));
        p.cubicTo(h.x(260), h.y(285), h.x(160), h.y(250), h.x(90), h.y(200));
        p.close();
        canvas.drawPath(p, paint);

        final ridge1 = Path()
          ..moveTo(h.x(90), h.y(130))
          ..cubicTo(h.x(180), h.y(120), h.x(280), h.y(160), h.x(330), h.y(280));
        final ridge2 = Path()
          ..moveTo(h.x(90), h.y(170))
          ..cubicTo(h.x(170), h.y(180), h.x(270), h.y(220), h.x(330), h.y(280));
        canvas.drawPath(ridge1, paint);
        canvas.drawPath(ridge2, paint);

        canvas.drawPath(
          h.polygon([
            [90, 90],
            [60, 70],
            [55, 95],
            [90, 130],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 3. MANGO (Alphonso voluptuous curves, beak tip, stem & leaf)
  // ==========================================
  static ColoringPage _buildMango() {
    return ColoringPage(
      id: 'mango',
      name: 'Juicy Mango',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Mango is known as the "King of Fruits" and is the national fruit of India!',
      iconEmoji: '🥭',
      imageAsset: 'assets/images/mango.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFFD447),
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'mango_body',
          name: 'Mango Flesh',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(180), h.y(110));
            p.cubicTo(
              h.x(290),
              h.y(110),
              h.x(320),
              h.y(220),
              h.x(270),
              h.y(310),
            );
            p.cubicTo(
              h.x(220),
              h.y(380),
              h.x(140),
              h.y(340),
              h.x(100),
              h.y(270),
            );
            p.cubicTo(
              h.x(60),
              h.y(190),
              h.x(110),
              h.y(110),
              h.x(180),
              h.y(110),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'stem',
          name: 'Twig Stem',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [175, 115],
            [170, 70],
            [185, 68],
            [190, 115],
          ]),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Mango Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(185, 90, 275, 55, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final finePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = paint.strokeWidth * 0.55;

        final body = Path();
        body.moveTo(h.x(180), h.y(110));
        body.cubicTo(
          h.x(290),
          h.y(110),
          h.x(320),
          h.y(220),
          h.x(270),
          h.y(310),
        );
        body.cubicTo(
          h.x(220),
          h.y(380),
          h.x(140),
          h.y(340),
          h.x(100),
          h.y(270),
        );
        body.cubicTo(h.x(60), h.y(190), h.x(110), h.y(110), h.x(180), h.y(110));
        body.close();
        canvas.drawPath(body, paint);

        // Beak indentation curve
        final beak = Path()
          ..moveTo(h.x(260), h.y(300))
          ..quadraticBezierTo(h.x(250), h.y(330), h.x(230), h.y(350));
        canvas.drawPath(beak, finePaint);

        // Stem
        canvas.drawPath(
          h.polygon([
            [175, 115],
            [170, 70],
            [185, 68],
            [190, 115],
          ]),
          paint,
        );
        // Leaf with realistic veins
        h.drawLeafWithVeins(canvas, 185, 90, 275, 55, 24, paint, finePaint);
      },
    );
  }

  // ==========================================
  // 4. ORANGE (Detailed citrus slice with 6 juicy segments & rind)
  // ==========================================
  static ColoringPage _buildOrange() {
    return ColoringPage(
      id: 'orange',
      name: 'Sunny Orange',
      category: FruitCategory.citrus,
      difficulty: 'Medium',
      funFact: 'There are over 600 distinct varieties of oranges grown all across the world!',
      iconEmoji: '🍊',
      imageAsset: 'assets/images/orange.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
        Color(0xFF58C7FA),
      ],
      regions: [
        ColorRegion(
          id: 'orange_rind',
          name: 'Outer Rind',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 140),
        ),
        ...List.generate(6, (i) {
          final angle = (i * 60) * math.pi / 180;
          return ColorRegion(
            id: 'slice_$i',
            name: 'Juicy Segment ${i + 1}',
            zIndex: 2,
            pathBuilder: (size) {
              final h = PathBuilderHelper(size);
              final p = Path();
              final cx = 200.0;
              final cy = 220.0;
              final r = 95.0;
              final a1 = angle + 0.12;
              final a2 = angle + (math.pi / 3) - 0.12;
              p.moveTo(h.x(cx), h.y(cy));
              p.lineTo(h.x(cx + r * math.cos(a1)), h.y(cy + r * math.sin(a1)));
              p.arcToPoint(
                h.pt(cx + r * math.cos(a2), cy + r * math.sin(a2)),
                radius: Radius.circular(r * h.sx),
              );
              p.close();
              return p;
            },
          );
        }),
        ColorRegion(
          id: 'center_core',
          name: 'Center Core',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 18),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Stem',
          zIndex: 4,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 80],
            [195, 45],
            [205, 45],
            [205, 80],
          ]),
        ),
        ColorRegion(
          id: 'leaf_right',
          name: 'Right Leaf',
          zIndex: 5,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(205, 60, 280, 45, 22),
        ),
        ColorRegion(
          id: 'leaf_left',
          name: 'Left Leaf',
          zIndex: 5,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(195, 65, 125, 40, 20),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final finePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = paint.strokeWidth * 0.55;

        canvas.drawCircle(h.pt(200, 220), 140 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 105 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 18 * h.sx, paint);

        for (int i = 0; i < 6; i++) {
          final a = i * 60 * math.pi / 180;
          canvas.drawLine(
            h.pt(200 + 20 * math.cos(a), 220 + 20 * math.sin(a)),
            h.pt(200 + 105 * math.cos(a), 220 + 105 * math.sin(a)),
            paint,
          );
          // Delicate inner pulp vesicle rays
          final midA = a + (30 * math.pi / 180);
          canvas.drawLine(
            h.pt(200 + 40 * math.cos(midA), 220 + 40 * math.sin(midA)),
            h.pt(200 + 85 * math.cos(midA), 220 + 85 * math.sin(midA)),
            finePaint,
          );
        }

        canvas.drawPath(
          h.polygon([
            [195, 80],
            [195, 45],
            [205, 45],
            [205, 80],
          ]),
          paint,
        );
        h.drawLeafWithVeins(canvas, 205, 60, 280, 45, 22, paint, finePaint);
        h.drawLeafWithVeins(canvas, 195, 65, 125, 40, 20, paint, finePaint);
      },
    );
  }

  // ==========================================
  // 5. STRAWBERRY (Plump cone, starry leafy crown & 8 distinct seeds)
  // ==========================================
  static ColoringPage _buildStrawberry() {
    return ColoringPage(
      id: 'strawberry',
      name: 'Ruby Strawberry',
      category: FruitCategory.berries,
      difficulty: 'Medium',
      funFact: 'Strawberries are the only fruit that wear their seeds on the outside of their skin!',
      iconEmoji: '🍓',
      imageAsset: 'assets/images/strawberry.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFFFF79B0),
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
      ],
      regions: [
        ColorRegion(
          id: 'berry_body',
          name: 'Berry Body',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(100), h.y(140));
            p.cubicTo(
              h.x(90),
              h.y(240),
              h.x(160),
              h.y(350),
              h.x(200),
              h.y(360),
            );
            p.cubicTo(
              h.x(240),
              h.y(350),
              h.x(310),
              h.y(240),
              h.x(300),
              h.y(140),
            );
            p.cubicTo(
              h.x(260),
              h.y(120),
              h.x(140),
              h.y(120),
              h.x(100),
              h.y(140),
            );
            p.close();
            return p;
          },
        ),
        ...[
          [150, 180],
          [200, 180],
          [250, 180],
          [170, 230],
          [230, 230],
          [150, 280],
          [200, 280],
          [250, 280],
        ].asMap().entries.map((e) {
          return ColorRegion(
            id: 'seed_${e.key}',
            name: 'Seed ${e.key + 1}',
            zIndex: 4,
            pathBuilder: (size) => PathBuilderHelper(size)
                .oval(e.value[0].toDouble(), e.value[1].toDouble(), 6, 10, 15),
          );
        }),
        ColorRegion(
          id: 'crown_leaf_1',
          name: 'Center Calyx Leaf',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [200, 130],
            [180, 80],
            [220, 80],
          ]),
        ),
        ColorRegion(
          id: 'crown_leaf_2',
          name: 'Left Calyx Leaf',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [170, 130],
            [110, 100],
            [140, 140],
          ]),
        ),
        ColorRegion(
          id: 'crown_leaf_3',
          name: 'Right Calyx Leaf',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [230, 130],
            [290, 100],
            [260, 140],
          ]),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Stem',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 80],
            [195, 45],
            [205, 45],
            [205, 80],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final body = Path();
        body.moveTo(h.x(100), h.y(140));
        body.cubicTo(h.x(90), h.y(240), h.x(160), h.y(350), h.x(200), h.y(360));
        body.cubicTo(
          h.x(240),
          h.y(350),
          h.x(310),
          h.y(240),
          h.x(300),
          h.y(140),
        );
        body.cubicTo(
          h.x(260),
          h.y(120),
          h.x(140),
          h.y(120),
          h.x(100),
          h.y(140),
        );
        body.close();
        canvas.drawPath(body, paint);

        canvas.drawPath(
          h.polygon([
            [200, 130],
            [180, 80],
            [220, 80],
          ]),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [170, 130],
            [110, 100],
            [140, 140],
          ]),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [230, 130],
            [290, 100],
            [260, 140],
          ]),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [195, 80],
            [195, 45],
            [205, 45],
            [205, 80],
          ]),
          paint,
        );

        final seedPaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        for (final pt in [
          [150, 180],
          [200, 180],
          [250, 180],
          [170, 230],
          [230, 230],
          [150, 280],
          [200, 280],
          [250, 280],
        ]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: h.pt(pt[0].toDouble(), pt[1].toDouble()),
              width: 12 * h.sx,
              height: 18 * h.sy,
            ),
            seedPaint,
          );
        }
      },
    );
  }

  // ==========================================
  // 6. WATERMELON (Juicy crescent slice, 2-tier rind & teardrop seeds)
  // ==========================================
  static ColoringPage _buildWatermelon() {
    return ColoringPage(
      id: 'watermelon',
      name: 'Fresh Watermelon',
      category: FruitCategory.melons,
      difficulty: 'Easy',
      funFact: 'Watermelons are 92% water, making them the ultimate thirst quencher!',
      iconEmoji: '🍉',
      imageAsset: 'assets/images/watermelon.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
        Color(0xFF25264A),
        Color(0xFFFFF9F0),
      ],
      regions: [
        ColorRegion(
          id: 'rind_outer',
          name: 'Green Crust Rind',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(50), h.y(180));
            p.arcToPoint(
              h.pt(350, 180),
              radius: Radius.circular(150 * h.sx),
              clockwise: false,
            );
            p.lineTo(h.x(320), h.y(180));
            p.arcToPoint(
              h.pt(80, 180),
              radius: Radius.circular(120 * h.sx),
              clockwise: true,
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'rind_inner',
          name: 'White Pith Border',
          zIndex: 2,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(80), h.y(180));
            p.arcToPoint(
              h.pt(320, 180),
              radius: Radius.circular(120 * h.sx),
              clockwise: false,
            );
            p.lineTo(h.x(300), h.y(180));
            p.arcToPoint(
              h.pt(100, 180),
              radius: Radius.circular(100 * h.sx),
              clockwise: true,
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'flesh_red',
          name: 'Sweet Red Pulp',
          zIndex: 3,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(100), h.y(180));
            p.arcToPoint(
              h.pt(300, 180),
              radius: Radius.circular(100 * h.sx),
              clockwise: false,
            );
            p.close();
            return p;
          },
        ),
        ...[
          [150, 210],
          [200, 205],
          [250, 210],
          [170, 245],
          [230, 245],
          [200, 270],
        ].asMap().entries.map((e) {
          return ColorRegion(
            id: 'seed_${e.key}',
            name: 'Seed ${e.key + 1}',
            zIndex: 4,
            pathBuilder: (size) => PathBuilderHelper(size)
                .oval(e.value[0].toDouble(), e.value[1].toDouble(), 6, 12, 10),
          );
        }),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final finePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = paint.strokeWidth * 0.55;

        final outer = Path()
          ..moveTo(h.x(50), h.y(180))
          ..arcToPoint(
            h.pt(350, 180),
            radius: Radius.circular(150 * h.sx),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(outer, paint);

        final rim1 = Path()
          ..moveTo(h.x(80), h.y(180))
          ..arcToPoint(
            h.pt(320, 180),
            radius: Radius.circular(120 * h.sx),
            clockwise: false,
          );
        canvas.drawPath(rim1, paint);

        final rim2 = Path()
          ..moveTo(h.x(100), h.y(180))
          ..arcToPoint(
            h.pt(300, 180),
            radius: Radius.circular(100 * h.sx),
            clockwise: false,
          );
        canvas.drawPath(rim2, paint);

        canvas.drawLine(h.pt(50, 180), h.pt(350, 180), paint);

        // Natural dark wavy rind stripes
        for (int i = 1; i <= 6; i++) {
          final a = math.pi + (i * math.pi / 7);
          canvas.drawLine(
            h.pt(200 + 120 * math.cos(a), 180 - 120 * math.sin(a)),
            h.pt(200 + 150 * math.cos(a), 180 - 150 * math.sin(a)),
            finePaint,
          );
        }

        // Seeds with gleams
        for (final pt in [
          [150, 210],
          [200, 205],
          [250, 210],
          [170, 245],
          [230, 245],
          [200, 270],
        ]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: h.pt(pt[0].toDouble(), pt[1].toDouble()),
              width: 12 * h.sx,
              height: 20 * h.sy,
            ),
            Paint()..color = paint.color,
          );
          canvas.drawCircle(
            h.pt(pt[0].toDouble() - 2, pt[1].toDouble() - 4),
            2 * h.sx,
            Paint()..color = Colors.white,
          );
        }
      },
    );
  }

  // ==========================================
  // 7. PINEAPPLE (Crosshatch diamond scales & spiky crown fan)
  // ==========================================
  static ColoringPage _buildPineapple() {
    return ColoringPage(
      id: 'pineapple',
      name: 'Tropical Pineapple',
      category: FruitCategory.tropical,
      difficulty: 'Detailed',
      funFact:
          'A single pineapple takes almost 3 whole years to grow and mature!',
      iconEmoji: '🍍',
      imageAsset: 'assets/images/pineapple.jpg',
      suggestedColors: const [
        Color(0xFFFFD447),
        Color(0xFFFF9638),
        Color(0xFF64DDA0),
        Color(0xFF8D6E63),
      ],
      regions: [
        ColorRegion(
          id: 'body_main',
          name: 'Pineapple Shell',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 250, 85, 115),
        ),
        ...List.generate(6, (i) {
          final row = i ~/ 2;
          final col = i % 2;
          final cx = 165.0 + col * 70.0;
          final cy = 190.0 + row * 55.0;
          return ColorRegion(
            id: 'facet_$i',
            name: 'Diamond Facet ${i + 1}',
            zIndex: 2,
            pathBuilder: (size) =>
                PathBuilderHelper(size).star(cx, cy, 28, 14, 4),
          );
        }),
        ColorRegion(
          id: 'crown_1',
          name: 'Center Spire Leaf',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [190, 150],
            [200, 45],
            [210, 150],
          ]),
        ),
        ColorRegion(
          id: 'crown_2',
          name: 'Left Crown Leaf',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [180, 150],
            [130, 65],
            [195, 120],
          ]),
        ),
        ColorRegion(
          id: 'crown_3',
          name: 'Right Crown Leaf',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [220, 150],
            [270, 65],
            [205, 120],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 250),
            width: 170 * h.sx,
            height: 230 * h.sy,
          ),
          paint,
        );
        canvas.drawLine(h.pt(130, 190), h.pt(270, 310), paint);
        canvas.drawLine(h.pt(130, 250), h.pt(250, 345), paint);
        canvas.drawLine(h.pt(270, 190), h.pt(130, 310), paint);
        canvas.drawLine(h.pt(270, 250), h.pt(150, 345), paint);

        canvas.drawPath(
          h.polygon([
            [190, 150],
            [200, 45],
            [210, 150],
          ]),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [180, 150],
            [130, 65],
            [195, 120],
          ]),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [220, 150],
            [270, 65],
            [205, 120],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 8. GRAPES (Juicy cluster of 13 grapes with vine leaf & stalk)
  // ==========================================
  static ColoringPage _buildGrapes() {
    final grapeCoords = [
      [160, 150],
      [200, 140],
      [240, 150],
      [140, 190],
      [180, 185],
      [220, 185],
      [260, 190],
      [160, 230],
      [200, 225],
      [240, 230],
      [180, 270],
      [220, 270],
      [200, 310],
    ];

    return ColoringPage(
      id: 'grapes',
      name: 'Grape Bunch',
      category: FruitCategory.berries,
      difficulty: 'Medium',
      funFact: 'Grapes can come in red, black, purple, blue, green, and golden yellow colors!',
      iconEmoji: '🍇',
      imageAsset: 'assets/images/grapes.jpg',
      suggestedColors: const [
        Color(0xFF9875FF),
        Color(0xFF64DDA0),
        Color(0xFF8D6E63),
        Color(0xFFFF79B0),
      ],
      regions: [
        ...grapeCoords.asMap().entries.map((e) {
          return ColorRegion(
            id: 'grape_${e.key}',
            name: 'Grape ${e.key + 1}',
            zIndex: 1,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(e.value[0].toDouble(), e.value[1].toDouble(), 24),
          );
        }),
        ColorRegion(
          id: 'stem',
          name: 'Vine Stem',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 130],
            [195, 60],
            [208, 60],
            [208, 130],
          ]),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Lobed Grape Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(208, 90, 300, 70, 35),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        for (final pt in grapeCoords) {
          canvas.drawCircle(
            h.pt(pt[0].toDouble(), pt[1].toDouble()),
            24 * h.sx,
            paint,
          );
        }
        canvas.drawPath(
          h.polygon([
            [195, 130],
            [195, 60],
            [208, 60],
            [208, 130],
          ]),
          paint,
        );
        canvas.drawPath(h.leaf(208, 90, 300, 70, 35), paint);
      },
    );
  }

  // ==========================================
  // 9. PAPAYA (Halved papaya with skin, orange meat & caviar seeds)
  // ==========================================
  static ColoringPage _buildPapaya() {
    return ColoringPage(
      id: 'papaya',
      name: 'Golden Papaya',
      category: FruitCategory.tropical,
      difficulty: 'Medium',
      funFact: 'Papaya contains papain, a natural enzyme that aids digestion.',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/papaya.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
        Color(0xFF25264A),
      ],
      regions: [
        ColorRegion(
          id: 'skin',
          name: 'Green/Yellow Skin',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(200), h.y(80));
            p.cubicTo(
              h.x(280),
              h.y(120),
              h.x(310),
              h.y(240),
              h.x(270),
              h.y(340),
            );
            p.cubicTo(
              h.x(230),
              h.y(380),
              h.x(170),
              h.y(380),
              h.x(130),
              h.y(340),
            );
            p.cubicTo(h.x(90), h.y(240), h.x(120), h.y(120), h.x(200), h.y(80));
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'flesh',
          name: 'Orange Sweet Flesh',
          zIndex: 2,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(200), h.y(110));
            p.cubicTo(
              h.x(260),
              h.y(140),
              h.x(280),
              h.y(240),
              h.x(245),
              h.y(320),
            );
            p.cubicTo(
              h.x(220),
              h.y(350),
              h.x(180),
              h.y(350),
              h.x(155),
              h.y(320),
            );
            p.cubicTo(
              h.x(120),
              h.y(240),
              h.x(140),
              h.y(140),
              h.x(200),
              h.y(110),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'seed_cavity',
          name: 'Center Cavity',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).oval(200, 230, 40, 70),
        ),
        // 6 distinct caviar seeds
        ...[
          [190, 190],
          [210, 195],
          [195, 230],
          [205, 230],
          [192, 265],
          [208, 260],
        ].asMap().entries.map(
          (e) => ColorRegion(
            id: 'seed_${e.key}',
            name: 'Seed ${e.key + 1}',
            zIndex: 4,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(e.value[0].toDouble(), e.value[1].toDouble(), 8),
          ),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final skin = Path();
        skin.moveTo(h.x(200), h.y(80));
        skin.cubicTo(
          h.x(280),
          h.y(120),
          h.x(310),
          h.y(240),
          h.x(270),
          h.y(340),
        );
        skin.cubicTo(
          h.x(230),
          h.y(380),
          h.x(170),
          h.y(380),
          h.x(130),
          h.y(340),
        );
        skin.cubicTo(h.x(90), h.y(240), h.x(120), h.y(120), h.x(200), h.y(80));
        skin.close();
        canvas.drawPath(skin, paint);

        final flesh = Path();
        flesh.moveTo(h.x(200), h.y(110));
        flesh.cubicTo(
          h.x(260),
          h.y(140),
          h.x(280),
          h.y(240),
          h.x(245),
          h.y(320),
        );
        flesh.cubicTo(
          h.x(220),
          h.y(350),
          h.x(180),
          h.y(350),
          h.x(155),
          h.y(320),
        );
        flesh.cubicTo(
          h.x(120),
          h.y(240),
          h.x(140),
          h.y(140),
          h.x(200),
          h.y(110),
        );
        flesh.close();
        canvas.drawPath(flesh, paint);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 230),
            width: 80 * h.sx,
            height: 140 * h.sy,
          ),
          paint,
        );

        for (final pt in [
          [190, 190],
          [210, 195],
          [195, 230],
          [205, 230],
          [192, 265],
          [208, 260],
        ]) {
          canvas.drawCircle(
            h.pt(pt[0].toDouble(), pt[1].toDouble()),
            8 * h.sx,
            Paint()..color = paint.color,
          );
        }
      },
    );
  }

  // ==========================================
  // 10. GUAVA (Whole fruit + slice with pink pulp & seeds)
  // ==========================================
  static ColoringPage _buildGuava() {
    return ColoringPage(
      id: 'guava',
      name: 'Pink Guava',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Guavas have four times more vitamin C than fresh oranges!',
      iconEmoji: '🍏',
      imageAsset: 'assets/images/guava.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFF79B0),
        Color(0xFFFF5B67),
        Color(0xFF8D6E63),
      ],
      regions: [
        ColorRegion(
          id: 'skin',
          name: 'Green Rind',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 225, 120, 110),
        ),
        ColorRegion(
          id: 'pulp',
          name: 'Pink Pulp Flesh',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 230, 80),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Woody Stem',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 115],
            [195, 65],
            [205, 65],
            [205, 115],
          ]),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Guava Leaf',
          zIndex: 4,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(205, 85, 285, 60, 26),
        ),
        ...[
          [180, 215],
          [220, 215],
          [190, 245],
          [210, 245],
        ].asMap().entries.map(
          (e) => ColorRegion(
            id: 'seed_${e.key}',
            name: 'Seed ${e.key + 1}',
            zIndex: 5,
            pathBuilder: (size) => PathBuilderHelper(size)
                .oval(e.value[0].toDouble(), e.value[1].toDouble(), 6, 8, 20),
          ),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 225),
            width: 240 * h.sx,
            height: 220 * h.sy,
          ),
          paint,
        );
        canvas.drawCircle(h.pt(200, 230), 80 * h.sx, paint);
        canvas.drawPath(
          h.polygon([
            [195, 115],
            [195, 65],
            [205, 65],
            [205, 115],
          ]),
          paint,
        );
        canvas.drawPath(h.leaf(205, 85, 285, 60, 26), paint);
        for (final pt in [
          [180, 215],
          [220, 215],
          [190, 245],
          [210, 245],
        ]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: h.pt(pt[0].toDouble(), pt[1].toDouble()),
              width: 12 * h.sx,
              height: 16 * h.sy,
            ),
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 11. POMEGRANATE (Crown coronet + cluster of jewel ruby arils)
  // ==========================================
  static ColoringPage _buildPomegranate() {
    return ColoringPage(
      id: 'pomegranate',
      name: 'Ruby Pomegranate',
      category: FruitCategory.tropical,
      difficulty: 'Detailed',
      funFact:
          'A single pomegranate can contain up to 1,400 ruby red juicy seeds!',
      iconEmoji: '🍎',
      imageAsset: 'assets/images/pomegranate.jpg',
      suggestedColors: const [
        Color(0xFFFF2E4C),
        Color(0xFFFF5B67),
        Color(0xFFFFF9F0),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Pomegranate Shell',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 235, 120),
        ),
        ColorRegion(
          id: 'crown',
          name: 'Royal Crown Calyx',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [165, 120],
            [150, 60],
            [175, 85],
            [200, 50],
            [225, 85],
            [250, 60],
            [235, 120],
          ]),
        ),
        ColorRegion(
          id: 'aril_bed',
          name: 'Aril Bed Window',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).oval(200, 240, 65, 65),
        ),
        ...List.generate(6, (i) {
          final a = i * 60 * math.pi / 180;
          return ColorRegion(
            id: 'ruby_$i',
            name: 'Ruby Gem ${i + 1}',
            zIndex: 4,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(200 + 35 * math.cos(a), 240 + 35 * math.sin(a), 14),
          );
        }),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 235), 120 * h.sx, paint);
        canvas.drawPath(
          h.polygon([
            [165, 120],
            [150, 60],
            [175, 85],
            [200, 50],
            [225, 85],
            [250, 60],
            [235, 120],
          ]),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 240),
            width: 130 * h.sx,
            height: 130 * h.sy,
          ),
          paint,
        );
        for (int i = 0; i < 6; i++) {
          final a = i * 60 * math.pi / 180;
          canvas.drawCircle(
            h.pt(200 + 35 * math.cos(a), 240 + 35 * math.sin(a)),
            14 * h.sx,
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 12. KIWI (Fuzzy outer rind + starburst light-green core & radial seeds)
  // ==========================================
  static ColoringPage _buildKiwi() {
    return ColoringPage(
      id: 'kiwi',
      name: 'Fuzzy Kiwi',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Kiwifruit was originally named Chinese Gooseberry!',
      iconEmoji: '🥝',
      imageAsset: 'assets/images/kiwi.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFF8D6E63),
        Color(0xFFFFF9F0),
        Color(0xFF25264A),
      ],
      regions: [
        ColorRegion(
          id: 'rind',
          name: 'Fuzzy Brown Skin',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 200, 130),
        ),
        ColorRegion(
          id: 'flesh',
          name: 'Green Radiating Flesh',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 200, 115),
        ),
        ColorRegion(
          id: 'core',
          name: 'Cream Center Core',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).oval(200, 200, 28, 42),
        ),
        ...List.generate(8, (i) {
          final a = i * 45 * math.pi / 180;
          return ColorRegion(
            id: 'seed_$i',
            name: 'Seed ${i + 1}',
            zIndex: 4,
            pathBuilder: (size) => PathBuilderHelper(size).oval(
              200 + 60 * math.cos(a),
              200 + 60 * math.sin(a),
              4,
              7,
              a * 180 / math.pi,
            ),
          );
        }),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final finePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = paint.strokeWidth * 0.55;

        canvas.drawCircle(h.pt(200, 200), 130 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 200), 115 * h.sx, paint);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 200),
            width: 56 * h.sx,
            height: 84 * h.sy,
          ),
          paint,
        );

        // Fuzzy bristles around perimeter
        for (int i = 0; i < 24; i++) {
          final a = i * 15 * math.pi / 180;
          canvas.drawLine(
            h.pt(200 + 130 * math.cos(a), 200 + 130 * math.sin(a)),
            h.pt(
              200 + 137 * math.cos(a + 0.05),
              200 + 137 * math.sin(a + 0.05),
            ),
            finePaint,
          );
        }

        // Radiating sunburst rays
        for (int i = 0; i < 16; i++) {
          final a = i * 22.5 * math.pi / 180;
          canvas.drawLine(
            h.pt(200 + 35 * math.cos(a), 200 + 35 * math.sin(a)),
            h.pt(200 + 105 * math.cos(a), 200 + 105 * math.sin(a)),
            finePaint,
          );
        }

        // Seeds
        for (int i = 0; i < 8; i++) {
          final a = i * 45 * math.pi / 180;
          canvas.drawCircle(
            h.pt(200 + 60 * math.cos(a), 200 + 60 * math.sin(a)),
            4 * h.sx,
            Paint()..color = paint.color,
          );
        }
      },
    );
  }

  // ==========================================
  // 13. DRAGON FRUIT (Magenta shell with wavy flame scales & speckled pulp)
  // ==========================================
  static ColoringPage _buildDragonFruit() {
    return ColoringPage(
      id: 'dragon_fruit',
      name: 'Exotic Dragon Fruit',
      category: FruitCategory.tropical,
      difficulty: 'Detailed',
      funFact: 'Dragon fruit flowers only bloom at night and are pollinated by bats and moths!',
      iconEmoji: '🐉',
      imageAsset: 'assets/images/dragon_fruit.jpg',
      suggestedColors: const [
        Color(0xFFFF79B0),
        Color(0xFF64DDA0),
        Color(0xFFFFF9F0),
        Color(0xFF25264A),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Magenta Outer Skin',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 100, 130),
        ),
        ColorRegion(
          id: 'inner_pulp',
          name: 'White Seeded Pulp',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 75, 105),
        ),
        ColorRegion(
          id: 'scale_left',
          name: 'Left Flame Scale',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(140, 220, 70, 180, 32),
        ),
        ColorRegion(
          id: 'scale_right',
          name: 'Right Flame Scale',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(260, 220, 330, 180, 32),
        ),
        ColorRegion(
          id: 'scale_top',
          name: 'Top Flame Crown',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 100, 200, 35, 30),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 200 * h.sx,
            height: 260 * h.sy,
          ),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 150 * h.sx,
            height: 210 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(h.leaf(140, 220, 70, 180, 32), paint);
        canvas.drawPath(h.leaf(260, 220, 330, 180, 32), paint);
        canvas.drawPath(h.leaf(200, 100, 200, 35, 30), paint);
      },
    );
  }

  // ==========================================
  // 14. AVOCADO (Pear-shaped halved avocado with giant round seed pit)
  // ==========================================
  static ColoringPage _buildAvocado() {
    return ColoringPage(
      id: 'avocado',
      name: 'Creamy Avocado',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Avocado is botanically a single-seeded berry!',
      iconEmoji: '🥑',
      imageAsset: 'assets/images/avocado.jpg',
      suggestedColors: const [
        Color(0xFF2E7D32),
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'skin',
          name: 'Dark Pebbled Skin',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(160), h.y(90));
            p.cubicTo(h.x(130), h.y(150), h.x(85), h.y(230), h.x(95), h.y(300));
            p.cubicTo(
              h.x(110),
              h.y(365),
              h.x(290),
              h.y(365),
              h.x(305),
              h.y(300),
            );
            p.cubicTo(
              h.x(315),
              h.y(230),
              h.x(270),
              h.y(150),
              h.x(240),
              h.y(90),
            );
            p.cubicTo(h.x(215), h.y(75), h.x(185), h.y(75), h.x(160), h.y(90));
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'meat',
          name: 'Pale Green Meat',
          zIndex: 2,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(165), h.y(115));
            p.cubicTo(
              h.x(140),
              h.y(165),
              h.x(105),
              h.y(235),
              h.x(115),
              h.y(290),
            );
            p.cubicTo(
              h.x(125),
              h.y(345),
              h.x(275),
              h.y(345),
              h.x(285),
              h.y(290),
            );
            p.cubicTo(
              h.x(295),
              h.y(235),
              h.x(260),
              h.y(165),
              h.x(235),
              h.y(115),
            );
            p.cubicTo(
              h.x(215),
              h.y(100),
              h.x(185),
              h.y(100),
              h.x(165),
              h.y(115),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'seed',
          name: 'Round Brown Seed Pit',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 260, 52),
        ),
        ColorRegion(
          id: 'seed_shine',
          name: 'Pit Highlight',
          zIndex: 4,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(180, 245, 12, 22, -30),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final skin = Path();
        skin.moveTo(h.x(160), h.y(90));
        skin.cubicTo(h.x(130), h.y(150), h.x(85), h.y(230), h.x(95), h.y(300));
        skin.cubicTo(
          h.x(110),
          h.y(365),
          h.x(290),
          h.y(365),
          h.x(305),
          h.y(300),
        );
        skin.cubicTo(h.x(315), h.y(230), h.x(270), h.y(150), h.x(240), h.y(90));
        skin.cubicTo(h.x(215), h.y(75), h.x(185), h.y(75), h.x(160), h.y(90));
        skin.close();
        canvas.drawPath(skin, paint);

        final meat = Path();
        meat.moveTo(h.x(165), h.y(115));
        meat.cubicTo(
          h.x(140),
          h.y(165),
          h.x(105),
          h.y(235),
          h.x(115),
          h.y(290),
        );
        meat.cubicTo(
          h.x(125),
          h.y(345),
          h.x(275),
          h.y(345),
          h.x(285),
          h.y(290),
        );
        meat.cubicTo(
          h.x(295),
          h.y(235),
          h.x(260),
          h.y(165),
          h.x(235),
          h.y(115),
        );
        meat.cubicTo(
          h.x(215),
          h.y(100),
          h.x(185),
          h.y(100),
          h.x(165),
          h.y(115),
        );
        meat.close();
        canvas.drawPath(meat, paint);

        // Seed pit outline
        canvas.drawCircle(h.pt(200, 260), 52 * h.sx, paint);

        final finePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = paint.strokeWidth * 0.55;

        // Pit specular reflection crescent
        canvas.drawPath(h.oval(180, 245, 12, 22, -30), finePaint);
      },
    );
  }

  // ==========================================
  // 15. BLUEBERRY (Plump berry with 5-point star calyx & leaves)
  // ==========================================
  static ColoringPage _buildBlueberry() {
    return ColoringPage(
      id: 'blueberry',
      name: 'Plump Blueberry',
      category: FruitCategory.berries,
      difficulty: 'Easy',
      funFact: 'Blueberries protect their berries with a natural silvery wax called "bloom"!',
      iconEmoji: '🫐',
      imageAsset: 'assets/images/blueberry.jpg',
      suggestedColors: const [
        Color(0xFF58C7FA),
        Color(0xFF9875FF),
        Color(0xFF25264A),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Berry Globe',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 120),
        ),
        ColorRegion(
          id: 'calyx_star',
          name: 'Star Calyx Crown',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).star(200, 140, 28, 14, 5),
        ),
        ColorRegion(
          id: 'leaf_1',
          name: 'Right Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 110, 290, 70, 28),
        ),
        ColorRegion(
          id: 'leaf_2',
          name: 'Left Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(180, 115, 110, 80, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 120 * h.sx, paint);
        canvas.drawPath(h.star(200, 140, 28, 14, 5), paint);
        canvas.drawPath(h.leaf(200, 110, 290, 70, 28), paint);
        canvas.drawPath(h.leaf(180, 115, 110, 80, 24), paint);
      },
    );
  }

  // ==========================================
  // 16. RASPBERRY (12 distinct plump rounded drupelets & top sepal cap)
  // ==========================================
  static ColoringPage _buildRaspberry() {
    final pts = [
      [170, 160],
      [230, 160],
      [140, 205],
      [195, 200],
      [255, 205],
      [145, 255],
      [200, 250],
      [255, 255],
      [170, 295],
      [230, 295],
      [200, 335],
    ];
    return ColoringPage(
      id: 'raspberry',
      name: 'Sweet Raspberry',
      category: FruitCategory.berries,
      difficulty: 'Medium',
      funFact: 'A single raspberry is made up of about 100 tiny individual fruit pods called drupelets!',
      iconEmoji: '🍇',
      imageAsset: 'assets/images/raspberry.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFFFF79B0),
        Color(0xFF64DDA0),
      ],
      regions: [
        ...pts.asMap().entries.map(
          (e) => ColorRegion(
            id: 'drupelet_${e.key}',
            name: 'Drupelet ${e.key + 1}',
            zIndex: 1,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(e.value[0].toDouble(), e.value[1].toDouble(), 26),
          ),
        ),
        ColorRegion(
          id: 'sepal',
          name: 'Green Calyx Cap',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [200, 145],
            [160, 100],
            [200, 70],
            [240, 100],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        for (final p in pts) {
          canvas.drawCircle(
            h.pt(p[0].toDouble(), p[1].toDouble()),
            26 * h.sx,
            paint,
          );
        }
        canvas.drawPath(
          h.polygon([
            [200, 145],
            [160, 100],
            [200, 70],
            [240, 100],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 17. BLACKBERRY (Deep dark textured aggregate berry with sepals)
  // ==========================================
  static ColoringPage _buildBlackberry() {
    final pts = [
      [170, 160],
      [230, 160],
      [140, 205],
      [195, 200],
      [255, 205],
      [145, 255],
      [200, 250],
      [255, 255],
      [170, 295],
      [230, 295],
      [200, 335],
    ];
    return ColoringPage(
      id: 'blackberry',
      name: 'Wild Blackberry',
      category: FruitCategory.berries,
      difficulty: 'Medium',
      funFact: 'Blackberries are rich in powerful anthocyanins that give them their deep dark color!',
      iconEmoji: '🫐',
      imageAsset: 'assets/images/blackberry.jpg',
      suggestedColors: const [
        Color(0xFF25264A),
        Color(0xFF9875FF),
        Color(0xFF64DDA0),
      ],
      regions: [
        ...pts.asMap().entries.map(
          (e) => ColorRegion(
            id: 'drupelet_${e.key}',
            name: 'Drupelet ${e.key + 1}',
            zIndex: 1,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(e.value[0].toDouble(), e.value[1].toDouble(), 26),
          ),
        ),
        ColorRegion(
          id: 'calyx',
          name: 'Top Star Calyx',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [200, 145],
            [150, 95],
            [200, 65],
            [250, 95],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        for (final p in pts) {
          canvas.drawCircle(
            h.pt(p[0].toDouble(), p[1].toDouble()),
            26 * h.sx,
            paint,
          );
        }
        canvas.drawPath(
          h.polygon([
            [200, 145],
            [150, 95],
            [200, 65],
            [250, 95],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 18. CHERRY (Twin plump cherries joined by arched stems & twin leaves)
  // ==========================================
  static ColoringPage _buildCherry() {
    return ColoringPage(
      id: 'cherry',
      name: 'Twin Cherries',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'A cherry tree can produce over 7,000 cherries in a single summer harvest!',
      iconEmoji: '🍒',
      imageAsset: 'assets/images/cherry.jpg',
      suggestedColors: const [
        Color(0xFFFF2E4C),
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'cherry_left',
          name: 'Left Cherry',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(140, 260, 58),
        ),
        ColorRegion(
          id: 'cherry_right',
          name: 'Right Cherry',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(260, 260, 58),
        ),
        ColorRegion(
          id: 'leaf_1',
          name: 'Leaf 1',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 80, 280, 50, 26),
        ),
        ColorRegion(
          id: 'leaf_2',
          name: 'Leaf 2',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 80, 120, 60, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(140, 260), 58 * h.sx, paint);
        canvas.drawCircle(h.pt(260, 260), 58 * h.sx, paint);
        final stem1 = Path()
          ..moveTo(h.x(140), h.y(205))
          ..quadraticBezierTo(h.x(160), h.y(120), h.x(200), h.y(80));
        final stem2 = Path()
          ..moveTo(h.x(260), h.y(205))
          ..quadraticBezierTo(h.x(240), h.y(120), h.x(200), h.y(80));
        canvas.drawPath(stem1, paint);
        canvas.drawPath(stem2, paint);
        canvas.drawPath(h.leaf(200, 80, 280, 50, 26), paint);
        canvas.drawPath(h.leaf(200, 80, 120, 60, 24), paint);
      },
    );
  }

  // ==========================================
  // 19. PEACH (Fuzzy cleft heart lobes, stem & slender leaf)
  // ==========================================
  static ColoringPage _buildPeach() {
    return ColoringPage(
      id: 'peach',
      name: 'Fuzzy Peach',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'Peaches originally came from China, where they symbolize long life and immortality!',
      iconEmoji: '🍑',
      imageAsset: 'assets/images/peach.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFF79B0),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body_left',
          name: 'Left Peach Lobe',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).oval(160, 220, 75, 95),
        ),
        ColorRegion(
          id: 'body_right',
          name: 'Right Peach Lobe',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).oval(240, 220, 75, 95),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Stem',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 120],
            [195, 75],
            [205, 75],
            [205, 120],
          ]),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Peach Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 100, 285, 65, 26),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 225),
            width: 220 * h.sx,
            height: 210 * h.sy,
          ),
          paint,
        );
        canvas.drawLine(h.pt(200, 120), h.pt(200, 270), paint);
        canvas.drawPath(
          h.polygon([
            [195, 120],
            [195, 75],
            [205, 75],
            [205, 120],
          ]),
          paint,
        );
        canvas.drawPath(h.leaf(200, 100, 285, 65, 26), paint);
      },
    );
  }

  // ==========================================
  // 20. PEAR (Graceful pyriform bell curve, stem & leaf)
  // ==========================================
  static ColoringPage _buildPear() {
    return ColoringPage(
      id: 'pear',
      name: 'Sweet Pear',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'Pears are one of the world’s oldest cultivated fruits dating back thousands of years!',
      iconEmoji: '🍐',
      imageAsset: 'assets/images/pear.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Pear Bell Body',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(170), h.y(120));
            p.cubicTo(
              h.x(140),
              h.y(170),
              h.x(90),
              h.y(240),
              h.x(100),
              h.y(300),
            );
            p.cubicTo(
              h.x(120),
              h.y(360),
              h.x(280),
              h.y(360),
              h.x(300),
              h.y(300),
            );
            p.cubicTo(
              h.x(310),
              h.y(240),
              h.x(260),
              h.y(170),
              h.x(230),
              h.y(120),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'stem',
          name: 'Woody Stem',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 120],
            [190, 65],
            [205, 65],
            [205, 120],
          ]),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Curved Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 90, 275, 70, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final p = Path();
        p.moveTo(h.x(170), h.y(120));
        p.cubicTo(h.x(140), h.y(170), h.x(90), h.y(240), h.x(100), h.y(300));
        p.cubicTo(h.x(120), h.y(360), h.x(280), h.y(360), h.x(300), h.y(300));
        p.cubicTo(h.x(310), h.y(240), h.x(260), h.y(170), h.x(230), h.y(120));
        p.close();
        canvas.drawPath(p, paint);
        canvas.drawPath(
          h.polygon([
            [195, 120],
            [190, 65],
            [205, 65],
            [205, 120],
          ]),
          paint,
        );
        canvas.drawPath(h.leaf(200, 90, 275, 70, 24), paint);
      },
    );
  }

  // ==========================================
  // 21. PLUM (Deep plum with side crease & leaf)
  // ==========================================
  static ColoringPage _buildPlum() {
    return ColoringPage(
      id: 'plum',
      name: 'Purple Plum',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'Dried plums are called prunes and are packed with vitamins and fiber!',
      iconEmoji: '🫐',
      imageAsset: 'assets/images/plum.jpg',
      suggestedColors: const [
        Color(0xFF9875FF),
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Plum Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 110, 125),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 95, 270, 65, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 220 * h.sx,
            height: 250 * h.sy,
          ),
          paint,
        );
        canvas.drawLine(h.pt(200, 100), h.pt(200, 220), paint);
        canvas.drawPath(h.leaf(200, 95, 270, 65, 24), paint);
      },
    );
  }

  // ==========================================
  // 22. APRICOT (Golden apricot with indentation & petite leaf)
  // ==========================================
  static ColoringPage _buildApricot() {
    return ColoringPage(
      id: 'apricot',
      name: 'Golden Apricot',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'Apricots belong to the rose family of plants!',
      iconEmoji: '🍑',
      imageAsset: 'assets/images/apricot.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Apricot Body',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 115),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Petite Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 105, 260, 75, 20),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 115 * h.sx, paint);
        canvas.drawLine(h.pt(200, 105), h.pt(200, 210), paint);
        canvas.drawPath(h.leaf(200, 105, 260, 75, 20), paint);
      },
    );
  }

  // ==========================================
  // 23. COCONUT (Cracked coconut half with fibrous husk & white meat)
  // ==========================================
  static ColoringPage _buildCoconut() {
    return ColoringPage(
      id: 'coconut',
      name: 'Island Coconut',
      category: FruitCategory.tropical,
      difficulty: 'Medium',
      funFact: 'Coconuts can float for months across ocean currents before sprouting on beaches!',
      iconEmoji: '🥥',
      imageAsset: 'assets/images/coconut.jpg',
      suggestedColors: const [
        Color(0xFF795548),
        Color(0xFFFFF9F0),
        Color(0xFF58C7FA),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'husk',
          name: 'Fibrous Brown Husk',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 130),
        ),
        ColorRegion(
          id: 'meat',
          name: 'White Meat Rim',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 105),
        ),
        ColorRegion(
          id: 'water',
          name: 'Coconut Water Cavity',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 75),
        ),
        ColorRegion(
          id: 'palm_frond',
          name: 'Palm Frond Leaf',
          zIndex: 4,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 90, 310, 45, 30),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 130 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 105 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 75 * h.sx, paint);
        canvas.drawPath(h.leaf(200, 90, 310, 45, 30), paint);
      },
    );
  }

  // ==========================================
  // 24. LEMON (Pointed oval lemon with citrus slice & branch)
  // ==========================================
  static ColoringPage _buildLemon() {
    return ColoringPage(
      id: 'lemon',
      name: 'Zesty Lemon',
      category: FruitCategory.citrus,
      difficulty: 'Easy',
      funFact: 'Lemons contain high levels of citric acid that create electricity to power small bulbs!',
      iconEmoji: '🍋',
      imageAsset: 'assets/images/lemon.jpg',
      suggestedColors: const [
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
        Color(0xFF58C7FA),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Lemon Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 135, 95, 15),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Citrus Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(170, 120, 100, 65, 28),
        ),
        ColorRegion(
          id: 'highlight',
          name: 'Sunlight Highlight',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(160, 180, 18, 40, -10),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawPath(h.oval(200, 220, 135, 95, 15), paint);
        canvas.drawPath(h.leaf(170, 120, 100, 65, 28), paint);
        canvas.drawPath(
          h.oval(160, 180, 18, 40, -10),
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      },
    );
  }

  // ==========================================
  // 25. LIME (Smooth round lime with slice wedges & leaf)
  // ==========================================
  static ColoringPage _buildLime() {
    return ColoringPage(
      id: 'lime',
      name: 'Crisp Lime',
      category: FruitCategory.citrus,
      difficulty: 'Easy',
      funFact: 'Sailors used limes to prevent scurvy on long sea journeys!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/lime.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
        Color(0xFF58C7FA),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Lime Globe',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 120),
        ),
        ColorRegion(
          id: 'inner_ring',
          name: 'Inner Pulp Ring',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 85),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Lime Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 100, 280, 55, 26),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 120 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 85 * h.sx, paint);
        for (int i = 0; i < 6; i++) {
          final a = i * 60 * math.pi / 180;
          canvas.drawLine(
            h.pt(200, 220),
            h.pt(200 + 85 * math.cos(a), 220 + 85 * math.sin(a)),
            paint,
          );
        }
        canvas.drawPath(h.leaf(200, 100, 280, 55, 26), paint);
      },
    );
  }

  // ==========================================
  // 26. GRAPEFRUIT (Halved citrus showing thick rind, pith & 8 pink segments)
  // ==========================================
  static ColoringPage _buildGrapefruit() {
    return ColoringPage(
      id: 'grapefruit',
      name: 'Ruby Grapefruit',
      category: FruitCategory.citrus,
      difficulty: 'Medium',
      funFact:
          'Grapefruits grow on trees in clusters resembling big grape bunches!',
      iconEmoji: '🍊',
      imageAsset: 'assets/images/grapefruit.jpg',
      suggestedColors: const [
        Color(0xFFFF79B0),
        Color(0xFFFF9638),
        Color(0xFFFFD447),
      ],
      regions: [
        ColorRegion(
          id: 'rind',
          name: 'Yellow-Orange Rind',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 135),
        ),
        ColorRegion(
          id: 'pith',
          name: 'White Pith Margin',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 115),
        ),
        ...List.generate(8, (i) {
          final a = i * 45 * math.pi / 180;
          return ColorRegion(
            id: 'segment_$i',
            name: 'Ruby Segment ${i + 1}',
            zIndex: 3,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .wedge(200, 220, 16, 95, a + 0.08, (math.pi / 4) - 0.16),
          );
        }),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 135 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 115 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 16 * h.sx, paint);
        for (int i = 0; i < 8; i++) {
          final a = i * 45 * math.pi / 180;
          canvas.drawLine(
            h.pt(200 + 16 * math.cos(a), 220 + 16 * math.sin(a)),
            h.pt(200 + 115 * math.cos(a), 220 + 115 * math.sin(a)),
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 27. JACKFRUIT (Massive oblong fruit with studded bumpy peel & inner bulbs)
  // ==========================================
  static ColoringPage _buildJackfruit() {
    return ColoringPage(
      id: 'jackfruit',
      name: 'Giant Jackfruit',
      category: FruitCategory.tropical,
      difficulty: 'Detailed',
      funFact: 'Jackfruit is the largest tree-borne fruit in the entire world, weighing up to 80 pounds!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/jackfruit.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
        Color(0xFFFF9638),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Studded Bumpy Peel',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 230, 110, 145),
        ),
        ColorRegion(
          id: 'bulb_center',
          name: 'Sweet Bulb Pod',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).oval(200, 230, 48, 70),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Thick Trunk Stem',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [190, 85],
            [190, 45],
            [210, 45],
            [210, 85],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 230),
            width: 220 * h.sx,
            height: 290 * h.sy,
          ),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 230),
            width: 96 * h.sx,
            height: 140 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [190, 85],
            [190, 45],
            [210, 45],
            [210, 85],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 28. DURIAN (Spiky thorns facets, stalk & custard seed chamber)
  // ==========================================
  static ColoringPage _buildDurian() {
    return ColoringPage(
      id: 'durian',
      name: 'Spiky Durian',
      category: FruitCategory.tropical,
      difficulty: 'Detailed',
      funFact: 'Famous for its strong aroma, durian is considered a delicacy in Southeast Asia!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/durian.jpg',
      suggestedColors: const [
        Color(0xFF8D6E63),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Spiky Husk Shell',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).star(200, 220, 135, 110, 16),
        ),
        ColorRegion(
          id: 'pod',
          name: 'Creamy Custard Pod',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).oval(200, 220, 52, 75),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Woody Stem',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 90],
            [195, 45],
            [205, 45],
            [205, 90],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawPath(h.star(200, 220, 135, 110, 16), paint);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 104 * h.sx,
            height: 150 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(
          h.polygon([
            [195, 90],
            [195, 45],
            [205, 45],
            [205, 90],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 29. LYCHEE (Textured cracked shell revealing translucent pearl fruit)
  // ==========================================
  static ColoringPage _buildLychee() {
    return ColoringPage(
      id: 'lychee',
      name: 'Sweet Lychee',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Under its bumpy red skin lies translucent, fragrant, sweet pearl-white fruit!',
      iconEmoji: '🍓',
      imageAsset: 'assets/images/lychee.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFFFFF9F0),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'shell',
          name: 'Bumpy Red Husk',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 115),
        ),
        ColorRegion(
          id: 'pearl',
          name: 'Pearl Aril Fruit',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 72),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Twig Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 105, 280, 65, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 115 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 72 * h.sx, paint);
        canvas.drawPath(h.leaf(200, 105, 280, 65, 24), paint);
      },
    );
  }

  // ==========================================
  // 30. RAMBUTAN (Hairy tendril spines & sweet translucent interior)
  // ==========================================
  static ColoringPage _buildRambutan() {
    return ColoringPage(
      id: 'rambutan',
      name: 'Hairy Rambutan',
      category: FruitCategory.tropical,
      difficulty: 'Medium',
      funFact:
          'The name Rambutan comes from the Malay word "rambut", meaning hair!',
      iconEmoji: '🧶',
      imageAsset: 'assets/images/rambutan.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
        Color(0xFFFFF9F0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Red Spiny Body',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 120),
        ),
        ColorRegion(
          id: 'inner',
          name: 'White Fruit Core',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 60),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 120 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 60 * h.sx, paint);
        for (int i = 0; i < 18; i++) {
          final a = i * 20 * math.pi / 180;
          final p1 = h.pt(200 + 120 * math.cos(a), 220 + 120 * math.sin(a));
          final p2 = h.pt(
            200 + 155 * math.cos(a + 0.15),
            220 + 155 * math.sin(a + 0.15),
          );
          canvas.drawLine(p1, p2, paint);
        }
      },
    );
  }

  // ==========================================
  // 31. PASSION FRUIT (Purple granadilla bowl filled with golden vesicles)
  // ==========================================
  static ColoringPage _buildPassionFruit() {
    return ColoringPage(
      id: 'passion_fruit',
      name: 'Passion Fruit',
      category: FruitCategory.tropical,
      difficulty: 'Medium',
      funFact: 'Passion fruit contains seeds surrounded by intense, aromatic golden jelly vesicles!',
      iconEmoji: '🟣',
      imageAsset: 'assets/images/passion_fruit.jpg',
      suggestedColors: const [
        Color(0xFF9875FF),
        Color(0xFFFFD447),
        Color(0xFFFF9638),
      ],
      regions: [
        ColorRegion(
          id: 'rind',
          name: 'Purple Bowl Shell',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 125),
        ),
        ColorRegion(
          id: 'pulp',
          name: 'Golden Jelly Pulp',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 92),
        ),
        ...[
          [170, 190],
          [230, 190],
          [180, 240],
          [220, 240],
          [200, 215],
        ].asMap().entries.map(
          (e) => ColorRegion(
            id: 'seed_${e.key}',
            name: 'Seed Pod ${e.key + 1}',
            zIndex: 3,
            pathBuilder: (size) => PathBuilderHelper(size)
                .oval(e.value[0].toDouble(), e.value[1].toDouble(), 8, 12, 25),
          ),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 125 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 92 * h.sx, paint);
        for (final pt in [
          [170, 190],
          [230, 190],
          [180, 240],
          [220, 240],
          [200, 215],
        ]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: h.pt(pt[0].toDouble(), pt[1].toDouble()),
              width: 16 * h.sx,
              height: 24 * h.sy,
            ),
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 32. STAR FRUIT (Five-pointed star carambola cross-section)
  // ==========================================
  static ColoringPage _buildStarFruit() {
    return ColoringPage(
      id: 'star_fruit',
      name: 'Star Fruit',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'When sliced crosswise, this tropical carambola forms perfect five-pointed stars!',
      iconEmoji: '⭐',
      imageAsset: 'assets/images/star_fruit.jpg',
      suggestedColors: const [
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
        Color(0xFFFF9638),
      ],
      regions: [
        ColorRegion(
          id: 'star_outer',
          name: 'Star Outline Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).star(200, 220, 135, 65, 5),
        ),
        ColorRegion(
          id: 'star_inner',
          name: 'Inner Star Core',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).star(200, 220, 45, 20, 5),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawPath(h.star(200, 220, 135, 65, 5), paint);
        canvas.drawPath(h.star(200, 220, 45, 20, 5), paint);
      },
    );
  }

  // ==========================================
  // 33. CUSTARD APPLE (Heart shape covered in knobby rounded scales & stem)
  // ==========================================
  static ColoringPage _buildCustardApple() {
    return ColoringPage(
      id: 'custard_apple',
      name: 'Custard Apple',
      category: FruitCategory.apples,
      difficulty: 'Detailed',
      funFact: 'Custard apple is also called Sitaphal and has sweet flesh that tastes like sweet custard!',
      iconEmoji: '🍏',
      imageAsset: 'assets/images/custard_apple.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFF9F0),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Knobby Scaled Body',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 125),
        ),
        ...List.generate(6, (i) {
          final a = i * 60 * math.pi / 180;
          return ColorRegion(
            id: 'scale_$i',
            name: 'Knobby Scale ${i + 1}',
            zIndex: 2,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(200 + 60 * math.cos(a), 220 + 60 * math.sin(a), 26),
          );
        }),
        ColorRegion(
          id: 'stem',
          name: 'Stem',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 95],
            [195, 55],
            [205, 55],
            [205, 95],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 125 * h.sx, paint);
        for (int i = 0; i < 6; i++) {
          final a = i * 60 * math.pi / 180;
          canvas.drawCircle(
            h.pt(200 + 60 * math.cos(a), 220 + 60 * math.sin(a)),
            26 * h.sx,
            paint,
          );
        }
        canvas.drawPath(
          h.polygon([
            [195, 95],
            [195, 55],
            [205, 55],
            [205, 95],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 34. SAPODILLA (Chiku oval fruit with sliced half & almond seeds)
  // ==========================================
  static ColoringPage _buildSapodilla() {
    return ColoringPage(
      id: 'sapodilla',
      name: 'Sweet Sapodilla',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Also called Chiku, its sap was historically used to make natural chewing gum (chicle)!',
      iconEmoji: '🥔',
      imageAsset: 'assets/images/sapodilla.jpg',
      suggestedColors: const [
        Color(0xFF8D6E63),
        Color(0xFFFFD447),
        Color(0xFF25264A),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Brown Chiku Skin',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 115, 140),
        ),
        ColorRegion(
          id: 'pulp',
          name: 'Caramel Flesh',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 85, 105),
        ),
        ColorRegion(
          id: 'seed_1',
          name: 'Shiny Seed 1',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(180, 215, 10, 25, -20),
        ),
        ColorRegion(
          id: 'seed_2',
          name: 'Shiny Seed 2',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(220, 225, 10, 25, 20),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 230 * h.sx,
            height: 280 * h.sy,
          ),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 170 * h.sx,
            height: 210 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(h.oval(180, 215, 10, 25, -20), paint);
        canvas.drawPath(h.oval(220, 225, 10, 25, 20), paint);
      },
    );
  }

  // ==========================================
  // 35. FIG (Classic teardrop Anjeer with wrinkled neck & base eye)
  // ==========================================
  static ColoringPage _buildFig() {
    return ColoringPage(
      id: 'fig',
      name: 'Sweet Fig',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Figs are inverted flowers that bloom inside their fleshy pods!',
      iconEmoji: '🫐',
      imageAsset: 'assets/images/fig.jpg',
      suggestedColors: const [
        Color(0xFF9875FF),
        Color(0xFFFF79B0),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Fig Teardrop Body',
          zIndex: 1,
          pathBuilder: (size) {
            final h = PathBuilderHelper(size);
            final p = Path();
            p.moveTo(h.x(200), h.y(100));
            p.cubicTo(
              h.x(260),
              h.y(160),
              h.x(310),
              h.y(250),
              h.x(280),
              h.y(310),
            );
            p.cubicTo(
              h.x(250),
              h.y(350),
              h.x(150),
              h.y(350),
              h.x(120),
              h.y(310),
            );
            p.cubicTo(
              h.x(90),
              h.y(250),
              h.x(140),
              h.y(160),
              h.x(200),
              h.y(100),
            );
            p.close();
            return p;
          },
        ),
        ColorRegion(
          id: 'stem',
          name: 'Fig Stem Neck',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 100],
            [195, 50],
            [205, 50],
            [205, 100],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        final p = Path();
        p.moveTo(h.x(200), h.y(100));
        p.cubicTo(h.x(260), h.y(160), h.x(310), h.y(250), h.x(280), h.y(310));
        p.cubicTo(h.x(250), h.y(350), h.x(150), h.y(350), h.x(120), h.y(310));
        p.cubicTo(h.x(90), h.y(250), h.x(140), h.y(160), h.x(200), h.y(100));
        p.close();
        canvas.drawPath(p, paint);
        canvas.drawPath(
          h.polygon([
            [195, 100],
            [195, 50],
            [205, 50],
            [205, 100],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 36. DATES (Cluster of oblong palm dates hanging from stalk)
  // ==========================================
  static ColoringPage _buildDates() {
    return ColoringPage(
      id: 'dates',
      name: 'Desert Dates',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Date palms have provided sustenance to desert travelers for thousands of years!',
      iconEmoji: '🌴',
      imageAsset: 'assets/images/dates.jpg',
      suggestedColors: const [
        Color(0xFF795548),
        Color(0xFFFF9638),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'date_1',
          name: 'Date 1',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(160, 200, 35, 60, -15),
        ),
        ColorRegion(
          id: 'date_2',
          name: 'Date 2',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(240, 210, 35, 60, 15),
        ),
        ColorRegion(
          id: 'date_3',
          name: 'Date 3',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 275, 35, 60, 0),
        ),
        ColorRegion(
          id: 'frond',
          name: 'Palm Frond',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 120, 280, 80, 25),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawPath(h.oval(160, 200, 35, 60, -15), paint);
        canvas.drawPath(h.oval(240, 210, 35, 60, 15), paint);
        canvas.drawPath(h.oval(200, 275, 35, 60, 0), paint);
        canvas.drawPath(h.leaf(200, 120, 280, 80, 25), paint);
      },
    );
  }

  // ==========================================
  // 37. PERSIMMON (Tomato-like squat fruit with 4-lobed leafy calyx)
  // ==========================================
  static ColoringPage _buildPersimmon() {
    return ColoringPage(
      id: 'persimmon',
      name: 'Autumn Persimmon',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'In Japan, persimmons are considered a symbol of good luck and fortune!',
      iconEmoji: '🍅',
      imageAsset: 'assets/images/persimmon.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Persimmon Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 230, 125, 105),
        ),
        ColorRegion(
          id: 'calyx',
          name: 'Four-Leaf Calyx Cap',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).star(200, 125, 48, 20, 4),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 230),
            width: 250 * h.sx,
            height: 210 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(h.star(200, 125, 48, 20, 4), paint);
      },
    );
  }

  // ==========================================
  // 38. CRANBERRY (Trio of tart round cranberries with stems & glossy leaves)
  // ==========================================
  static ColoringPage _buildCranberry() {
    return ColoringPage(
      id: 'cranberry',
      name: 'Tart Cranberry',
      category: FruitCategory.berries,
      difficulty: 'Easy',
      funFact: 'Cranberry farmers flood the bogs with water so the buoyant berries float to the surface!',
      iconEmoji: '🔴',
      imageAsset: 'assets/images/cranberry.jpg',
      suggestedColors: const [
        Color(0xFFFF2E4C),
        Color(0xFFFF5B67),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'berry_1',
          name: 'Cranberry 1',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(150, 210, 52),
        ),
        ColorRegion(
          id: 'berry_2',
          name: 'Cranberry 2',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(250, 230, 55),
        ),
        ColorRegion(
          id: 'berry_3',
          name: 'Cranberry 3',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(190, 280, 48),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Glossy Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 140, 270, 95, 24),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(150, 210), 52 * h.sx, paint);
        canvas.drawCircle(h.pt(250, 230), 55 * h.sx, paint);
        canvas.drawCircle(h.pt(190, 280), 48 * h.sx, paint);
        canvas.drawPath(h.leaf(200, 140, 270, 95, 24), paint);
      },
    );
  }

  // ==========================================
  // 39. MULBERRY (Cylindrical aggregate berry with multiple nodules)
  // ==========================================
  static ColoringPage _buildMulberry() {
    return ColoringPage(
      id: 'mulberry',
      name: 'Ripe Mulberry',
      category: FruitCategory.berries,
      difficulty: 'Medium',
      funFact: 'Mulberry leaves are the sole food source of natural silkworms!',
      iconEmoji: '🫐',
      imageAsset: 'assets/images/mulberry.jpg',
      suggestedColors: const [
        Color(0xFF9875FF),
        Color(0xFF25264A),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Long Mulberry Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 65, 115),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Serrated Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 105, 290, 75, 30),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 130 * h.sx,
            height: 230 * h.sy,
          ),
          paint,
        );
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(
            h.pt(140, 150 + i * 30),
            h.pt(260, 150 + i * 30),
            paint,
          );
        }
        canvas.drawPath(h.leaf(200, 105, 290, 75, 30), paint);
      },
    );
  }

  // ==========================================
  // 40. GOOSEBERRY (Translucent round berry with vertical striations)
  // ==========================================
  static ColoringPage _buildGooseberry() {
    return ColoringPage(
      id: 'gooseberry',
      name: 'Green Gooseberry',
      category: FruitCategory.berries,
      difficulty: 'Easy',
      funFact: 'Gooseberries have delicate translucent skin showcasing vertical leaf-like veins!',
      iconEmoji: '🟢',
      imageAsset: 'assets/images/gooseberry.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Translucent Berry',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 120),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Curved Twig',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).polygon([
            [195, 100],
            [195, 55],
            [205, 55],
            [205, 100],
          ]),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 120 * h.sx, paint);
        for (int i = 1; i <= 3; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: h.pt(200, 220),
              width: i * 70 * h.sx,
              height: 240 * h.sy,
            ),
            paint,
          );
        }
        canvas.drawPath(
          h.polygon([
            [195, 100],
            [195, 55],
            [205, 55],
            [205, 100],
          ]),
          paint,
        );
      },
    );
  }

  // ==========================================
  // 41. AMLA (Indian gooseberry with 6 vertical ribbed segments)
  // ==========================================
  static ColoringPage _buildAmla() {
    return ColoringPage(
      id: 'amla',
      name: 'Indian Amla',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'Amla is a super-fruit packed with 20 times more vitamin C than an orange!',
      iconEmoji: '🟢',
      imageAsset: 'assets/images/amla.jpg',
      suggestedColors: const [Color(0xFF64DDA0), Color(0xFFFFD447)],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Ribbed Amla Sphere',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 120),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 120 * h.sx, paint);
        for (int i = 0; i < 6; i++) {
          final a = i * 30 * math.pi / 180;
          canvas.drawLine(
            h.pt(200, 220),
            h.pt(200 + 120 * math.cos(a), 220 + 120 * math.sin(a)),
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 42. MUSKMELON (Round melon with raised webbed netting)
  // ==========================================
  static ColoringPage _buildMuskmelon() {
    return ColoringPage(
      id: 'muskmelon',
      name: 'Sweet Muskmelon',
      category: FruitCategory.melons,
      difficulty: 'Medium',
      funFact: 'Muskmelons have a distinctive raised webbed lace pattern covering their sweet rind!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/muskmelon.jpg',
      suggestedColors: const [
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
        Color(0xFFFF9638),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Netted Melon Body',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 125),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 125 * h.sx, paint);
        for (int i = 1; i <= 3; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: h.pt(200, 220),
              width: i * 70 * h.sx,
              height: 250 * h.sy,
            ),
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 43. CANTALOUPE (Halved cantaloupe with rind, thick orange flesh & cavity)
  // ==========================================
  static ColoringPage _buildCantaloupe() {
    return ColoringPage(
      id: 'cantaloupe',
      name: 'Orange Cantaloupe',
      category: FruitCategory.melons,
      difficulty: 'Medium',
      funFact: 'Named after Cantalupo, an Italian town near Rome where it was cultivated in gardens!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/cantaloupe.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
      ],
      regions: [
        ColorRegion(
          id: 'rind',
          name: 'Netted Outer Rind',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 128),
        ),
        ColorRegion(
          id: 'flesh',
          name: 'Sweet Orange Flesh',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 98),
        ),
        ColorRegion(
          id: 'seed_core',
          name: 'Scooped Seed Hollow',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 42),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 128 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 98 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 42 * h.sx, paint);
      },
    );
  }

  // ==========================================
  // 44. HONEYDEW (Smooth pale green melon with stem button & leaf)
  // ==========================================
  static ColoringPage _buildHoneydew() {
    return ColoringPage(
      id: 'honeydew',
      name: 'Sweet Honeydew',
      category: FruitCategory.melons,
      difficulty: 'Easy',
      funFact: 'Honeydew melons were considered a sacred food in ancient Egyptian royal courts!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/honeydew.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFF9F0),
        Color(0xFFFFD447),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Smooth Honeydew Body',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 125),
        ),
        ColorRegion(
          id: 'stem',
          name: 'Stem Button',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 95, 12),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Leaf',
          zIndex: 3,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 95, 275, 60, 25),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 125 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 95), 12 * h.sx, paint);
        canvas.drawPath(h.leaf(200, 95, 275, 60, 25), paint);
      },
    );
  }

  // ==========================================
  // 45. TANGERINE (Squat easy-peel citrus with stem & twin leaves)
  // ==========================================
  static ColoringPage _buildTangerine() {
    return ColoringPage(
      id: 'tangerine',
      name: 'Sweet Tangerine',
      category: FruitCategory.citrus,
      difficulty: 'Easy',
      funFact: 'Tangerines got their name from Tangier, Morocco, where they were exported from!',
      iconEmoji: '🍊',
      imageAsset: 'assets/images/tangerine.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Puffy Tangerine Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 220, 130, 105),
        ),
        ColorRegion(
          id: 'leaf_1',
          name: 'Right Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 115, 275, 75, 25),
        ),
        ColorRegion(
          id: 'leaf_2',
          name: 'Left Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(190, 115, 120, 80, 22),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 220),
            width: 260 * h.sx,
            height: 210 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(h.leaf(200, 115, 275, 75, 25), paint);
        canvas.drawPath(h.leaf(190, 115, 120, 80, 22), paint);
      },
    );
  }

  // ==========================================
  // 46. MANDARIN (Flattened citrus with peeled crescent slice)
  // ==========================================
  static ColoringPage _buildMandarin() {
    return ColoringPage(
      id: 'mandarin',
      name: 'Little Mandarin',
      category: FruitCategory.citrus,
      difficulty: 'Easy',
      funFact: 'Mandarins are the ancestral wild parents of modern cultivated oranges!',
      iconEmoji: '🍊',
      imageAsset: 'assets/images/mandarin.jpg',
      suggestedColors: const [
        Color(0xFFFF9638),
        Color(0xFFFFD447),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Mandarin Body',
          zIndex: 1,
          pathBuilder: (size) =>
              PathBuilderHelper(size).oval(200, 225, 125, 100),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Petite Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 125, 130, 85, 22),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawOval(
          Rect.fromCenter(
            center: h.pt(200, 225),
            width: 250 * h.sx,
            height: 200 * h.sy,
          ),
          paint,
        );
        canvas.drawPath(h.leaf(200, 125, 130, 85, 22), paint);
      },
    );
  }

  // ==========================================
  // 47. NECTARINE (Smooth shiny stone fruit with glowing skin & cleft)
  // ==========================================
  static ColoringPage _buildNectarine() {
    return ColoringPage(
      id: 'nectarine',
      name: 'Smooth Nectarine',
      category: FruitCategory.stoneAndMixed,
      difficulty: 'Easy',
      funFact: 'Nectarines are naturally smooth-skinned peaches without the fuzzy hair!',
      iconEmoji: '🍑',
      imageAsset: 'assets/images/nectarine.jpg',
      suggestedColors: const [
        Color(0xFFFF5B67),
        Color(0xFFFF9638),
        Color(0xFFFFD447),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Smooth Glow Body',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 120),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Slender Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 100, 275, 65, 25),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 120 * h.sx, paint);
        canvas.drawLine(h.pt(200, 100), h.pt(200, 230), paint);
        canvas.drawPath(h.leaf(200, 100, 275, 65, 25), paint);
      },
    );
  }

  // ==========================================
  // 48. BREADFRUIT (Large round fruit with polygonal tessellated skin & giant leaf)
  // ==========================================
  static ColoringPage _buildBreadfruit() {
    return ColoringPage(
      id: 'breadfruit',
      name: 'Island Breadfruit',
      category: FruitCategory.tropical,
      difficulty: 'Medium',
      funFact: 'When baked, breadfruit has a warm, freshly-baked bread aroma and texture!',
      iconEmoji: '🍈',
      imageAsset: 'assets/images/breadfruit.jpg',
      suggestedColors: const [
        Color(0xFF64DDA0),
        Color(0xFFFFD447),
        Color(0xFF795548),
      ],
      regions: [
        ColorRegion(
          id: 'body',
          name: 'Tessellated Fruit',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 125),
        ),
        ColorRegion(
          id: 'leaf',
          name: 'Lobed Giant Leaf',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).leaf(200, 95, 280, 50, 35),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 125 * h.sx, paint);
        canvas.drawPath(h.leaf(200, 95, 280, 50, 35), paint);
      },
    );
  }

  // ==========================================
  // 49. MANGOSTEEN (Queen of fruits: thick purple bowl, 4 woody calyx petals & snow-white segments)
  // ==========================================
  static ColoringPage _buildMangosteen() {
    return ColoringPage(
      id: 'mangosteen',
      name: 'Royal Mangosteen',
      category: FruitCategory.tropical,
      difficulty: 'Medium',
      funFact: 'Known as the "Queen of Fruits", Queen Victoria offered 100 pounds for a fresh one!',
      iconEmoji: '🟣',
      imageAsset: 'assets/images/mangosteen.jpg',
      suggestedColors: const [
        Color(0xFF9875FF),
        Color(0xFF25264A),
        Color(0xFFFFF9F0),
        Color(0xFF64DDA0),
      ],
      regions: [
        ColorRegion(
          id: 'rind',
          name: 'Deep Purple Rind',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 230, 115),
        ),
        ColorRegion(
          id: 'calyx_cap',
          name: 'Woody 4-Petal Calyx',
          zIndex: 2,
          pathBuilder: (size) =>
              PathBuilderHelper(size).star(200, 115, 45, 20, 4),
        ),
        ...List.generate(4, (i) {
          final a = i * 90 * math.pi / 180;
          return ColorRegion(
            id: 'segment_$i',
            name: 'Snow White Segment ${i + 1}',
            zIndex: 3,
            pathBuilder: (size) =>
                PathBuilderHelper(size)
                    .circle(200 + 35 * math.cos(a), 230 + 35 * math.sin(a), 24),
          );
        }),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 230), 115 * h.sx, paint);
        canvas.drawPath(h.star(200, 115, 45, 20, 4), paint);
        for (int i = 0; i < 4; i++) {
          final a = i * 90 * math.pi / 180;
          canvas.drawCircle(
            h.pt(200 + 35 * math.cos(a), 230 + 35 * math.sin(a)),
            24 * h.sx,
            paint,
          );
        }
      },
    );
  }

  // ==========================================
  // 50. LONGAN (Dragon eye cluster with black shining pit)
  // ==========================================
  static ColoringPage _buildLongan() {
    return ColoringPage(
      id: 'longan',
      name: 'Dragon Eye Longan',
      category: FruitCategory.tropical,
      difficulty: 'Easy',
      funFact: 'Longan means "Dragon Eye" because when peeled, the black seed shines through translucent pulp!',
      iconEmoji: '👁️',
      imageAsset: 'assets/images/longan.jpg',
      suggestedColors: const [
        Color(0xFFFFD447),
        Color(0xFF8D6E63),
        Color(0xFF25264A),
        Color(0xFFFFF9F0),
      ],
      regions: [
        ColorRegion(
          id: 'shell',
          name: 'Golden Tan Shell',
          zIndex: 1,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 115),
        ),
        ColorRegion(
          id: 'aril',
          name: 'Translucent Pulp',
          zIndex: 2,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 75),
        ),
        ColorRegion(
          id: 'eye_pupil',
          name: 'Dragon Eye Black Pit',
          zIndex: 3,
          pathBuilder: (size) => PathBuilderHelper(size).circle(200, 220, 36),
        ),
        ColorRegion(
          id: 'pupil_shine',
          name: 'Eye Sparkle',
          zIndex: 4,
          pathBuilder: (size) => PathBuilderHelper(size).circle(192, 212, 10),
        ),
      ],
      drawOutlines: (canvas, size, paint) {
        final h = PathBuilderHelper(size);
        canvas.drawCircle(h.pt(200, 220), 115 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 75 * h.sx, paint);
        canvas.drawCircle(h.pt(200, 220), 36 * h.sx, paint);
        canvas.drawCircle(h.pt(192, 212), 10 * h.sx, paint);
      },
    );
  }
}
