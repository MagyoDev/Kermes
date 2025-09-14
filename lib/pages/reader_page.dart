// lib/pages/reader_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
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
  List<File> _pages = [];
  ReadingMode _mode = ReadingMode.vertical;
  TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    final dir = await chapterDir(widget.mangaId, widget.chapter.label);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.png') ||
            f.path.endsWith('.webp'))
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    setState(() => _pages = files);
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

  void _resetZoom() {
    setState(() {
      _transformCtrl.value = Matrix4.identity();
    });
  }

  Widget _zoomableImage(File file) {
    return InteractiveViewer(
      transformationController: _transformCtrl,
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.file(file, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title ?? "Cap. ${widget.chapter.number}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _resetZoom,
            tooltip: "Resetar Zoom",
          ),
          IconButton(
            icon: const Icon(Icons.view_agenda),
            onPressed: _toggleMode,
            tooltip: "Mudar modo de leitura",
          ),
        ],
      ),
      body: _buildReader(),
    );
  }

  Widget _buildReader() {
    if (_pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_mode) {
      case ReadingMode.vertical:
        return ListView.builder(
          itemCount: _pages.length,
          itemBuilder: (_, i) => _zoomableImage(_pages[i]),
        );

      case ReadingMode.horizontal:
        return PageView.builder(
          itemCount: _pages.length,
          itemBuilder: (_, i) => _zoomableImage(_pages[i]),
        );

      case ReadingMode.doublePage:
        final pairs = <List<File>>[];
        for (int i = 0; i < _pages.length; i += 2) {
          if (i + 1 < _pages.length) {
            pairs.add([_pages[i], _pages[i + 1]]);
          } else {
            pairs.add([_pages[i]]);
          }
        }
        return PageView.builder(
          itemCount: pairs.length,
          itemBuilder: (_, i) {
            final p = pairs[i];
            return Row(
              children: p
                  .map((file) => Expanded(child: _zoomableImage(file)))
                  .toList(),
            );
          },
        );
    }
  }
}
