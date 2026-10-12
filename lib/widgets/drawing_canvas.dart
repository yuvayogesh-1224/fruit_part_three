import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/artwork_model.dart';
import '../models/coloring_page_model.dart';
import '../theme/app_theme.dart';
import '../utils/flood_fill_engine.dart';
import '../viewmodels/coloring_viewmodel.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final TransformationController transformationController;

  const DrawingCanvasWidget({
    super.key,
    required this.transformationController,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _popAnimController;
  Offset? _lastTapPos;

  @override
  void initState() {
    super.initState();
    _popAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _popAnimController?.dispose();
    super.dispose();
  }

  void _triggerPopEffect(Offset pos) {
    setState(() => _lastTapPos = pos);
    _popAnimController?.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();
    final page = vm.currentPage;
    if (page == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a square canvas fitting comfortably in constraints
        final canvasDimension = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final canvasSize = Size(canvasDimension, canvasDimension);

        return InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: !vm.isPanZoomLocked,
          scaleEnabled: !vm.isPanZoomLocked,
          boundaryMargin: const EdgeInsets.all(80),
          child: Center(
            child: Container(
              width: canvasDimension,
              height: canvasDimension,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.lightGray, width: 3.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    final pos = event.localPosition;
                    if (vm.currentTool == ColoringTool.bucketFill) {
                      _triggerPopEffect(pos);
                      vm.fillRegionAt(pos, canvasSize);
                    } else if (vm.currentTool == ColoringTool.eraser) {
                      _triggerPopEffect(pos);
                      vm.eraseRegionAt(pos, canvasSize);
                      if (vm.isPanZoomLocked) {
                        vm.startStroke(pos, canvasSize);
                      }
                    } else if (vm.currentTool == ColoringTool.brush) {
                      if (vm.isPanZoomLocked) {
                        vm.startStroke(pos, canvasSize);
                      }
                    }
                  },
                  onPointerMove: (event) {
                    if (!vm.isPanZoomLocked) return;
                    final pos = event.localPosition;
                    if (vm.currentTool == ColoringTool.eraser) {
                      vm.eraseRegionAt(pos, canvasSize);
                      vm.updateStroke(pos, canvasSize);
                    } else if (vm.currentTool == ColoringTool.brush) {
                      vm.updateStroke(pos, canvasSize);
                    }
                  },
                  onPointerUp: (_) {
                    if (vm.currentTool != ColoringTool.bucketFill) {
                      vm.endStroke();
                    }
                  },
                  onPointerCancel: (_) {
                    if (vm.currentTool != ColoringTool.bucketFill) {
                      vm.endStroke();
                    }
                  },
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: canvasSize,
                        painter: _FruitMasterCanvasPainter(
                          page: page,
                          regionFills: vm.regionFills,
                          brushStrokes: vm.brushStrokes,
                          activeStroke: vm.activeStroke,
                          drawOutlineArt: true,
                          floodFillController: vm.floodFillController,
                        ),
                      ),

                      // Loading spinner
                      if (vm.floodFillController.isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.coralPink,
                            strokeWidth: 3,
                          ),
                        ),

                      // Touch ripple/pop effect
                      if (_lastTapPos != null && _popAnimController != null)
                        AnimatedBuilder(
                          animation: _popAnimController!,
                          builder: (context, _) {
                            final progress = _popAnimController!.value;
                            if (progress >= 1.0) return const SizedBox.shrink();
                            return Positioned(
                              left: _lastTapPos!.dx - (35 * progress),
                              top: _lastTapPos!.dy - (35 * progress),
                              child: Container(
                                width: 70 * progress,
                                height: 70 * progress,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: vm.selectedColor.withValues(
                                    alpha: (1.0 - progress) * 0.4,
                                  ),
                                  border: Border.all(
                                    color: vm.selectedColor.withValues(
                                      alpha: 1.0 - progress,
                                    ),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter that layers vector region fills, user brush strokes, and crisp outline art
class _FruitMasterCanvasPainter extends CustomPainter {
  final ColoringPage page;
  final Map<String, Color> regionFills;
  final List<BrushStroke> brushStrokes;
  final BrushStroke? activeStroke;
  final bool drawOutlineArt;
  final FloodFillController? floodFillController;

  _FruitMasterCanvasPainter({
    required this.page,
    required this.regionFills,
    required this.brushStrokes,
    required this.activeStroke,
    this.drawOutlineArt = true,
    this.floodFillController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isBotanical = page.imageAsset != null && floodFillController?.hasImage == true;

    // 1. Layer: Background Paper
    final paperPaint = Paint()..color = AppColors.canvasPaper;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paperPaint);

    final scale = size.width / 400.0;

    // 2. Layer: Region Fills
    if (isBotanical) {
      if (floodFillController?.fillImage != null) {
        canvas.drawImageRect(
          floodFillController!.fillImage!,
          Rect.fromLTWH(
            0,
            0,
            floodFillController!.width.toDouble(),
            floodFillController!.height.toDouble(),
          ),
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
    } else {
      final sortedRegions = List<ColorRegion>.from(page.regions)
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

      for (final region in sortedRegions) {
        final color = regionFills[region.id];
        if (color != null) {
          final fillPaint = Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true;
          canvas.drawPath(region.pathBuilder(size), fillPaint);
        }
      }
    }

    // 3. Layer: Freehand Brush Strokes
    final hasStrokes = brushStrokes.isNotEmpty || activeStroke != null;
    if (hasStrokes) {
      final hasErasers = brushStrokes.any((s) => s.isEraser) || (activeStroke?.isEraser == true);

      void drawNormalStroke(BrushStroke s) {
        if (s.points.isEmpty || s.isEraser) return;
        final strokePaint = Paint()
          ..color = s.color
          ..strokeWidth = s.strokeWidth * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        if (s.points.length == 1) {
          canvas.drawCircle(
            Offset(s.points.first.dx * scale, s.points.first.dy * scale),
            (s.strokeWidth * scale) / 2,
            Paint()..color = s.color..style = PaintingStyle.fill..isAntiAlias = true,
          );
          return;
        }

        final path = Path();
        path.moveTo(s.points.first.dx * scale, s.points.first.dy * scale);
        for (int i = 1; i < s.points.length; i++) {
          final p0 = s.points[i - 1];
          final p1 = s.points[i];
          final mx = (p0.dx + p1.dx) / 2 * scale;
          final my = (p0.dy + p1.dy) / 2 * scale;
          path.quadraticBezierTo(p0.dx * scale, p0.dy * scale, mx, my);
        }
        path.lineTo(s.points.last.dx * scale, s.points.last.dy * scale);
        canvas.drawPath(path, strokePaint);
      }

      if (!hasErasers) {
        for (final stroke in brushStrokes) {
          drawNormalStroke(stroke);
        }
        if (activeStroke != null) {
          drawNormalStroke(activeStroke!);
        }
      } else {
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
        for (final stroke in brushStrokes) {
          drawNormalStroke(stroke);
        }
        if (activeStroke != null) {
          drawNormalStroke(activeStroke!);
        }

        void drawEraserStroke(BrushStroke s) {
          if (s.points.isEmpty || !s.isEraser) return;
          final strokePaint = Paint()
            ..blendMode = BlendMode.clear
            ..strokeWidth = s.strokeWidth * scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true;

          if (s.points.length == 1) {
            canvas.drawCircle(
              Offset(s.points.first.dx * scale, s.points.first.dy * scale),
              (s.strokeWidth * scale) / 2,
              Paint()..blendMode = BlendMode.clear..style = PaintingStyle.fill..isAntiAlias = true,
            );
            return;
          }

          final path = Path();
          path.moveTo(s.points.first.dx * scale, s.points.first.dy * scale);
          for (int i = 1; i < s.points.length; i++) {
            final p0 = s.points[i - 1];
            final p1 = s.points[i];
            final mx = (p0.dx + p1.dx) / 2 * scale;
            final my = (p0.dy + p1.dy) / 2 * scale;
            path.quadraticBezierTo(p0.dx * scale, p0.dy * scale, mx, my);
          }
          path.lineTo(s.points.last.dx * scale, s.points.last.dy * scale);
          canvas.drawPath(path, strokePaint);
        }

        for (final stroke in brushStrokes) {
          drawEraserStroke(stroke);
        }
        if (activeStroke != null) {
          drawEraserStroke(activeStroke!);
        }
        canvas.restore();
      }
    }

    // 4. Layer: Master Line Art Outline Overlay
    if (isBotanical) {
      if (floodFillController?.lineArtImage != null) {
        canvas.drawImageRect(
          floodFillController!.lineArtImage!,
          Rect.fromLTWH(
            0,
            0,
            floodFillController!.width.toDouble(),
            floodFillController!.height.toDouble(),
          ),
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()
            ..blendMode = BlendMode.multiply
            ..filterQuality = FilterQuality.high,
        );
      }
    } else if (drawOutlineArt) {
      final outlinePaint = Paint()
        ..color = AppColors.outlineDark
        ..strokeWidth = 4.0 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      page.drawOutlines(canvas, size, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FruitMasterCanvasPainter oldDelegate) => true;
}
