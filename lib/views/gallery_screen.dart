import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coloring_page_model.dart';
import '../theme/app_theme.dart';
import '../utils/sound_effect_service.dart';
import '../viewmodels/coloring_viewmodel.dart';
import '../widgets/coloring_page_card.dart';
import 'coloring_screen.dart';

class GalleryScreen extends StatefulWidget {
  final FruitCategory? initialCategory;

  const GalleryScreen({super.key, this.initialCategory});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ColoringViewModel>().setCategoryFilter(
          widget.initialCategory,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ColoringViewModel>();
    final pages = vm.filteredPages;

    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(title: const Text('Fruit Gallery')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: vm.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search delicious fruits...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.coralPink,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            vm.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Category Chips Bar
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(
                  label: 'All (${vm.allPages.length})',
                  isSelected: vm.selectedCategory == null,
                  color: AppColors.coralPink,
                  onTap: () => vm.setCategoryFilter(null),
                ),
                ...FruitCategory.values.map((cat) {
                  final count = vm.allPages
                      .where((p) => p.category == cat)
                      .length;
                  return _buildCategoryChip(
                    label: '${cat.label} ${cat.emoji} ($count)',
                    isSelected: vm.selectedCategory == cat,
                    color: cat.themeColor,
                    onTap: () => vm.setCategoryFilter(cat),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Difficulty Chips Bar (Scrollable to prevent any screen width overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Difficulty:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDifficultyChip('All', null, vm),
                  const SizedBox(width: 6),
                  _buildDifficultyChip('Easy', 'Easy', vm),
                  const SizedBox(width: 6),
                  _buildDifficultyChip('Medium', 'Medium', vm),
                  const SizedBox(width: 6),
                  _buildDifficultyChip('Detailed', 'Detailed', vm),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Grid of Fruit Outline Cards
          Expanded(
            child: pages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text(
                          'No fruits match your search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coralPink,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            vm.setSearchQuery('');
                            vm.setCategoryFilter(null);
                            vm.setDifficultyFilter(null);
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.deepNavy,
          ),
        ),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: AppColors.pureWhite,
        side: BorderSide(
          color: isSelected ? color : const Color(0x1825264A),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildDifficultyChip(
    String label,
    String? value,
    ColoringViewModel vm,
  ) {
    final isSelected = vm.selectedDifficulty == value;
    return GestureDetector(
      onTap: () => vm.setDifficultyFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.deepNavy : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
