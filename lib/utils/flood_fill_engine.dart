import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Represents an undoable flood fill operation
class FloodFillStep {
  final List<int> pixelIndices;
  final int previousColor;
  final int newColor;

  FloodFillStep({
    required this.pixelIndices,
    required this.previousColor,
    required this.newColor,
  });
}

/// High-performance, pixel-perfect Flood Fill Controller for botanical line art.
class FloodFillController extends ChangeNotifier {
  ui.Image? lineArtImage;
  ui.Image? fillImage;

  Uint32List? _linePixels;
  Uint32List? _fillPixels;
  int _width = 0;
  int _height = 0;
  bool _isLoading = false;
  String? _currentAsset;

  final List<FloodFillStep> _undoStack = [];
  final List<FloodFillStep> _redoStack = [];

  bool get isLoading => _isLoading;
  bool get hasImage => lineArtImage != null && fillImage != null;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get width => _width;
  int get height => _height;
  String? get currentAsset => _currentAsset;

  /// Loads and prepares a coloring image for pixel-perfect flood filling.
  Future<void> loadAsset(String assetPath) async {
    if (_currentAsset == assetPath && hasImage) return;

    _isLoading = true;
    _currentAsset = assetPath;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      lineArtImage = image;
      _width = image.width;
      _height = image.height;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData != null) {
        _linePixels = byteData.buffer.asUint32List();
        // Initialize fill layer with pure white (0xFFFFFFFF)
        _fillPixels = Uint32List(_width * _height);
        _fillPixels!.fillRange(0, _fillPixels!.length, 0xFFFFFFFF);
        _computeOuterBackgroundMask();
        await _refreshFillImage();
      }
    } catch (e) {
      debugPrint('Error loading flood fill asset $assetPath: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Uint8List? _outerBackgroundMask;

  /// Determines if a pixel index belongs to the outer background canvas paper.
  bool isOuterBackground(int idx) {
    if (_outerBackgroundMask == null || idx < 0 || idx >= _outerBackgroundMask!.length) {
      return false;
    }
    return _outerBackgroundMask![idx] == 1;
  }

  /// Floods inward from the image perimeter to map out the entire outer background.
  void _computeOuterBackgroundMask() {
    if (_linePixels == null || _width == 0 || _height == 0) return;
    final int total = _width * _height;
    _outerBackgroundMask = Uint8List(total);

    final Int32List queue = Int32List(total);
    int head = 0;
    int tail = 0;

    final int w = _width;
    final int h = _height;

    void enqueueIfFree(int x, int y) {
      final int idx = y * w + x;
      if (_outerBackgroundMask![idx] == 0 && !_isBoundary(idx)) {
        _outerBackgroundMask![idx] = 1;
        queue[tail++] = idx;
      }
    }

    // Top and Bottom perimeter
    for (int x = 0; x < w; x++) {
      enqueueIfFree(x, 0);
      enqueueIfFree(x, h - 1);
    }

    // Left and Right perimeter
    for (int y = 0; y < h; y++) {
      enqueueIfFree(0, y);
      enqueueIfFree(w - 1, y);
    }

    // BFS flood from outer perimeter inward until hitting dark boundaries
    while (head < tail) {
      final int curr = queue[head++];
      final int cx = curr % w;
      final int cy = curr ~/ w;

      // West
      if (cx > 0) {
        final int next = curr - 1;
        if (_outerBackgroundMask![next] == 0 && !_isBoundary(next)) {
          _outerBackgroundMask![next] = 1;
          queue[tail++] = next;
        }
      }
      // East
      if (cx < w - 1) {
        final int next = curr + 1;
        if (_outerBackgroundMask![next] == 0 && !_isBoundary(next)) {
          _outerBackgroundMask![next] = 1;
          queue[tail++] = next;
        }
      }
      // North
      if (cy > 0) {
        final int next = curr - w;
        if (_outerBackgroundMask![next] == 0 && !_isBoundary(next)) {
          _outerBackgroundMask![next] = 1;
          queue[tail++] = next;
        }
      }
      // South
      if (cy < h - 1) {
        final int next = curr + w;
        if (_outerBackgroundMask![next] == 0 && !_isBoundary(next)) {
          _outerBackgroundMask![next] = 1;
          queue[tail++] = next;
        }
      }
    }
  }

  /// Determines if a pixel index is part of the dark boundary line art.
  bool _isBoundary(int idx) {
    if (_linePixels == null || idx < 0 || idx >= _linePixels!.length) {
      return true;
    }
    final int pixel = _linePixels![idx];
    // In rawRgba (little-endian): Byte0=R, Byte1=G, Byte2=B
    final int r = pixel & 0xFF;
    final int g = (pixel >> 8) & 0xFF;
    final int b = (pixel >> 16) & 0xFF;
    // Luminance threshold for outline boundary
    final int lum = (r * 299 + g * 587 + b * 114) ~/ 1000;
    return lum < 135;
  }

  /// Converts a Flutter Color to a 32-bit integer in little-endian rawRgba format.
  static int colorToRgba32(Color color) {
    final int r = (color.r * 255).round().clamp(0, 255);
    final int g = (color.g * 255).round().clamp(0, 255);
    final int b = (color.b * 255).round().clamp(0, 255);
    final int a = (color.a * 255).round().clamp(0, 255);
    return (a << 24) | (b << 16) | (g << 8) | r;
  }

  /// Performs an ultra-fast Queue-based Scanline Flood Fill at the normalized canvas offset.
  Future<bool> fillAtNormalized(Offset normalizedOffset, Color color) async {
    if (_fillPixels == null || _width == 0 || _height == 0) return false;

    final int startX = (normalizedOffset.dx * _width).toInt().clamp(0, _width - 1);
    final int startY = (normalizedOffset.dy * _height).toInt().clamp(0, _height - 1);
    final int startIdx = startY * _width + startX;

    // Do not fill if user tapped directly on a dark outline or on the outer background
    if (_isBoundary(startIdx) || isOuterBackground(startIdx)) return false;

    final int targetColor = _fillPixels![startIdx];
    final int newColor = colorToRgba32(color);

    if (targetColor == newColor) return false;

    // Fast integer queue for BFS
    final int totalPixels = _width * _height;
    final Int32List queue = Int32List(totalPixels);
    int head = 0;
    int tail = 0;

    queue[tail++] = startIdx;
    _fillPixels![startIdx] = newColor;
    final List<int> changedIndices = [startIdx];

    final int w = _width;
    final int h = _height;

    while (head < tail) {
      final int curr = queue[head++];
      final int cx = curr % w;
      final int cy = curr ~/ w;

      // Check West (Left)
      if (cx > 0) {
        final int next = curr - 1;
        if (!_isBoundary(next) && !isOuterBackground(next) && _fillPixels![next] == targetColor) {
          _fillPixels![next] = newColor;
          changedIndices.add(next);
          queue[tail++] = next;
        }
      }

      // Check East (Right)
      if (cx < w - 1) {
        final int next = curr + 1;
        if (!_isBoundary(next) && !isOuterBackground(next) && _fillPixels![next] == targetColor) {
          _fillPixels![next] = newColor;
          changedIndices.add(next);
          queue[tail++] = next;
        }
      }

      // Check North (Up)
      if (cy > 0) {
        final int next = curr - w;
        if (!_isBoundary(next) && !isOuterBackground(next) && _fillPixels![next] == targetColor) {
          _fillPixels![next] = newColor;
          changedIndices.add(next);
          queue[tail++] = next;
        }
      }

      // Check South (Down)
      if (cy < h - 1) {
        final int next = curr + w;
        if (!_isBoundary(next) && !isOuterBackground(next) && _fillPixels![next] == targetColor) {
          _fillPixels![next] = newColor;
          changedIndices.add(next);
          queue[tail++] = next;
        }
      }
    }

    if (changedIndices.isNotEmpty) {
      _undoStack.add(
        FloodFillStep(
          pixelIndices: changedIndices,
          previousColor: targetColor,
          newColor: newColor,
        ),
      );
      _redoStack.clear();
      await _refreshFillImage();
      return true;
    }

    return false;
  }

  /// Erases a filled region by flood-filling with pure white (0xFFFFFFFF).
  Future<bool> eraseAtNormalized(Offset normalizedOffset) async {
    return fillAtNormalized(normalizedOffset, const Color(0xFFFFFFFF));
  }

  /// Reverts the last flood fill step.
  Future<void> undo() async {
    if (!canUndo || _fillPixels == null) return;
    final step = _undoStack.removeLast();
    for (final idx in step.pixelIndices) {
      _fillPixels![idx] = step.previousColor;
    }
    _redoStack.add(step);
    await _refreshFillImage();
  }

  /// Redoes the undone flood fill step.
  Future<void> redo() async {
    if (!canRedo || _fillPixels == null) return;
    final step = _redoStack.removeLast();
    for (final idx in step.pixelIndices) {
      _fillPixels![idx] = step.newColor;
    }
    _undoStack.add(step);
    await _refreshFillImage();
  }

  /// Clears all fills back to pure white paper.
  Future<void> resetAll() async {
    if (_fillPixels == null) return;
    _fillPixels!.fillRange(0, _fillPixels!.length, 0xFFFFFFFF);
    _undoStack.clear();
    _redoStack.clear();
    await _refreshFillImage();
  }

  /// Converts the raw Uint32List buffer into a hardware-accelerated ui.Image for rendering.
  Future<void> _refreshFillImage() async {
    if (_fillPixels == null || _width == 0 || _height == 0) return;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.view(_fillPixels!.buffer),
      _width,
      _height,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );
    fillImage = await completer.future;
    notifyListeners();
  }
}
