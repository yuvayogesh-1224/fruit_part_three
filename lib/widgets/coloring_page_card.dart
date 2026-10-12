import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coloring_page_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/coloring_viewmodel.dart';

/// Card showing the crisp black-and-white outline preview of a fruit coloring page
class ColoringPageCard extends StatefulWidget {
  final ColoringPage page;
  final VoidCallback onTap;

  const ColoringPageCard({super.key, required this.page, required this.onTap});

  @override
  State<ColoringPageCard> createState() => _ColoringPageCardState();
}

class _ColoringPageCardState extends State<ColoringPageCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();
    final matches = vm.savedArtworks.where((a) => a.fruitId == widget.page.id);
    final savedArtwork = matches.isNotEmpty ? matches.first : null;
    final isDone =
        savedArtwork != null && savedArtwork.completionPercentage >= 0.99;
    final hasProgress =
        savedArtwork != null && savedArtwork.completionPercentage > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _isPressed ? 0.96 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDone
                  ? AppColors.mintGreen
                  : hasProgress
                  ? AppColors.sunshineYellow
                  : const Color(0x1825264A),
              width: isDone || hasProgress ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepNavy.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drawing Preview Box
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.canvasPaper,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child:
                            savedArtwork != null &&
                                savedArtwork.imagePath.isNotEmpty &&
                                File(savedArtwork.imagePath).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(savedArtwork.imagePath),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : widget.page.imageAsset != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    widget.page.imageAsset!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12),
                                child: CustomPaint(
                                  size: const Size(130, 130),
                                  painter: _OutlineThumbnailPainter(
                                    widget.page,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Category Pill Tag
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.page.category.themeColor.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.page.category.themeColor.withValues(
                              alpha: 0.4,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.page.category.emoji,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.page.category.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.page.category.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Completion Badge
                    if (isDone)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.mintGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      )
                    else if (hasProgress)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sunshineYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(savedArtwork.completionPercentage * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title and details
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.page.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.page.regions.length} coloring zones',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Play Button Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.page.category.themeColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.palette_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter for crisp vector line art thumbnail
class _OutlineThumbnailPainter extends CustomPainter {
  final ColoringPage page;

  _OutlineThumbnailPainter(this.page);

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = const Color(0xFF1E1F3B)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    page.drawOutlines(canvas, size, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _OutlineThumbnailPainter oldDelegate) =>
      oldDelegate.page.id != page.id;
}
