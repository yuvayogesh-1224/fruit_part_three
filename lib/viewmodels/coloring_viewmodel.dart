import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/fruit_coloring_data.dart';
import '../models/artwork_model.dart';
import '../models/coloring_page_model.dart';
import '../repositories/coloring_repository.dart';
import '../theme/app_theme.dart';
import '../utils/flood_fill_engine.dart';
import '../utils/sound_effect_service.dart';

enum ColoringTool {
  bucketFill('Fill Bucket', Icons.format_color_fill_rounded),
  brush('Paint Brush', Icons.brush_rounded),
  eraser('Eraser', Icons.auto_fix_normal_rounded);

  final String label;
  final IconData icon;
  const ColoringTool(this.label, this.icon);
}

/// Base abstract class for Canvas Undo/Redo actions
abstract class CanvasAction {
  void undo(ColoringViewModel vm);
  void redo(ColoringViewModel vm);
}

class FillAction extends CanvasAction {
  final String regionId;
  final Color? previousColor;
  final Color newColor;

  FillAction({
    required this.regionId,
    required this.previousColor,
    required this.newColor,
  });

  @override
  void undo(ColoringViewModel vm) {
    if (previousColor == null) {
      vm._regionFills.remove(regionId);
    } else {
      vm._regionFills[regionId] = previousColor!;
    }
  }

  @override
  void redo(ColoringViewModel vm) {
    vm._regionFills[regionId] = newColor;
  }
}

class EraseRegionAction extends CanvasAction {
  final String regionId;
  final Color previousColor;

  EraseRegionAction({
    required this.regionId,
    required this.previousColor,
  });

  @override
  void undo(ColoringViewModel vm) {
    vm._regionFills[regionId] = previousColor;
  }

  @override
  void redo(ColoringViewModel vm) {
    vm._regionFills.remove(regionId);
  }
}

class StrokeAction extends CanvasAction {
  final BrushStroke stroke;

  StrokeAction(this.stroke);

  @override
  void undo(ColoringViewModel vm) {
    vm._brushStrokes.remove(stroke);
  }

  @override
  void redo(ColoringViewModel vm) {
    vm._brushStrokes.add(stroke);
  }
}

class ClearCanvasAction extends CanvasAction {
  final Map<String, Color> previousFills;
  final List<BrushStroke> previousStrokes;

  ClearCanvasAction({
    required this.previousFills,
    required this.previousStrokes,
  });

  @override
  void undo(ColoringViewModel vm) {
    vm._regionFills.clear();
    vm._regionFills.addAll(previousFills);
    vm._brushStrokes.clear();
    vm._brushStrokes.addAll(previousStrokes);
  }

  @override
  void redo(ColoringViewModel vm) {
    vm._regionFills.clear();
    vm._brushStrokes.clear();
  }
}

/// Central ViewModel managing the coloring canvas, undo/redo, gallery filters, and artwork persistence
class ColoringViewModel extends ChangeNotifier {
  final ColoringRepository _repository;
  final FloodFillController floodFillController = FloodFillController();

  ColoringViewModel({ColoringRepository? repository})
    : _repository = repository ?? ColoringRepository() {
    floodFillController.addListener(notifyListeners);
    _init();
  }

  // --- Session State ---
  ColoringPage? _currentPage;
  String? _currentArtworkId;
  Color _selectedColor = AppColors.coralPink;
  ColoringTool _currentTool = ColoringTool.bucketFill;
  double _brushSize = 12.0;
  bool _isPanZoomLocked =
      true; // When true, touch draws/fills; when false, pans/zooms

  final Map<String, Color> _regionFills = {};
  final List<BrushStroke> _brushStrokes = [];
  BrushStroke? _activeStroke;

  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];

  // Saving / Celebratory State
  bool _isSaving = false;
  bool _isCelebrating = false;

  // --- Gallery & Navigation State ---
  List<ColoringPage> _allPages = [];
  String _searchQuery = '';
  FruitCategory? _selectedCategory;
  String? _selectedDifficulty;

  // --- Saved Artworks State ---
  List<SavedArtwork> _savedArtworks = [];
  bool _isLoadingArtworks = false;

  // --- Settings State ---
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _autoSaveEnabled = true;
  List<Color> _recentColors = [];

  // --- Getters ---
  ColoringPage? get currentPage => _currentPage;
  String? get currentArtworkId => _currentArtworkId;
  Color get selectedColor => _selectedColor;
  ColoringTool get currentTool => _currentTool;
  double get brushSize => _brushSize;
  bool get isPanZoomLocked => _isPanZoomLocked;
  Map<String, Color> get regionFills => Map.unmodifiable(_regionFills);
  List<BrushStroke> get brushStrokes => List.unmodifiable(_brushStrokes);
  BrushStroke? get activeStroke => _activeStroke;
  bool get canUndo =>
      (_currentPage?.imageAsset != null && floodFillController.canUndo) ||
      _undoStack.isNotEmpty;
  bool get canRedo =>
      (_currentPage?.imageAsset != null && floodFillController.canRedo) ||
      _redoStack.isNotEmpty;
  bool get isSaving => _isSaving;
  bool get isCelebrating => _isCelebrating;

  List<ColoringPage> get allPages => _allPages;
  String get searchQuery => _searchQuery;
  FruitCategory? get selectedCategory => _selectedCategory;
  String? get selectedDifficulty => _selectedDifficulty;
  List<SavedArtwork> get savedArtworks => _savedArtworks;
  bool get isLoadingArtworks => _isLoadingArtworks;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get autoSaveEnabled => _autoSaveEnabled;
  List<Color> get recentColors => _recentColors;

  // Completion calculation
  double get currentCompletionPercentage {
    if (_currentPage == null || _currentPage!.regions.isEmpty) return 0.0;
    return (_regionFills.length / _currentPage!.regions.length).clamp(0.0, 1.0);
  }

  // Filtered pages for gallery
  List<ColoringPage> get filteredPages {
    return _allPages.where((page) {
      if (_selectedCategory != null && page.category != _selectedCategory) {
        return false;
      }
      if (_selectedDifficulty != null &&
          page.difficulty != _selectedDifficulty) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchesName = page.name.toLowerCase().contains(query);
        final matchesId = page.id.toLowerCase().contains(query);
        final matchesCat = page.category.label.toLowerCase().contains(query);
        if (!matchesName && !matchesId && !matchesCat) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _init() async {
    _allPages = FruitColoringData.allPages;
    _soundEnabled = await _repository.getSoundEnabled();
    _hapticsEnabled = await _repository.getHapticsEnabled();
    _autoSaveEnabled = await _repository.getAutoSaveEnabled();
    SoundEffectService.soundEnabled = _soundEnabled;
    SoundEffectService.hapticsEnabled = _hapticsEnabled;

    final recentInts = await _repository.getRecentColors();
    _recentColors = recentInts.map((i) => Color(i)).toList();

    await loadSavedArtworks();
    notifyListeners();
  }

  // --- Session Setup ---
  Future<void> startColoringPage(ColoringPage page) async {
    _currentPage = page;
    _regionFills.clear();
    _brushStrokes.clear();
    _activeStroke = null;
    _undoStack.clear();
    _redoStack.clear();
    _isCelebrating = false;

    if (page.imageAsset != null) {
      await floodFillController.loadAsset(page.imageAsset!);
    }

    // Check if there is an existing saved artwork for this fruit
    final existing = await _repository.getArtworkForFruit(page.id);
    if (existing != null) {
      _currentArtworkId = existing.id;
      for (final entry in existing.regionColors.entries) {
        _regionFills[entry.key] = Color(entry.value);
      }
      _brushStrokes.addAll(existing.strokes);
    } else {
      _currentArtworkId = null;
    }

    if (page.suggestedColors.isNotEmpty) {
      _selectedColor = page.suggestedColors.first;
    } else {
      _selectedColor = AppColors.coralPink;
    }

    notifyListeners();
  }

  // --- Tool & Color Selection ---
  void selectColor(Color color) {
    _selectedColor = color;
    SoundEffectService.playPop();

    // Add to recent colors
    if (!_recentColors.contains(color)) {
      _recentColors.insert(0, color);
      if (_recentColors.length > 8) {
        _recentColors.removeLast();
      }
      _repository.saveRecentColor(color.toARGB32());
    }
    notifyListeners();
  }

  void selectTool(ColoringTool tool) {
    _currentTool = tool;
    SoundEffectService.playPop();
    notifyListeners();
  }

  void setBrushSize(double size) {
    _brushSize = size;
    SoundEffectService.playTick();
    notifyListeners();
  }

  void togglePanZoomLock() {
    _isPanZoomLocked = !_isPanZoomLocked;
    SoundEffectService.playPop();
    notifyListeners();
  }

  // --- Coloring Operations ---
  Future<void> fillRegionAt(Offset point, Size canvasSize) async {
    if (_currentPage == null) return;

    if (_currentPage!.imageAsset != null) {
      final normOffset = Offset(
        (point.dx / canvasSize.width).clamp(0.0, 1.0),
        (point.dy / canvasSize.height).clamp(0.0, 1.0),
      );
      final filled = await floodFillController.fillAtNormalized(
        normOffset,
        _selectedColor,
      );
      if (filled) {
        SoundEffectService.playPop();
        notifyListeners();
      }
      return;
    }

    final region = _currentPage!.hitTest(point, canvasSize);
    if (region != null) {
      final previous = _regionFills[region.id];
      if (previous == _selectedColor) return; // Same color already

      _regionFills[region.id] = _selectedColor;
      _undoStack.add(
        FillAction(
          regionId: region.id,
          previousColor: previous,
          newColor: _selectedColor,
        ),
      );
      _redoStack.clear();
      SoundEffectService.playPop();

      // Check if newly completed
      if (currentCompletionPercentage >= 1.0) {
        _isCelebrating = true;
        SoundEffectService.playCelebrate();
      }

      notifyListeners();
    }
  }

  Future<void> eraseRegionAt(Offset point, Size canvasSize) async {
    if (_currentPage == null) return;

    if (_currentPage!.imageAsset != null) {
      final normOffset = Offset(
        (point.dx / canvasSize.width).clamp(0.0, 1.0),
        (point.dy / canvasSize.height).clamp(0.0, 1.0),
      );
      final erased = await floodFillController.eraseAtNormalized(normOffset);
      if (erased) {
        SoundEffectService.playPop();
        notifyListeners();
      }
      return;
    }

    final region = _currentPage!.hitTest(point, canvasSize);
    if (region != null && _regionFills.containsKey(region.id)) {
      final prev = _regionFills.remove(region.id)!;
      _undoStack.add(
        EraseRegionAction(
          regionId: region.id,
          previousColor: prev,
        ),
      );
      _redoStack.clear();
      SoundEffectService.playPop();
      notifyListeners();
    }
  }

  // Brush drawing (coordinates normalized to 0..400)
  void startStroke(Offset point, Size canvasSize) {
    final normX = (point.dx / canvasSize.width) * 400.0;
    final normY = (point.dy / canvasSize.height) * 400.0;

    _activeStroke = BrushStroke(
      points: [Offset(normX, normY)],
      colorValue: _selectedColor.toARGB32(),
      strokeWidth: _brushSize,
      isEraser: _currentTool == ColoringTool.eraser,
    );
    notifyListeners();
  }

  void updateStroke(Offset point, Size canvasSize) {
    if (_activeStroke == null) return;
    final normX = (point.dx / canvasSize.width) * 400.0;
    final normY = (point.dy / canvasSize.height) * 400.0;

    _activeStroke!.points.add(Offset(normX, normY));
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke != null && _activeStroke!.points.isNotEmpty) {
      _brushStrokes.add(_activeStroke!);
      _undoStack.add(StrokeAction(_activeStroke!));
      _redoStack.clear();
      _activeStroke = null;
      notifyListeners();
    }
  }

  // --- Undo / Redo ---
  Future<void> undo() async {
    if (_currentPage?.imageAsset != null && floodFillController.canUndo) {
      await floodFillController.undo();
      SoundEffectService.playPop();
      notifyListeners();
      return;
    }

    if (!canUndo) return;
    final action = _undoStack.removeLast();
    action.undo(this);
    _redoStack.add(action);
    SoundEffectService.playPop();
    notifyListeners();
  }

  Future<void> redo() async {
    if (_currentPage?.imageAsset != null && floodFillController.canRedo) {
      await floodFillController.redo();
      SoundEffectService.playPop();
      notifyListeners();
      return;
    }

    if (!canRedo) return;
    final action = _redoStack.removeLast();
    action.redo(this);
    _undoStack.add(action);
    SoundEffectService.playPop();
    notifyListeners();
  }

  Future<void> resetCanvas() async {
    if (_currentPage?.imageAsset != null) {
      await floodFillController.resetAll();
      _brushStrokes.clear();
      SoundEffectService.playPop();
      notifyListeners();
      return;
    }

    if (_regionFills.isEmpty && _brushStrokes.isEmpty) return;
    _undoStack.add(
      ClearCanvasAction(
        previousFills: Map.from(_regionFills),
        previousStrokes: List.from(_brushStrokes),
      ),
    );
    _redoStack.clear();
    _regionFills.clear();
    _brushStrokes.clear();
    SoundEffectService.playPop();
    notifyListeners();
  }

  // --- Save Artwork ---
  Future<SavedArtwork?> saveCurrentArtwork() async {
    if (_currentPage == null) return null;
    _isSaving = true;
    notifyListeners();

    try {
      final renderedImage = await renderCanvasImage(targetSize: 800);
      final saved = await _repository.saveArtwork(
        existingArtworkId: _currentArtworkId,
        page: _currentPage!,
        regionColors: _regionFills,
        strokes: _brushStrokes,
        renderedImage: renderedImage,
      );

      _currentArtworkId = saved.id;
      await loadSavedArtworks();
      _isSaving = false;
      _isCelebrating = true;
      SoundEffectService.playCelebrate();
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('Error saving artwork: $e');
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  void dismissCelebration() {
    _isCelebrating = false;
    notifyListeners();
  }

  /// Renders a high-resolution export image of the current drawing
  Future<ui.Image> renderCanvasImage({double targetSize = 800}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetSize, targetSize),
    );
    final size = Size(targetSize, targetSize);
    final scale = targetSize / 400.0;

    // 1. Crisp white canvas paper background
    final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, targetSize, targetSize), bgPaint);

    if (_currentPage != null) {
      if (_currentPage!.imageAsset != null && floodFillController.hasImage) {
        if (floodFillController.fillImage != null) {
          canvas.drawImageRect(
            floodFillController.fillImage!,
            Rect.fromLTWH(
              0,
              0,
              floodFillController.width.toDouble(),
              floodFillController.height.toDouble(),
            ),
            Rect.fromLTWH(0, 0, targetSize, targetSize),
            Paint()..filterQuality = FilterQuality.high,
          );
        }
      } else {
        // 2. Filled vector regions (sorted by zIndex)
        final sorted = List<ColorRegion>.from(_currentPage!.regions)
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        for (final region in sorted) {
          final color = _regionFills[region.id];
          if (color != null) {
            final paint = Paint()
              ..color = color
              ..style = PaintingStyle.fill;
            canvas.drawPath(region.pathBuilder(size), paint);
          }
        }
      }

      // 3. Brush Strokes
      if (_brushStrokes.isNotEmpty) {
        canvas.saveLayer(Rect.fromLTWH(0, 0, targetSize, targetSize), Paint());

        void drawExportStroke(BrushStroke stroke, {required bool isEraserPass}) {
          if (stroke.points.isEmpty) return;
          if (stroke.isEraser != isEraserPass) return;

          final strokePaint = Paint()
            ..strokeWidth = stroke.strokeWidth * scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

          if (isEraserPass) {
            strokePaint.blendMode = BlendMode.clear;
          } else {
            strokePaint.color = stroke.color;
          }

          final path = Path();
          path.moveTo(
            stroke.points.first.dx * scale,
            stroke.points.first.dy * scale,
          );
          for (int i = 1; i < stroke.points.length; i++) {
            path.lineTo(stroke.points[i].dx * scale, stroke.points[i].dy * scale);
          }
          canvas.drawPath(path, strokePaint);
        }

        for (final stroke in _brushStrokes) {
          drawExportStroke(stroke, isEraserPass: false);
        }
        for (final stroke in _brushStrokes) {
          drawExportStroke(stroke, isEraserPass: true);
        }

        canvas.restore();
      }

      // 4. Master outline layer
      if (_currentPage!.imageAsset != null && floodFillController.hasImage) {
        if (floodFillController.lineArtImage != null) {
          canvas.drawImageRect(
            floodFillController.lineArtImage!,
            Rect.fromLTWH(
              0,
              0,
              floodFillController.width.toDouble(),
              floodFillController.height.toDouble(),
            ),
            Rect.fromLTWH(0, 0, targetSize, targetSize),
            Paint()
              ..blendMode = ui.BlendMode.multiply
              ..filterQuality = FilterQuality.high,
          );
        }
      } else {
        final outlinePaint = Paint()
          ..color = const Color(0xFF1E1F3B)
          ..strokeWidth = 4.0 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        _currentPage!.drawOutlines(canvas, size, outlinePaint);
      }
    }

    final picture = recorder.endRecording();
    return await picture.toImage(targetSize.toInt(), targetSize.toInt());
  }

  // --- Artwork Storage Operations ---
  Future<void> loadSavedArtworks() async {
    _isLoadingArtworks = true;
    notifyListeners();
    _savedArtworks = await _repository.loadAllArtworks();
    _isLoadingArtworks = false;
    notifyListeners();
  }

  Future<void> deleteArtwork(String artworkId) async {
    await _repository.deleteArtwork(artworkId);
    if (_currentArtworkId == artworkId) {
      _currentArtworkId = null;
    }
    await loadSavedArtworks();
  }

  Future<void> clearAllArtworks() async {
    await _repository.clearAllArtworks();
    _currentArtworkId = null;
    _regionFills.clear();
    _brushStrokes.clear();
    await loadSavedArtworks();
  }

  // --- Gallery Filters ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(FruitCategory? category) {
    _selectedCategory = category;
    SoundEffectService.playPop();
    notifyListeners();
  }

  void setDifficultyFilter(String? difficulty) {
    _selectedDifficulty = difficulty;
    SoundEffectService.playPop();
    notifyListeners();
  }

  // --- Settings Toggles ---
  void toggleSound(bool value) {
    _soundEnabled = value;
    SoundEffectService.soundEnabled = value;
    _repository.setSoundEnabled(value);
    if (value) SoundEffectService.playPop();
    notifyListeners();
  }

  void toggleHaptics(bool value) {
    _hapticsEnabled = value;
    SoundEffectService.hapticsEnabled = value;
    _repository.setHapticsEnabled(value);
    if (value) SoundEffectService.playTick();
    notifyListeners();
  }

  void toggleAutoSave(bool value) {
    _autoSaveEnabled = value;
    _repository.setAutoSaveEnabled(value);
    SoundEffectService.playPop();
    notifyListeners();
  }
}
