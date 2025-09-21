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
    try {
      final j = jsonDecode(await f.readAsString());
      final idx = LibraryIndex.fromJson(j);

      // recria capítulos garantindo lang válido
      idx.chapters = idx.chapters.map((c) {
        return ChapterMeta(
          id: c.id,
          label: c.label,
          number: c.number,
          title: c.title,
          pages: c.pages,
          lang: c.lang.isEmpty ? idx.meta.lang : c.lang,
          progress: c.progress,
          lastPage: c.lastPage,
        );
      }).toList();

      return idx;
    } catch (e) {
      print("Erro ao carregar índice $mangaId: $e");
      try {
        await f.rename('${f.path}.corrupted');
      } catch (_) {}
    }
  }
  return LibraryIndex(meta: seed ?? MangaMeta(id: mangaId, title: 'Sem título'));
}

Future<void> saveIndex(String mangaId, LibraryIndex idx) async {
  final f = await _fileFor(mangaId);
  await f.writeAsString(jsonEncode(idx.toJson()), flush: true);
}

/// Lista todos os índices (mangás salvos na biblioteca)
Future<List<LibraryIndex>> listIndexes() async {
  final dir = await appDir();
  final files = (await dir.list().toList())
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));

  final result = <LibraryIndex>[];
  for (final f in files) {
    try {
      final j = jsonDecode(await f.readAsString());
      final idx = LibraryIndex.fromJson(j);

      // recria capítulos garantindo lang válido
      idx.chapters = idx.chapters.map((c) {
        return ChapterMeta(
          id: c.id,
          label: c.label,
          number: c.number,
          title: c.title,
          pages: c.pages,
          lang: c.lang.isEmpty ? idx.meta.lang : c.lang,
          progress: c.progress,
          lastPage: c.lastPage,
        );
      }).toList();

      result.add(idx);
    } catch (e) {
      print("Erro ao ler ${f.path}: $e");
      continue;
    }
  }

  // Ordena por título 
  result.sort((a, b) => a.meta.title.compareTo(b.meta.title));
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
  final files = (await dir.list().toList())
      .whereType<File>()
      .where((f) =>
          f.path.toLowerCase().endsWith('.jpg') ||
          f.path.toLowerCase().endsWith('.png') ||
          f.path.toLowerCase().endsWith('.webp'))
      .toList();

  if (files.isEmpty) return null;

  files.sort((a, b) {
    final na = int.tryParse(RegExp(r'\d+').firstMatch(a.path)?.group(0) ?? '') ?? -1;
    final nb = int.tryParse(RegExp(r'\d+').firstMatch(b.path)?.group(0) ?? '') ?? -1;
    if (na == -1 || nb == -1) return a.path.compareTo(b.path);
    return na.compareTo(nb);
  });

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

/// Atualiza o meta de um mangá salvo
Future<void> updateMeta(String mangaId, MangaMeta meta) async {
  final idx = await loadIndex(mangaId, seed: meta);
  idx.meta = meta;
  await saveIndex(mangaId, idx);
}
