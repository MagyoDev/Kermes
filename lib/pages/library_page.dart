import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage.dart';
import '../widgets/chapter_tile.dart';

class LibraryPage extends StatefulWidget {
  final String mangaId;
  const LibraryPage({super.key, required this.mangaId});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  LibraryIndex? _index;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final idx = await loadIndex(widget.mangaId);
    setState(() => _index = idx);
  }

  Future<void> _toggleFav(ChapterMeta c) async {
    final idx = _index!;
    if (idx.favorites.contains(c.id)) {
      idx.favorites.remove(c.id);
    } else {
      idx.favorites.add(c.id);
    }
    await saveIndex(widget.mangaId, idx);
    setState(() {});
  }

  Future<void> _deleteChapter(String label) async {
    final idx = _index!;
    idx.chapters.removeWhere((c) => c.label == label);
    await saveIndex(widget.mangaId, idx);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index;
    if (idx == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(idx.meta.title)),
      body: idx.chapters.isEmpty
          ? const Center(child: Text("Nenhum capítulo baixado ainda."))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: idx.chapters.length,
              itemBuilder: (_, i) {
                final c = idx.chapters[i];
                final fav = idx.favorites.contains(c.id);
                return ChapterTile(
                  mangaId: widget.mangaId,
                  c: c,
                  fav: fav,
                  onFav: () => _toggleFav(c),
                  onDelete: () => _deleteChapter(c.label),
                );
              },
            ),
    );
  }
}
