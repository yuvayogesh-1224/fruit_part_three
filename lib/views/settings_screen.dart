import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../viewmodels/coloring_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmClearData(BuildContext context, ColoringViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.softCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset All Saved Artworks?'),
        content: const Text(
          'This will remove all your saved colored drawings from this device. Outline pages will remain available.',
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
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.clearAllArtworks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All artworks cleared successfully.'),
                  backgroundColor: AppColors.coralPink,
                ),
              );
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();

    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(title: const Text('Settings & Info')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Mascot Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.rainbowGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coralPink.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🍎', style: TextStyle(fontSize: 34)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fruit Coloring Book',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Color Fun • Version 1.0.0',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '50+ Hand-Drawn Fruit Outlines',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Audio & Haptics Section
          const Text(
            'Sound & Touch',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),

          Material(
            color: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0x1825264A), width: 1.5),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: AppColors.coralPink,
                  title: const Text(
                    'Playful Sound FX',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Satisfying pop and chime sound effects',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.coralPink,
                  ),
                  value: vm.soundEnabled,
                  onChanged: vm.toggleSound,
                ),
                const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.lightGray,
                ),
                SwitchListTile(
                  activeThumbColor: AppColors.sunshineYellow,
                  title: const Text(
                    'Haptic Vibration',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Gentle vibration feedback when coloring',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.vibration_rounded,
                    color: AppColors.sunshineYellow,
                  ),
                  value: vm.hapticsEnabled,
                  onChanged: vm.toggleHaptics,
                ),
                const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.lightGray,
                ),
                SwitchListTile(
                  activeThumbColor: AppColors.mintGreen,
                  title: const Text(
                    'Auto-Save Artwork',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Automatically save drawings when closing canvas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.save_rounded,
                    color: AppColors.mintGreen,
                  ),
                  value: vm.autoSaveEnabled,
                  onChanged: vm.toggleAutoSave,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // How to Color Guide
          const Text(
            'How to Color',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x1825264A), width: 1.5),
            ),
            child: const Column(
              children: [
                _TipItem(
                  emoji: '🪣',
                  title: 'Tap to Fill',
                  description: 'Select Fill tool and tap inside any closed outline to flood it with color.',
                ),
                SizedBox(height: 14),
                _TipItem(
                  emoji: '🖌️',
                  title: 'Magic Brush & Eraser',
                  description: 'Use the brush for freehand details and eraser to clean up strokes.',
                ),
                SizedBox(height: 14),
                _TipItem(
                  emoji: '🔍',
                  title: 'Pinch to Zoom',
                  description: 'Toggle Zoom mode to pinch-in and color tiny seeds, leaves, and stems.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Management
          Material(
            color: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0x1825264A), width: 1.5),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.coralPink,
              ),
              title: const Text(
                'Reset All Artwork Data',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.coralPink,
                ),
              ),
              subtitle: Text(
                '${vm.savedArtworks.length} artworks currently saved',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
              onTap: () => _confirmClearData(context, vm),
            ),
          ),

          const SizedBox(height: 24),

          // Offline Kid-Safe Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mintGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.mintGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.mintGreen,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '100% Offline & Kid-Safe. No internet connection required. No personal data collected.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _TipItem({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
