import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

import '../models/models.dart';
import '../api/manga_source.dart';
import '../api/mangadex_client.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import 'reader_page.dart';

class MangaDetailPage extends StatefulWidget {
  final String mangaId;
  const MangaDetailPage({super.key, required this.mangaId});

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  LibraryIndex? _index;
  bool _loading = true;
  String _lang = "pt-br";

  final Map<String, String> langNames = {
    "pt-br": "Português",
    "en": "Inglês",
    "es": "Espanhol",
  };

  final int _pageSize = 30;
  int _visibleCount = 30;
  final ScrollController _scrollController = ScrollController();

  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    DownloadManager.instance.api ??= MangaDexClient();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var idx = await loadIndex(
        widget.mangaId,
        seed: MangaMeta(id: widget.mangaId, title: "Sem título"),
      );

      final client = DownloadManager.instance.api;
      if (client != null) {
        final meta = await client.fetchMangaMeta(widget.mangaId, lang: _lang);
        final chapters =
            await client.fetchChapters(widget.mangaId, lang: _lang);

        MangaMeta updatedMeta = meta.copyWith(lang: _lang);
        String? desc = meta.getDescription(_lang);
        if (desc != null) {
          updatedMeta = updatedMeta.withDescription(_lang, desc);
        }

        idx.meta = updatedMeta;
        idx.chapters = chapters
            .map((c) => ChapterMeta(
                  id: c.id,
                  label: c.labelForFolder(),
                  number: c.chapter,
                  title: c.title,
                  pages: idx.chapters
                      .firstWhere(
                        (old) => old.id == c.id,
                        orElse: () => ChapterMeta(
                          id: c.id,
                          label: c.labelForFolder(),
                          pages: 0,
                        ),
                      )
                      .pages,
                  lang: c.lang,
                ))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _index = idx;
        _loading = false;
        _visibleCount = _pageSize;
      });
    } catch (e) {
      debugPrint("⚠️ Erro em _load: $e");
      setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_index != null && _visibleCount < _index!.chapters.length) {
      setState(() {
        _visibleCount += _pageSize;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_index == null) return;

    final meta = _index!.meta;
    final isFav = _index!.favorites.contains(meta.id);

    setState(() {
      if (isFav) {
        _index!.favorites.remove(meta.id);
      } else {
        _index!.favorites.add(meta.id);
      }
    });

    await saveIndex(widget.mangaId, _index!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isFav
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        content: Text(
          isFav ? "Removido dos favoritos" : "Adicionado aos favoritos",
        ),
      ),
    );
  }

  void _toggleChapterFavorite(ChapterMeta c) async {
    if (_index == null) return;
    final isFav = _index!.favoriteChapters.contains(c.id);

    setState(() {
      if (isFav) {
        _index!.favoriteChapters.remove(c.id);
      } else {
        _index!.favoriteChapters.add(c.id);
      }
    });

    await saveIndex(widget.mangaId, _index!);
  }

  /// 🔹 Detalhes modernizados
  void _showDetails(MangaMeta meta) {
    final colors = Theme.of(context).colorScheme;

    String? original = meta.getDescription(meta.lang);
    String? translated = meta.getDescription(_lang);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        minChildSize: 0.5,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              if (meta.coverUrl != null)
                Center(
                  child: Hero(
                    tag: meta.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(meta.coverUrl!,
                          height: 220, fit: BoxFit.cover),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                meta.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (meta.author != null)
                    Expanded(
                      child: Text("Autor: ${meta.author}",
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  Text(
                    "Idioma: ${langNames[meta.lang] ?? meta.lang}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (original != null) ...[
                Text("Descrição original:",
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(original,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              if (translated != null && translated != original) ...[
                Text("Descrição em ${langNames[_lang] ?? _lang}:",
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(translated,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              if (meta.tags.isNotEmpty) ...[
                Text("Tags:",
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: meta.tags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          backgroundColor:
                              colors.primaryContainer.withOpacity(0.3),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToLibrary() async {
    if (_index != null) {
      await saveIndex(widget.mangaId, _index!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          content: const Text("Adicionado à Biblioteca"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final idx = _index;
    if (idx == null) {
      return const Scaffold(
        body: Center(child: Text("Erro ao carregar mangá.")),
      );
    }

    final chapters = idx.chapters.take(_visibleCount).toList();
    final isFavorite = idx.favorites.contains(idx.meta.id);

    String? descPreview =
        idx.meta.getDescription(_lang) ?? idx.meta.getDescription(idx.meta.lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(idx.meta.title),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (idx.meta.coverUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(idx.meta.coverUrl!, height: 150),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(idx.meta.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (idx.meta.author != null)
                        Text("Autor: ${idx.meta.author}"),
                      const SizedBox(height: 8),
                      if (descPreview != null)
                        Text(
                          descPreview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.info_outline),
                            label: const Text("Detalhes"),
                            onPressed: () => _showDetails(idx.meta),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.bookmark_add),
                            label: const Text("Adicionar"),
                            onPressed: _addToLibrary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _lang,
                    isExpanded: true,
                    items: langNames.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() {
                          _lang = v;
                          _loading = true;
                        });
                        if (_index != null) {
                          _index!.meta = _index!.meta.copyWith(lang: v);
                        }
                        await _load();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text("Total de capítulos: ${idx.chapters.length}",
                style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 24),
            ...chapters.map((c) {
              final displayTitle = (c.title != null && c.title!.isNotEmpty)
                  ? "${c.number ?? ''} - ${c.title}"
                  : (c.number ?? c.id);

              final isFavChapter = idx.favoriteChapters.contains(c.id);

              return AnimatedBuilder(
                animation: DownloadManager.instance,
                builder: (context, _) {
                  final progress =
                      DownloadManager.instance.chapterProgress[c.id] ?? 0.0;
                  final chapStatus =
                      DownloadManager.instance.chapterStatus[c.id] ?? "";

                  Widget trailingWidget;
                  if (chapStatus == "Baixando") {
                    trailingWidget = SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress > 0 && progress < 1 ? progress : null),
                    );
                  } else if (chapStatus == "Concluído" || c.pages > 0) {
                    trailingWidget = Icon(Icons.check_circle,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary);
                  } else if (chapStatus == "Erro") {
                    trailingWidget = Icon(Icons.error,
                        size: 22, color: Theme.of(context).colorScheme.error);
                  } else {
                    trailingWidget = IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.download, size: 22),
                      onPressed: () {
                        DownloadManager.instance.enqueue([
                          DownloadTask(
                            widget.mangaId,
                            MdChapter(
                              id: c.id,
                              chapter: c.number,
                              title: c.title,
                              lang: c.lang,
                            ),
                          ),
                        ]);
                      },
                    );
                  }

                  return ListTile(
                    leading: Icon(Icons.menu_book,
                        color: c.pages > 0 || chapStatus == "Concluído"
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey),
                    title: Text(displayTitle),
                    subtitle: Text(
                      c.pages > 0
                          ? "${c.pages} páginas"
                          : (chapStatus == "Baixando"
                              ? "Baixando..."
                              : "Não baixado"),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavChapter ? Icons.star : Icons.star_border,
                              color: isFavChapter ? Colors.amber : null,
                              size: 22,
                            ),
                            onPressed: () => _toggleChapterFavorite(c),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(child: trailingWidget),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReaderPage(mangaId: widget.mangaId, chapter: c),
                        ),
                      );
                    },
                  );
                },
              );
            }),
            if (_visibleCount < idx.chapters.length)
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  OutlinedButton(
                    onPressed: _loadMore,
                    child: const Text("Carregar mais"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
