import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage.dart';
import 'reader_page.dart';

class LibraryDetailPage extends StatefulWidget {
  final String mangaId;
  const LibraryDetailPage({super.key, required this.mangaId});

  @override
  State<LibraryDetailPage> createState() => _LibraryDetailPageState();
}

class _LibraryDetailPageState extends State<LibraryDetailPage> {
  LibraryIndex? _index;
  bool _orderDesc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final idx = await loadIndex(widget.mangaId);
    if (!mounted) return;
    setState(() => _index = idx);
  }

  Future<void> _deleteChapter(String chapterId) async {
    final idx = _index;
    if (idx == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir capítulo"),
        content: const Text("Deseja remover este capítulo da biblioteca?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      idx.chapters.removeWhere((c) => c.id == chapterId);
      idx.favoriteChapters.remove(chapterId); // 🔹 remove dos favoritos também
      await saveIndex(widget.mangaId, idx);
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Capítulo removido")),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final idx = _index;
    if (idx == null) return;

    setState(() {
      if (idx.favorites.contains(idx.meta.id)) {
        idx.favorites.remove(idx.meta.id);
      } else {
        idx.favorites.add(idx.meta.id);
      }
    });

    await saveIndex(widget.mangaId, idx);
  }

  Future<void> _toggleChapterFavorite(String chapterId) async {
    final idx = _index;
    if (idx == null) return;

    setState(() {
      if (idx.favoriteChapters.contains(chapterId)) {
        idx.favoriteChapters.remove(chapterId);
      } else {
        idx.favoriteChapters.add(chapterId);
      }
    });

    await saveIndex(widget.mangaId, idx);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index;

    if (idx == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final chapters = idx.chapters.where((c) => c.pages > 0).toList();

    if (chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(idx.meta.title),
          actions: [
            IconButton(
              icon: Icon(
                idx.favorites.contains(idx.meta.id)
                    ? Icons.star
                    : Icons.star_border,
                color: idx.favorites.contains(idx.meta.id)
                    ? Colors.amber
                    : null,
              ),
              tooltip: idx.favorites.contains(idx.meta.id)
                  ? "Remover dos favoritos"
                  : "Adicionar aos favoritos",
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: const Center(
          child: Text("Nenhum capítulo baixado ainda."),
        ),
      );
    }

    chapters.sort((a, b) {
      final na = double.tryParse(a.number ?? '') ?? 0;
      final nb = double.tryParse(b.number ?? '') ?? 0;
      return _orderDesc ? nb.compareTo(na) : na.compareTo(nb);
    });

    final totalChapters = chapters.length;
    final totalPages = chapters.fold<int>(0, (sum, c) => sum + c.pages);

    return Scaffold(
      appBar: AppBar(
        title: Text(idx.meta.title),
        actions: [
          IconButton(
            icon: Icon(
              idx.favorites.contains(idx.meta.id)
                  ? Icons.star
                  : Icons.star_border,
              color: idx.favorites.contains(idx.meta.id) ? Colors.amber : null,
            ),
            tooltip: idx.favorites.contains(idx.meta.id)
                ? "Remover dos favoritos"
                : "Adicionar aos favoritos",
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              _orderDesc ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip:
                _orderDesc ? "Mais novos primeiro" : "Mais antigos primeiro",
            onPressed: () => setState(() => _orderDesc = !_orderDesc),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Capítulos baixados: $totalChapters • Total de páginas: $totalPages",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Divider(height: 1),
            ...chapters.map((c) {
              final chapterTitle = c.title != null && c.title!.isNotEmpty
                  ? "Cap. ${c.number ?? ''} - ${c.title}"
                  : "Cap. ${c.number ?? c.id}";

              final isFavChapter = idx.favoriteChapters.contains(c.id);

              return Dismissible(
                key: ValueKey(c.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _deleteChapter(c.id);
                  return true;
                },
                child: ListTile(
                  leading: Image.asset("assets/logo.png",
                      width: 32, height: 32), // 🔹 sua logo
                  title: Text(chapterTitle),
                  subtitle: Text("Páginas: ${c.pages}"),
                  trailing: IconButton(
                    icon: Icon(
                      isFavChapter ? Icons.star : Icons.star_border,
                      color: isFavChapter ? Colors.amber : null,
                    ),
                    onPressed: () => _toggleChapterFavorite(c.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderPage(
                          mangaId: widget.mangaId,
                          chapter: c,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
