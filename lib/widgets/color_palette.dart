import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../utils/sound_effect_service.dart';
import '../viewmodels/coloring_viewmodel.dart';

/// 24+ Curated vibrant colors for the kid-friendly fruit coloring book
class PaletteColors {
  static const List<Color> curatedColors = [
    // Coral & Reds
    Color(0xFFFF5B67), // Coral Pink
    Color(0xFFFF2E4C), // Bright Ruby
    Color(0xFFE60039), // Crimson
    Color(0xFFFF79B0), // Hot Pink
    Color(0xFFFF4081), // Candy Pink
    Color(0xFFD81B60), // Deep Rose
    // Oranges & Yellows
    Color(0xFFFF9638), // Tangerine
    Color(0xFFFF7A00), // Pure Orange
    Color(0xFFFFA726), // Amber
    Color(0xFFFFD447), // Sunshine Yellow
    Color(0xFFFFEE58), // Lemon Yellow
    Color(0xFFFFCA28), // Golden Honey
    // Fresh Greens
    Color(0xFF64DDA0), // Mint Green
    Color(0xFF2ECC71), // Apple Green
    Color(0xFF10AC84), // Jungle Emerald
    Color(0xFF8BC34A), // Lime Green
    Color(0xFF4CAF50), // Leaf Green
    Color(0xFF2E7D32), // Deep Forest
    // Blues & Turquoises
    Color(0xFF58C7FA), // Sky Blue
    Color(0xFF00CEC9), // Aqua Cyan
    Color(0xFF0984E3), // Ocean Blue
    Color(0xFF74B9FF), // Baby Blue
    Color(0xFF2980B9), // Royal Blue
    // Purples & Violets
    Color(0xFF9875FF), // Grape Purple
    Color(0xFF8E44AD), // Plum Violet
    Color(0xFF6C5CE7), // Lavender Indigo
    Color(0xFFA29BFE), // Lilac Mist
    // Earthy & Neutrals
    Color(0xFF8D6E63), // Cocoa
    Color(0xFF5D4037), // Dark Trunk
    Color(0xFFA0522D), // Saddle Brown
    Color(0xFF25264A), // Deep Navy
    Color(0xFF2D3436), // Charcoal
    Color(0xFFFFF9F0), // Soft Cream
    Color(0xFFFFFFFF), // Pure White
  ];
}

class ColorPaletteWidget extends StatefulWidget {
  const ColorPaletteWidget({super.key});

  @override
  State<ColorPaletteWidget> createState() => _ColorPaletteWidgetState();
}

class _ColorPaletteWidgetState extends State<ColorPaletteWidget> {
  int _selectedCategoryIndex = 0;

  final List<String> _paletteTabs = [
    'All (34)',
    'Fruits 🍎',
    'Sunny ☀️',
    'Green 🍃',
    'Berries 🫐',
    'Pastel 🎨',
  ];

  List<Color> _getFilteredColors() {
    switch (_selectedCategoryIndex) {
      case 1: // Fruits
        return PaletteColors.curatedColors.sublist(0, 8);
      case 2: // Sunny
        return PaletteColors.curatedColors.sublist(6, 12);
      case 3: // Green
        return PaletteColors.curatedColors.sublist(12, 18);
      case 4: // Berries
        return PaletteColors.curatedColors.sublist(22, 27);
      case 5: // Pastel & Earth
        return PaletteColors.curatedColors.sublist(27);
      default:
        return PaletteColors.curatedColors;
    }
  }

  void _showCustomColorPicker(BuildContext context, ColoringViewModel vm) {
    double hue = 0.0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final pickedColor = HSVColor.fromAHSV(
              1.0,
              hue,
              0.85,
              0.95,
            ).toColor();
            return AlertDialog(
              backgroundColor: AppColors.softCream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.palette_rounded,
                    color: AppColors.grapePurple,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Rainbow Wheel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: pickedColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: pickedColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Slide to choose your magic color!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 14,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: hue,
                      min: 0,
                      max: 360,
                      activeColor: pickedColor,
                      onChanged: (val) {
                        setDialogState(() => hue = val);
                        SoundEffectService.playTick();
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
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
                    vm.selectColor(pickedColor);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Choose Color'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();
    final activeColors = _getFilteredColors();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top handle & category tabs
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),

            // Tab bar for palettes
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _paletteTabs.length,
                itemBuilder: (context, idx) {
                  final isSelected = _selectedCategoryIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _paletteTabs[idx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.pureWhite
                              : AppColors.deepNavy,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.coralPink,
                      backgroundColor: AppColors.softCream,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onSelected: (_) {
                        setState(() => _selectedCategoryIndex = idx);
                        SoundEffectService.playPop();
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Color swatches row
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activeColors.length + 1, // +1 for custom picker
                itemBuilder: (context, index) {
                  if (index == activeColors.length) {
                    // Rainbow custom color button
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _showCustomColorPicker(context, vm),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.rainbowGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.pureWhite,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coralPink.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  }

                  final color = activeColors[index];
                  final isSelected =
                      vm.selectedColor.toARGB32() == color.toARGB32();

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => vm.selectColor(color),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        scale: isSelected ? 1.18 : 1.0,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.deepNavy
                                  : Colors.white,
                              width: isSelected ? 3.5 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: isSelected ? 0.45 : 0.2,
                                ),
                                blurRadius: isSelected ? 10 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: color.computeLuminance() > 0.6
                                      ? AppColors.deepNavy
                                      : Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
