import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/artwork_model.dart';
import '../models/coloring_page_model.dart';

/// Repository managing local persistent storage for saved artworks and app settings
class ColoringRepository {
  static const String _artworksPrefKey = 'saved_artworks_json_list';
  static const String _prefSound = 'pref_sound_enabled';
  static const String _prefHaptics = 'pref_haptics_enabled';
  static const String _prefAutoSave = 'pref_auto_save_enabled';
  static const String _prefRecentColors = 'pref_recent_colors';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Load all saved artworks from local storage
  Future<List<SavedArtwork>> loadAllArtworks() async {
    final prefs = await _getPrefs();
    final rawList = prefs.getStringList(_artworksPrefKey) ?? [];
    final artworks = <SavedArtwork>[];

    for (final item in rawList) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        artworks.add(SavedArtwork.fromJson(map));
      } catch (e) {
        debugPrint('Error decoding artwork: $e');
      }
    }

    // Sort by lastEditedAt descending
    artworks.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
    return artworks;
  }

  /// Get the most recent saved session for a particular fruit ID
  Future<SavedArtwork?> getArtworkForFruit(String fruitId) async {
    final list = await loadAllArtworks();
    final matches = list.where((a) => a.fruitId == fruitId);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Saves the rendered canvas image to a PNG file and persists metadata
  Future<SavedArtwork> saveArtwork({
    required String? existingArtworkId,
    required ColoringPage page,
    required Map<String, Color> regionColors,
    required List<BrushStroke> strokes,
    required ui.Image renderedImage,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final artworkId =
        existingArtworkId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final imagesDir = Directory('${appDir.path}/colored_artworks');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final filePath = '${imagesDir.path}/artwork_$artworkId.png';

    // Encode ui.Image to PNG byte data
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData != null) {
      final buffer = byteData.buffer.asUint8List();
      final file = File(filePath);
      await file.writeAsBytes(buffer, flush: true);
    }

    // Convert region colors to ARGB int map
    final regionColorMap = <String, int>{};
    for (final entry in regionColors.entries) {
      regionColorMap[entry.key] = entry.value.toARGB32();
    }

    final totalRegions = page.regions.length;
    final coloredCount = regionColors.length;
    final completionPct = totalRegions > 0
        ? (coloredCount / totalRegions).clamp(0.0, 1.0)
        : 0.0;

    final artwork = SavedArtwork(
      id: artworkId,
      fruitId: page.id,
      fruitName: page.name,
      category: page.category,
      createdAt: DateTime.now(),
      lastEditedAt: DateTime.now(),
      imagePath: filePath,
      regionColors: regionColorMap,
      strokes: strokes,
      completionPercentage: completionPct,
      coloredRegionsCount: coloredCount,
    );

    // Persist into preferences
    final prefs = await _getPrefs();
    final list = await loadAllArtworks();
    list.removeWhere((item) => item.id == artworkId || item.fruitId == page.id);
    list.insert(0, artwork);

    final encodedList = list.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_artworksPrefKey, encodedList);

    return artwork;
  }

  /// Deletes an artwork and its preview file
  Future<bool> deleteArtwork(String artworkId) async {
    final prefs = await _getPrefs();
    final list = await loadAllArtworks();
    final index = list.indexWhere((a) => a.id == artworkId);
    if (index != -1) {
      final item = list[index];
      if (item.imagePath.isNotEmpty) {
        final file = File(item.imagePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      list.removeAt(index);
      final encodedList = list.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_artworksPrefKey, encodedList);
      return true;
    }
    return false;
  }

  /// Clears all saved artworks
  Future<void> clearAllArtworks() async {
    final prefs = await _getPrefs();
    final list = await loadAllArtworks();
    for (final item in list) {
      if (item.imagePath.isNotEmpty) {
        final f = File(item.imagePath);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    }
    await prefs.remove(_artworksPrefKey);
  }

  // --- Settings Persistence ---
  Future<bool> getSoundEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_prefSound) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_prefSound, value);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_prefHaptics) ?? true;
  }

  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_prefHaptics, value);
  }

  Future<bool> getAutoSaveEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_prefAutoSave) ?? true;
  }

  Future<void> setAutoSaveEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_prefAutoSave, value);
  }

  Future<List<int>> getRecentColors() async {
    final prefs = await _getPrefs();
    final list = prefs.getStringList(_prefRecentColors);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
  }

  Future<void> saveRecentColor(int colorValue) async {
    final prefs = await _getPrefs();
    final existing = await getRecentColors();
    existing.remove(colorValue);
    existing.insert(0, colorValue);
    if (existing.length > 8) {
      existing.removeLast();
    }
    await prefs.setStringList(
      _prefRecentColors,
      existing.map((e) => e.toString()).toList(),
    );
  }
}
