import 'dart:io';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../api/manga_source.dart';
import '../api/mangadex_client.dart'; // 🔹 fallback
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

  MangaSourceClient? api;
  final Queue<DownloadTask> _queue = Queue();
  final List<ChapterMeta> completed = [];

  bool running = false; // 🔹 público para UI
  double progress = 0.0;
  int done = 0;
  String status = 'Parado';
  bool convertWebp = false;

  /// Adiciona novas tarefas à fila
  void enqueue(Iterable<DownloadTask> tasks) {
    _queue.addAll(tasks);
    _run();
  }

  void _run() {
    if (running) return;
    running = true;
    _loop();
  }

  Future<void> _loop() async {
    try {
      while (_queue.isNotEmpty) {
        final task = _queue.removeFirst();
        status = 'Baixando cap. ${task.chapter.chapter ?? task.chapter.id}';
        progress = 0;
        notifyListeners();

        try {
          final chap = await _downloadChapter(task);
          done++;
          completed.add(chap);
          status = 'Cap. ${task.chapter.chapter ?? task.chapter.id} concluído';
        } catch (e, st) {
          status = '❌ Erro no capítulo ${task.chapter.id}: $e';
          debugPrintStack(label: 'DownloadManager erro', stackTrace: st);
        }

        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      status = '✅ Todos concluídos';
    } finally {
      running = false;
      notifyListeners();
    }
  }

  Future<ChapterMeta> _downloadChapter(DownloadTask t) async {
    final client = api ??= MangaDexClient();

    final at = await client.atHomeServer(t.chapter.id);
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

      debugPrint("📥 Baixando: $url");

      final r = await http.get(url).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) {
        throw Exception('Erro ${r.statusCode} baixando $url');
      }

      var bytes = r.bodyBytes;
      if (convertWebp && filename.toLowerCase().endsWith('.webp')) {
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            bytes = img.encodeJpg(decoded, quality: 80);
          }
        } catch (e) {
          debugPrint("⚠️ Erro convertendo webp: $e");
        }
      }

      await out.writeAsBytes(bytes);
      progress = (i + 1) / total;
      notifyListeners();
    }

    // 🔹 Atualiza índice
    final idx = await loadIndex(t.mangaId);

    if (idx.meta.title == 'Sem título' || idx.meta.author == null) {
      try {
        final fullMeta =
            await client.fetchMangaMeta(t.mangaId, lang: idx.meta.lang);
        idx.meta = fullMeta;
      } catch (e) {
        debugPrint("⚠️ Falha ao atualizar meta: $e");
      }
    }

    final record = ChapterMeta(
      id: t.chapter.id,
      label: t.chapter.labelForFolder(),
      number: t.chapter.chapter,
      title: t.chapter.title,
      pages: total,
      lang: t.chapter.lang,
    );

    final existing = idx.chapters.indexWhere((c) => c.id == t.chapter.id);
    if (existing >= 0) {
      idx.chapters[existing] = record;
    } else {
      idx.chapters.add(record);
    }

    idx.chapters.sort((a, b) =>
        (double.tryParse(a.number ?? '') ?? 1e9)
            .compareTo(double.tryParse(b.number ?? '') ?? 1e9));

    await saveIndex(t.mangaId, idx);
    return record;
  }

  String _ext(String name) {
    final n = name.toLowerCase();
    if (convertWebp && n.endsWith('.webp')) return '.jpg';
    if (n.endsWith('.png')) return '.png';
    if (n.endsWith('.webp')) return '.webp';
    return '.jpg';
  }
}
