import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/fruit_coloring_data.dart';
import '../models/coloring_page_model.dart';
import '../theme/app_theme.dart';
import '../utils/sound_effect_service.dart';
import '../viewmodels/coloring_viewmodel.dart';
import '../widgets/coloring_page_card.dart';
import 'coloring_screen.dart';
import 'gallery_screen.dart';
import 'my_artwork_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: IndexedStack(
        index: _currentTabIndex,
        children: const [
          _HomeDashboardView(),
          GalleryScreen(),
          MyArtworkScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepNavy.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  'Home',
                  AppColors.coralPink,
                ),
                _buildNavItem(
                  1,
                  Icons.palette_rounded,
                  'Gallery',
                  AppColors.tangerine,
                ),
                _buildNavItem(
                  2,
                  Icons.photo_library_rounded,
                  'Artwork',
                  AppColors.grapePurple,
                ),
                _buildNavItem(
                  3,
                  Icons.settings_rounded,
                  'Settings',
                  AppColors.skyBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
  ) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        SoundEffectService.playPop();
        setState(() => _currentTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The Main Dashboard Tab View
class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();
    final featuredFruit = FruitColoringData.getById('strawberry');
    final recentArtworks = vm.savedArtworks;

    return CustomScrollView(
      slivers: [
        // Playful App Header Bar
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.coralSunset,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coralPink.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🍓', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fruit Coloring Book',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        Text(
                          'Botanical Art • 13 Masterpieces',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coralPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sound Toggle Icon Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightGray,
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        vm.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: vm.soundEnabled
                            ? AppColors.coralPink
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => vm.toggleSound(!vm.soundEnabled),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Hero "Fruit of the Day" Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GestureDetector(
              onTap: () {
                SoundEffectService.playPop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ColoringScreen(page: featuredFruit),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.coralSunset,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coralPink.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '⭐ Fruit of the Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            featuredFruit.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            featuredFruit.funFact,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.brush_rounded,
                                  color: AppColors.coralPink,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Color Now',
                                  style: TextStyle(
                                    color: AppColors.coralPink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Large featured icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🍓', style: TextStyle(fontSize: 52)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Recent Colored Pictures Section (if any)
        if (recentArtworks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Masterpieces',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  Text(
                    '${recentArtworks.length} saved',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: recentArtworks.length,
                itemBuilder: (context, idx) {
                  final artwork = recentArtworks[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        SoundEffectService.playPop();
                        final page = FruitColoringData.getById(artwork.fruitId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ColoringScreen(page: page),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0x1825264A),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasPaper,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: File(artwork.imagePath).existsSync()
                                      ? Image.file(
                                          File(artwork.imagePath),
                                          fit: BoxFit.contain,
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.brush_rounded,
                                            size: 28,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                artwork.fruitName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Category Cards Section
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Fruit Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 104,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: FruitCategory.values.length,
              itemBuilder: (context, idx) {
                final cat = FruitCategory.values[idx];
                final count = FruitColoringData.getByCategory(cat).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      SoundEffectService.playPop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GalleryScreen(initialCategory: cat),
                        ),
                      );
                    },
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: cat.themeColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cat.themeColor.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cat.themeColor,
                            ),
                          ),
                          Text(
                            '$count items',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Featured Coloring Pages
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Popular Outlines to Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              // Pick diverse popular fruits
              final popularFruitIds = [
                'apple',
                'banana',
                'mango',
                'orange',
                'watermelon',
                'pineapple',
              ];
              final page = FruitColoringData.getById(
                popularFruitIds[index % popularFruitIds.length],
              );
              return ColoringPageCard(
                page: page,
                onTap: () {
                  SoundEffectService.playPop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ColoringScreen(page: page),
                    ),
                  );
                },
              );
            }, childCount: 6),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
