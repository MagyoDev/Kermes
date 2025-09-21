import 'dart:io';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
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
      _isFavorite = idx.favoriteChapters.contains(widget.chapter.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final idx = await loadIndex(widget.mangaId);
    if (_isFavorite) {
      idx.favoriteChapters.remove(widget.chapter.id);
    } else {
      idx.favoriteChapters.add(widget.chapter.id);
    }
    await saveIndex(widget.mangaId, idx);
    setState(() => _isFavorite = !_isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isFavorite
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        content: Text(
          _isFavorite
              ? "Capítulo marcado como favorito"
              : "Capítulo removido dos favoritos",
        ),
        behavior: SnackBarBehavior.floating,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        content: Text(
          _mode == ReadingMode.vertical
              ? "Modo leitura: Vertical"
              : _mode == ReadingMode.horizontal
                  ? "Modo leitura: Horizontal"
                  : "Modo leitura: Dupla página",
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _zoomableImage(File file, {required int index}) {
    return VisibilityDetector(
      key: ValueKey("page_$index"),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          setState(() => _currentPage = index);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: InteractiveViewer(
          key: ValueKey(file.path),
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chapterTitle = widget.chapter.title != null &&
            widget.chapter.title!.isNotEmpty
        ? "Cap. ${widget.chapter.number ?? ''} - ${widget.chapter.title}"
        : "Cap. ${widget.chapter.number ?? widget.chapter.id}";

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            chapterTitle,
            key: ValueKey(chapterTitle),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Alterar modo de leitura",
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
            tooltip: _isFavorite
                ? "Remover dos favoritos"
                : "Adicionar aos favoritos",
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
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
            return Center(
              child: Text(
                "Nenhuma página encontrada.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          Widget progressBar() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 5,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / pages.length,
                      backgroundColor: colors.surfaceVariant,
                      color: colors.primary,
                    ),
                  ),
                ),
              );

          Widget content;
          switch (_mode) {
            case ReadingMode.vertical:
              content = ListView.builder(
                itemCount: pages.length,
                itemBuilder: (_, i) => _zoomableImage(pages[i], index: i),
              );
              break;

            case ReadingMode.horizontal:
              content = PageView.builder(
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _zoomableImage(pages[i], index: i),
              );
              break;

            case ReadingMode.doublePage:
              final pairs = <List<File>>[];
              for (int i = 0; i < pages.length; i += 2) {
                pairs.add(
                  (i + 1 < pages.length)
                      ? [pages[i], pages[i + 1]]
                      : [pages[i]],
                );
              }
              content = PageView.builder(
                itemCount: pairs.length,
                onPageChanged: (i) => setState(() => _currentPage = i * 2),
                itemBuilder: (_, i) {
                  final p = pairs[i];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: p
                        .map((f) => Expanded(child: _zoomableImage(f, index: i)))
                        .toList(),
                  );
                },
              );
              break;
          }

          return Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: content,
              ),
              progressBar(),
            ],
          );
        },
      ),
    );
  }
}
