import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// مساحة دائمة لحزم المحتوى التي يختار المستخدم تنزيلها أو استيرادها.
/// لا تقوم هذه الخدمة بتنزيل أي شيء في الخلفية، ولا تُخزّن محتوى دينياً
/// أو صوتياً من دون إجراء صريح من المستخدم.
class OfflineContentStorage {
  const OfflineContentStorage();

  Future<Directory> packagesDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/mirror_scorpion/content_packs');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<List<OfflinePackageRecord>> listPackages() async {
    final directory = await packagesDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    final records = <OfflinePackageRecord>[];
    for (final file in files) {
      try {
        final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        records.add(OfflinePackageRecord.fromJson(map, path: file.path));
      } on FormatException {
        // ملف غير متوافق لا يُعرض كحزمة صالحة.
      }
    }
    return records;
  }

  Future<File> savePackage({
    required String id,
    required Map<String, dynamic> content,
  }) async {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Package ID must be lowercase letters, digits, and hyphens only.');
    }
    final directory = await packagesDirectory();
    final file = File('${directory.path}/$id.json');
    await file.writeAsString(jsonEncode(content));
    return file;
  }
}

class OfflinePackageRecord {
  const OfflinePackageRecord({
    required this.id,
    required this.title,
    required this.path,
  });

  final String id;
  final String title;
  final String path;

  factory OfflinePackageRecord.fromJson(Map<String, dynamic> json, {required String path}) {
    return OfflinePackageRecord(
      id: json['packageId'] as String? ?? json['id'] as String? ?? 'unknown',
      title: json['title'] as String? ?? json['packageId'] as String? ?? 'حزمة محتوى',
      path: path,
    );
  }
}
