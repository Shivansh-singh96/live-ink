import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

enum ExportStatus { success, failure }

class ExportResult {
  final ExportStatus status;
  final String? filePath;
  final String? errorMessage;

  const ExportResult._({
    required this.status,
    this.filePath,
    this.errorMessage,
  });

  factory ExportResult.success(String filePath) =>
      ExportResult._(status: ExportStatus.success, filePath: filePath);

  factory ExportResult.failure(String message) =>
      ExportResult._(status: ExportStatus.failure, errorMessage: message);

  bool get isSuccess => status == ExportStatus.success;
}

class ExportService {
  /// Capture widget as PNG
  Future<Uint8List?> captureAsPng({
    required GlobalKey boundaryKey,
    double pixelRatio = 3.0,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image =
          await boundary.toImage(pixelRatio: pixelRatio);

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ExportService] captureAsPng failed: $e');
      return null;
    }
  }

  /// Save image to temporary storage
  Future<String?> saveToTempFile(Uint8List pngBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/liveink_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return filePath;
    } catch (e) {
      debugPrint('[ExportService] saveToTempFile failed: $e');
      return null;
    }
  }

  /// Save image to app documents
  Future<String?> saveToDocuments(Uint8List pngBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/liveink_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return filePath;
    } catch (e) {
      debugPrint('[ExportService] saveToDocuments failed: $e');
      return null;
    }
  }

  /// Share drawing
  Future<ExportResult> shareDrawing({
    required GlobalKey boundaryKey,
    double pixelRatio = 3.0,
  }) async {
    final pngBytes = await captureAsPng(
      boundaryKey: boundaryKey,
      pixelRatio: pixelRatio,
    );

    if (pngBytes == null) {
      return ExportResult.failure('Failed to capture canvas');
    }

    final filePath = await saveToTempFile(pngBytes);

    if (filePath == null) {
      return ExportResult.failure('Failed to save file');
    }

    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out my drawing made with LiveInk!',
      );

      return ExportResult.success(filePath);
    } catch (e) {
      return ExportResult.failure('Share failed: $e');
    }
  }

  /// Save drawing
  Future<ExportResult> saveDrawing({
    required GlobalKey boundaryKey,
    double pixelRatio = 3.0,
  }) async {
    final pngBytes = await captureAsPng(
      boundaryKey: boundaryKey,
      pixelRatio: pixelRatio,
    );

    if (pngBytes == null) {
      return ExportResult.failure('Failed to capture canvas');
    }

    final filePath = await saveToDocuments(pngBytes);

    if (filePath == null) {
      return ExportResult.failure('Failed to save file');
    }

    return ExportResult.success(filePath);
  }
}