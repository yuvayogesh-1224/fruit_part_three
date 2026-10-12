import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/fruit_coloring_data.dart';
import '../models/artwork_model.dart';
import '../theme/app_theme.dart';
import '../utils/sound_effect_service.dart';
import '../viewmodels/coloring_viewmodel.dart';
import 'coloring_screen.dart';

class MyArtworkScreen extends StatelessWidget {
  const MyArtworkScreen({super.key});

  void _showArtworkDetails(
    BuildContext context,
    SavedArtwork artwork,
    ColoringViewModel vm,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.softCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        final formattedDate = DateFormat('MMM d, y • h:mm a')
            .format(artwork.lastEditedAt);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                artwork.fruitName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Colored on $formattedDate',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Image preview
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepNavy.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: AppColors.lightGray, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: File(artwork.imagePath).existsSync()
                      ? Image.file(File(artwork.imagePath), fit: BoxFit.contain)
                      : const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons row
              Row(
                children: [
                  // Resume Coloring
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coralPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final page = FruitColoringData.getById(artwork.fruitId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ColoringScreen(page: page),
                          ),
                        );
                      },
                      icon: const Icon(Icons.palette_rounded, size: 20),
                      label: const Text('Continue Coloring'),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Share
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 20),
                    onPressed: () {
                      if (File(artwork.imagePath).existsSync()) {
                        // ignore: deprecated_member_use
                        Share.shareXFiles([
                          XFile(artwork.imagePath),
                        ], text: 'Check out my colored ${artwork.fruitName}!');
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Delete
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.lightGray,
                      foregroundColor: AppColors.coralPink,
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, artwork, vm);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    SavedArtwork artwork,
    ColoringViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.softCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Artwork?'),
        content: Text(
          'Are you sure you want to delete your ${artwork.fruitName} painting?',
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
              vm.deleteArtwork(artwork.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();
    final artworks = vm.savedArtworks;

    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(title: const Text('My Masterpieces')),
      body: artworks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.sunshineYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🎨', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Artworks Saved Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pick any of our 50 fruit outlines and paint your very first masterpiece!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coralPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Switch tab or pop to gallery
                        DefaultTabController.of(context).animateTo(1);
                      },
                      icon: const Icon(Icons.palette_rounded),
                      label: const Text('Go to Gallery'),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.84,
              ),
              itemCount: artworks.length,
              itemBuilder: (context, index) {
                final artwork = artworks[index];
                final formattedDate = DateFormat('MMM d')
                    .format(artwork.lastEditedAt);

                return GestureDetector(
                  onTap: () {
                    SoundEffectService.playPop();
                    _showArtworkDetails(context, artwork, vm);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0x1825264A),
                        width: 1.5,
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
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.canvasPaper,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: File(artwork.imagePath).existsSync()
                                  ? Image.file(
                                      File(artwork.imagePath),
                                      fit: BoxFit.contain,
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artwork.fruitName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.coralPink.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.open_in_new_rounded,
                                  color: AppColors.coralPink,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
