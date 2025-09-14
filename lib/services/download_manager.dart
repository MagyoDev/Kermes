import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../api/manga_source.dart';
import '../models/models.dart';
import 'storage.dart';

class DownloadTask {
  final String mangaId;
  final MdChapter chapter;
  DownloadTask(this.mangaId, this.chapter);
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager instance = DownloadManager._internal();
  factory DownloadManager() => instance;
  DownloadManager._internal();

  late MangaSourceClient api;
  final List<DownloadTask> _queue = [];
  final List<ChapterMeta> completed = [];

  bool _running = false;
  double progress = 0.0;
  int done = 0;
  String status = 'Parado';
  bool convertWebp = false;

  void enqueue(Iterable<DownloadTask> tasks) {
    _queue.addAll(tasks);
    _run();
  }

  void _run() {
    if (_running) return;
    _running = true;
    _loop();
  }

  Future<void> _loop() async {
    try {
      while (_queue.isNotEmpty) {
        final task = _queue.removeAt(0);
        status = 'Baixando cap. ${task.chapter.chapter ?? task.chapter.id}';
        progress = 0;
        notifyListeners();

        final chap = await _downloadChapter(task);

        done++;
        completed.add(chap);
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 200));
      }
      status = 'Concluído';
    } catch (e) {
      status = 'Erro: $e';
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<ChapterMeta> _downloadChapter(DownloadTask t) async {
    final at = await api.atHomeServer(t.chapter.id);
    final dir = await chapterDir(t.mangaId, t.chapter.labelForFolder());
    final total = at.files.length;

    for (int i = 0; i < total; i++) {
      final filename = at.files[i];
      final url = Uri.parse('${at.baseUrl}/data/${at.hash}/$filename');
      final out = File(
        '${dir.path}/${(i + 1).toString().padLeft(3, '0')}${_ext(filename)}',
      );

      if (await out.exists()) {
        progress = (i + 1) / total;
        notifyListeners();
        continue;
      }

      final r = await http.get(url).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) {
        throw Exception('Erro ${r.statusCode} baixando $url');
      }

      var bytes = r.bodyBytes;
      if (convertWebp) {
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            bytes = img.encodeJpg(decoded, quality: 80);
          }
        } catch (_) {}
      }

      await out.writeAsBytes(bytes);
      progress = (i + 1) / total;
      notifyListeners();
    }

    // 🔹 Atualiza índice e meta completo
    final idx = await loadIndex(t.mangaId);

    // Se ainda não tiver metadados completos, busca no MangaDex
    if (idx.meta.title == 'Sem título' || idx.meta.author == null) {
      try {
        final fullMeta =
            await api.fetchMangaMeta(t.mangaId, lang: idx.meta.lang);
        idx.meta = fullMeta;
      } catch (_) {
        // fallback silencioso
      }
    }

    final chapters = List<ChapterMeta>.from(idx.chapters);
    final label = t.chapter.labelForFolder();

    final existing = chapters.indexWhere((c) => c.id == t.chapter.id);

    final record = ChapterMeta(
      id: t.chapter.id,
      label: label,
      number: t.chapter.chapter,
      title: t.chapter.title,
      pages: total,
    );

    if (existing >= 0) {
      chapters[existing] = record;
    } else {
      chapters.add(record);
    }

    // 🔹 mantém a ordem numérica
    chapters.sort((a, b) =>
        (double.tryParse(a.number ?? '') ?? 1e9)
            .compareTo(double.tryParse(b.number ?? '') ?? 1e9));

    idx.chapters = chapters;
    await saveIndex(t.mangaId, idx);

    return record;
  }

  String _ext(String name) {
    final n = name.toLowerCase();
    if (convertWebp) return '.jpg';
    if (n.endsWith('.png')) return '.png';
    if (n.endsWith('.webp')) return '.webp';
    return '.jpg';
  }
}
