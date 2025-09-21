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
        final chapters = await client.fetchChapters(widget.mangaId, lang: _lang);

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
                          .firstWhere((old) => old.id == c.id,
                              orElse: () => ChapterMeta(
                                  id: c.id,
                                  label: c.labelForFolder(),
                                  pages: 0))
                          .pages ??
                      0, // 🔹 mantém páginas já salvas
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
      print("⚠️ Erro em _load: $e");
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

  /// 🔹 Favoritar/desfavoritar mangá
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
        content: Text(
          isFav ? "Removido dos favoritos" : "Adicionado aos favoritos",
        ),
      ),
    );
  }

  /// 🔹 Favoritar capítulo
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

  /// 🔹 Mostra detalhes em um modal
  void _showDetails(MangaMeta meta) async {
    String? original = meta.getDescription(meta.lang);
    String? translated = meta.getDescription(_lang);

    if (translated == null && original != null) {
      try {
        final result =
            await translator.translate(original, to: _lang.split('-').first);
        translated = result.text;

        setState(() {
          _index?.meta = meta.withDescription(_lang, translated ?? original);
        });
      } catch (e) {
        translated = original;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meta.coverUrl != null)
                Center(child: Image.network(meta.coverUrl!, height: 200)),
              const SizedBox(height: 12),
              Text(meta.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (meta.author != null) Text("Autor: ${meta.author}"),
              Text("Idioma original: ${langNames[meta.lang] ?? meta.lang}"),
              const SizedBox(height: 12),
              if (original != null) ...[
                Text("Descrição original:",
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(original, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
              ],
              if (translated != null) ...[
                Text("Descrição em ${langNames[_lang] ?? _lang}:",
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(translated, style: const TextStyle(fontSize: 14)),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: meta.tags.map((t) => Chip(label: Text(t))).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Adicionar à biblioteca
  Future<void> _addToLibrary() async {
    if (_index != null) {
      await saveIndex(widget.mangaId, _index!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adicionado à Biblioteca")),
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
            tooltip:
                isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos",
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
            // HEADER
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

            // Idioma
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

            // TOTAL DE CAPÍTULOS
            Text("Total de capítulos: ${idx.chapters.length}",
                style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 24),

            // LISTA DE CAPÍTULOS
            ...chapters.map((c) {
              final displayTitle = (c.title != null && c.title!.isNotEmpty)
                  ? "Cap. ${c.number ?? ''} - ${c.title}"
                  : "Cap. ${c.number ?? c.id}";

              final isFavChapter = idx.favoriteChapters.contains(c.id);

              return AnimatedBuilder(
                animation: DownloadManager.instance,
                builder: (context, _) {
                  final downloading =
                      DownloadManager.instance.status.contains(c.id);

                  Widget trailingWidget;

                  if (downloading) {
                    trailingWidget = const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  } else if (c.pages > 0) {
                    trailingWidget =
                        Image.asset("assets/logo.png", width: 28, height: 28);
                  } else {
                    trailingWidget = IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        DownloadManager.instance.api ??= MangaDexClient();

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

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Capítulo adicionado à fila")),
                        );

                        DownloadManager.instance.addListener(() async {
                          if (!DownloadManager.instance.running) {
                            await _load(); // 🔹 atualiza pages
                          }
                        });
                      },
                    );
                  }

                  return ListTile(
                    leading: Icon(
                      c.pages > 0 ? Icons.menu_book : Icons.menu_book_outlined,
                      color: c.pages > 0 ? Colors.green : null,
                    ),
                    title: Text(displayTitle),
                    subtitle: Text(
                      c.pages > 0
                          ? "${c.pages} páginas"
                          : "Capítulo não baixado",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavChapter ? Icons.star : Icons.star_border,
                            color: isFavChapter ? Colors.amber : null,
                          ),
                          onPressed: () => _toggleChapterFavorite(c),
                        ),
                        trailingWidget,
                      ],
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

            // ✅ Barra de download em andamento
            AnimatedBuilder(
              animation: DownloadManager.instance,
              builder: (context, _) {
                if (!DownloadManager.instance.running) {
                  return const SizedBox.shrink();
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListTile(
                    leading: const Icon(Icons.downloading, color: Colors.blue),
                    title: Text(DownloadManager.instance.status),
                    subtitle: LinearProgressIndicator(
                      value: DownloadManager.instance.progress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
