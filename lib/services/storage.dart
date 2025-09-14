import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

Future<Directory> appDir() async {
  return await getApplicationDocumentsDirectory();
}

Future<File> _fileFor(String mangaId) async {
  final dir = await appDir();
  return File('${dir.path}/$mangaId.json');
}

Future<LibraryIndex> loadIndex(String mangaId, {MangaMeta? seed}) async {
  final f = await _fileFor(mangaId);
  if (await f.exists()) {
    final j = jsonDecode(await f.readAsString());
    return LibraryIndex.fromJson(j);
  }
  return LibraryIndex(meta: seed ?? MangaMeta(id: mangaId, title: 'Sem título'));
}

Future<void> saveIndex(String mangaId, LibraryIndex idx) async {
  final f = await _fileFor(mangaId);
  await f.writeAsString(jsonEncode(idx.toJson()));
}

Future<List<LibraryIndex>> loadAllIndexes() async {
  final dir = await appDir();
  final files =
      dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
  final result = <LibraryIndex>[];
  for (final f in files) {
    try {
      final j = jsonDecode(await f.readAsString());
      result.add(LibraryIndex.fromJson(j));
    } catch (_) {}
  }
  return result;
}

Future<Directory> chapterDir(String mangaId, String folder) async {
  final dir = await appDir();
  final path = Directory('${dir.path}/$mangaId/$folder');
  if (!await path.exists()) {
    await path.create(recursive: true);
  }
  return path;
}

Future<String?> firstLocalImagePath(String mangaId, String folder) async {
  final dir = await chapterDir(mangaId, folder);
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) =>
          f.path.toLowerCase().endsWith('.jpg') ||
          f.path.toLowerCase().endsWith('.png') ||
          f.path.toLowerCase().endsWith('.webp'))
      .toList();

  if (files.isEmpty) return null;
  files.sort((a, b) => a.path.compareTo(b.path));
  return files.first.path;
}

Future<void> deleteIndex(String mangaId) async {
  final f = await _fileFor(mangaId);
  if (await f.exists()) {
    await f.delete();
  }
  final dir = await appDir();
  final folder = Directory('${dir.path}/$mangaId');
  if (await folder.exists()) {
    await folder.delete(recursive: true);
  }
}

/// Atualiza o meta de um mangá salvo (garante que o título e infos fiquem corretos)
Future<void> updateMeta(String mangaId, MangaMeta meta) async {
  final idx = await loadIndex(mangaId, seed: meta);
  idx.meta = meta; // sobrescreve título, autor, idioma, etc.
  await saveIndex(mangaId, idx);
}
