import 'dart:io';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart'; // 👈 add essa lib no pubspec.yaml
import '../models/models.dart';
import '../services/storage.dart';

enum ReadingMode { vertical, horizontal, doublePage }

class ReaderPage extends StatefulWidget {
  final String mangaId;
  final ChapterMeta chapter;

  const ReaderPage({super.key, required this.mangaId, required this.chapter});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  ReadingMode _mode = ReadingMode.vertical;
  late Future<List<File>> _pagesFuture;
  int _currentPage = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _pagesFuture = _loadPages();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final idx = await loadIndex(widget.mangaId);
    setState(() {
      _isFavorite = idx.favorites.contains(idx.meta.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final idx = await loadIndex(widget.mangaId);
    if (_isFavorite) {
      idx.favorites.remove(idx.meta.id);
    } else {
      idx.favorites.add(idx.meta.id);
    }
    await saveIndex(widget.mangaId, idx);
    setState(() => _isFavorite = !_isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? "Adicionado aos favoritos" : "Removido dos favoritos",
        ),
      ),
    );
  }

  Future<List<File>> _loadPages() async {
    final dir = await chapterDir(widget.mangaId, widget.chapter.label);
    if (!await dir.exists()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.toLowerCase().endsWith('.jpg') ||
            f.path.toLowerCase().endsWith('.png') ||
            f.path.toLowerCase().endsWith('.webp'))
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  void _toggleMode() {
    setState(() {
      switch (_mode) {
        case ReadingMode.vertical:
          _mode = ReadingMode.horizontal;
          break;
        case ReadingMode.horizontal:
          _mode = ReadingMode.doublePage;
          break;
        case ReadingMode.doublePage:
          _mode = ReadingMode.vertical;
          break;
      }
    });
  }

  Widget _zoomableImage(File file, {required int index}) {
    final imageWidget = Image.file(
      file,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    return VisibilityDetector(
      key: ValueKey("page_$index"),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          setState(() => _currentPage = index);
        }
      },
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter.title != null &&
            widget.chapter.title!.isNotEmpty
        ? "Cap. ${widget.chapter.number ?? ''} - ${widget.chapter.title}"
        : "Cap. ${widget.chapter.number ?? widget.chapter.id}";

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterTitle),
        actions: [
          IconButton(
            icon: Icon(
              _mode == ReadingMode.vertical
                  ? Icons.view_agenda
                  : _mode == ReadingMode.horizontal
                      ? Icons.view_carousel
                      : Icons.view_week,
            ),
            onPressed: _toggleMode,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.yellow : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: FutureBuilder<List<File>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pages = snapshot.data!;
          if (pages.isEmpty) {
            return const Center(child: Text("Nenhuma página encontrada."));
          }

          Widget progressBar() => Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / pages.length,
                    backgroundColor: Colors.black12,
                    color: Colors.blueAccent,
                  ),
                ),
              );

          switch (_mode) {
            case ReadingMode.vertical:
              return Stack(
                children: [
                  ListView.builder(
                    itemCount: pages.length,
                    itemBuilder: (_, i) => _zoomableImage(pages[i], index: i),
                  ),
                  progressBar(),
                ],
              );

            case ReadingMode.horizontal:
              return Stack(
                children: [
                  PageView.builder(
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) =>
                        _zoomableImage(pages[i], index: i),
                  ),
                  progressBar(),
                ],
              );

            case ReadingMode.doublePage:
              final pairs = <List<File>>[];
              for (int i = 0; i < pages.length; i += 2) {
                pairs.add(
                  (i + 1 < pages.length)
                      ? [pages[i], pages[i + 1]]
                      : [pages[i]],
                );
              }
              return Stack(
                children: [
                  PageView.builder(
                    itemCount: pairs.length,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i * 2),
                    itemBuilder: (_, i) {
                      final p = pairs[i];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: p
                            .map((f) => Expanded(
                                  child: _zoomableImage(f, index: i),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  progressBar(),
                ],
              );
          }
        },
      ),
    );
  }
}
