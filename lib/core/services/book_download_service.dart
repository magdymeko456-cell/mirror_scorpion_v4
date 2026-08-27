import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class BookDownloadService {
  final Dio _dio = Dio();

  Future<void> downloadBookPackage({
    required String downloadUrl,
    required String packageKey,
    required Function(double progress) onProgress,
    required Function(bool success, String? path) onComplete,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/books/$packageKey.json';

      final file = File(savePath);
      await file.parent.create(recursive: true);

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total);
            onProgress(progress);
          }
        },
      );

      onComplete(true, savePath);
    } catch (e) {
      onComplete(false, null);
    }
  }
}
