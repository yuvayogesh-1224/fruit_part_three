import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/coloring_page_model.dart';
import '../theme/app_theme.dart';
import '../utils/sound_effect_service.dart';
import '../viewmodels/coloring_viewmodel.dart';
import '../widgets/color_palette.dart';
import '../widgets/drawing_canvas.dart';

class ColoringScreen extends StatefulWidget {
  final ColoringPage page;

  const ColoringScreen({super.key, required this.page});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final TransformationController _transController = TransformationController();
  bool _showBrushSizeMenu = false;
  bool _isFactExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColoringViewModel>().startColoringPage(widget.page);
    });
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transController.value = Matrix4.identity();
    SoundEffectService.playPop();
  }

  void _confirmReset(BuildContext context, ColoringViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.softCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppColors.coralPink, size: 28),
            SizedBox(width: 8),
            Text('Start Fresh?'),
          ],
        ),
        content: const Text(
          'Do you want to clear all colors and strokes on this fruit? You can also undo this action later.',
          style: TextStyle(color: AppColors.deepNavy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.resetCanvas();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showSaveSuccessModal(
    BuildContext context,
    ColoringViewModel vm,
    String? imagePath,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.softCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.mintGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Super Artist!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your ${widget.page.name} artwork was saved to My Artwork!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (imagePath != null && imagePath.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.grapePurple,
                        side: const BorderSide(
                          color: AppColors.grapePurple,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // ignore: deprecated_member_use
                        Share.shareXFiles([
                          XFile(imagePath),
                        ], text: 'Look at my colorful ${widget.page.name}!');
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                if (imagePath != null && imagePath.isNotEmpty)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coralPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      vm.dismissCelebration();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Awesome!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();

    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepNavy.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.deepNavy,
              size: 20,
            ),
          ),
          onPressed: () async {
            if (vm.autoSaveEnabled && vm.regionFills.isNotEmpty) {
              await vm.saveCurrentArtwork();
            }
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.page.iconEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.page.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Undo Button
          IconButton(
            tooltip: 'Undo',
            icon: Icon(
              Icons.undo_rounded,
              color: vm.canUndo ? AppColors.deepNavy : AppColors.lightGray,
            ),
            onPressed: vm.canUndo ? vm.undo : null,
          ),
          // Redo Button
          IconButton(
            tooltip: 'Redo',
            icon: Icon(
              Icons.redo_rounded,
              color: vm.canRedo ? AppColors.deepNavy : AppColors.lightGray,
            ),
            onPressed: vm.canRedo ? vm.redo : null,
          ),
          // Reset Button
          IconButton(
            tooltip: 'Reset Canvas',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.coralPink),
            onPressed: () => _confirmReset(context, vm),
          ),
          // Save Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: vm.isSaving
                  ? null
                  : () async {
                      final saved = await vm.saveCurrentArtwork();
                      if (!context.mounted) return;
                      if (saved != null) {
                        _showSaveSuccessModal(context, vm, saved.imagePath);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.coralSunset,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coralPink.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: vm.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Fun fact strip
              GestureDetector(
                onTap: () => setState(() => _isFactExpanded = !_isFactExpanded),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sunshineYellow.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.sunshineYellow.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.tangerine,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.page.funFact,
                          maxLines: _isFactExpanded ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                      Icon(
                        _isFactExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.tangerine,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Tool Selector Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    // Fill Bucket Tool
                    _buildToolChip(
                      icon: Icons.format_color_fill_rounded,
                      label: 'Fill',
                      isSelected: vm.currentTool == ColoringTool.bucketFill,
                      activeColor: AppColors.coralPink,
                      onTap: () {
                        setState(() => _showBrushSizeMenu = false);
                        vm.selectTool(ColoringTool.bucketFill);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Brush Tool
                    _buildToolChip(
                      icon: Icons.brush_rounded,
                      label: 'Brush',
                      isSelected: vm.currentTool == ColoringTool.brush,
                      activeColor: AppColors.skyBlue,
                      onTap: () {
                        vm.selectTool(ColoringTool.brush);
                        setState(
                          () => _showBrushSizeMenu = !_showBrushSizeMenu,
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Eraser Tool
                    _buildToolChip(
                      icon: Icons.auto_fix_normal_rounded,
                      label: 'Eraser',
                      isSelected: vm.currentTool == ColoringTool.eraser,
                      activeColor: AppColors.hotPink,
                      onTap: () {
                        setState(() => _showBrushSizeMenu = false);
                        vm.selectTool(ColoringTool.eraser);
                      },
                    ),
                    const Spacer(),

                    // Zoom / Draw Mode Lock Toggle
                    GestureDetector(
                      onTap: vm.togglePanZoomLock,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: vm.isPanZoomLocked
                              ? AppColors.pureWhite
                              : AppColors.grapePurple,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: vm.isPanZoomLocked
                                ? AppColors.lightGray
                                : AppColors.grapePurple,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vm.isPanZoomLocked
                                  ? Icons.draw_rounded
                                  : Icons.zoom_in_rounded,
                              size: 16,
                              color: vm.isPanZoomLocked
                                  ? AppColors.deepNavy
                                  : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vm.isPanZoomLocked ? 'Draw' : 'Zoom',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: vm.isPanZoomLocked
                                    ? AppColors.deepNavy
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Reset Zoom Button
                    IconButton(
                      tooltip: 'Reset Zoom',
                      icon: const Icon(
                        Icons.fit_screen_rounded,
                        size: 20,
                        color: AppColors.deepNavy,
                      ),
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),

              // Canvas drawing area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DrawingCanvasWidget(
                    transformationController: _transController,
                  ),
                ),
              ),

              // Bottom Color Palette
              const ColorPaletteWidget(),
            ],
          ),

          // Brush Size Menu Overlay
          if (_showBrushSizeMenu && vm.currentTool == ColoringTool.brush)
            Positioned(
              left: 90,
              top: 105,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                color: AppColors.pureWhite,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.skyBlue.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [4.0, 10.0, 20.0, 36.0].map((size) {
                      final isCurrent = vm.brushSize == size;
                      return GestureDetector(
                        onTap: () {
                          vm.setBrushSize(size);
                          setState(() => _showBrushSizeMenu = false);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.skyBlue.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.skyBlue
                                  : AppColors.lightGray,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: size.clamp(6.0, 24.0),
                              height: size.clamp(6.0, 24.0),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.deepNavy,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0x1825264A),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.deepNavy,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
