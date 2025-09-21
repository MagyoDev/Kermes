import 'package:flutter/material.dart';
import '../api/mangadex_client.dart';
import '../models/models.dart';
import 'manga_detail_page.dart';

class CatalogPage extends StatefulWidget {
  final bool showAppBar;
  const CatalogPage({super.key, this.showAppBar = true});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final MangaDexClient _client = MangaDexClient();
  final ScrollController _scrollCtrl = ScrollController();

  String _query = '';
  List<MangaMeta> _items = [];

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;

  final String _lang = 'en'; 
  String _order = 'followedCount';

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        _fetch();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    try {
      if (reset) {
        _page = 1;
        _items.clear();
        _hasMore = true;
      }

      List<MangaMeta> list;
      if (_query.trim().isEmpty) {
        list = await _client.listPopular(
          page: _page,
          lang: _lang,
          order: _order,
        );
      } else {
        list = await _client.search(
          _query.trim(),
          page: _page,
          lang: _lang,
          order: _order,
        );
      }

      if (list.isEmpty) {
        _hasMore = false;
      } else {
        _page++;
        _items.addAll(list);
      }

      if (!mounted) return;
      setState(() {});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(MangaMeta m) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MangaDetailPage(mangaId: m.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                "Catálogo",
                style: texts.titleLarge!.copyWith(
                  color: colors.onPrimary, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              actions: [
                PopupMenuButton<String>(
                  color: colors.surface,
                  onSelected: (value) {
                    setState(() {
                      switch (value) {
                        case 'recent':
                          _order = 'latestUploadedChapter';
                          break;
                        case 'updated':
                          _order = 'updatedAt';
                          break;
                        default:
                          _order = 'followedCount';
                      }
                    });
                    _fetch(reset: true);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'popular',
                      child: Text("Popular",
                          style: texts.bodyMedium!
                              .copyWith(color: colors.onSurface)),
                    ),
                    PopupMenuItem(
                      value: 'recent',
                      child: Text("Recent",
                          style: texts.bodyMedium!
                              .copyWith(color: colors.onSurface)),
                    ),
                    PopupMenuItem(
                      value: 'updated',
                      child: Text("Updated",
                          style: texts.bodyMedium!
                              .copyWith(color: colors.onSurface)),
                    ),
                  ],
                  icon: Icon(Icons.sort, color: colors.onPrimary),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              style: texts.bodyLarge,
              decoration: InputDecoration(
                hintText: "Buscar mangá...",
                hintStyle: texts.bodyMedium!
                    .copyWith(color: colors.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colors.primary),
                filled: true,
                fillColor: colors.surfaceVariant.withOpacity(0.6),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.primary, width: 1.6),
                ),
              ),
              onChanged: (s) => _query = s,
              onSubmitted: (_) => _fetch(reset: true),
            ),
          ),

          const SizedBox(height: 4),

          // Grid com resultados
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _items.isEmpty && !_loading
                  ? Center(
                      key: const ValueKey("empty"),
                      child: Text(
                        "Nenhum mangá encontrado",
                        style: texts.bodyMedium!
                            .copyWith(color: colors.error),
                      ),
                    )
                  : GridView.builder(
                      key: const ValueKey("grid"),
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _items.length) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          );
                        }
                        final m = _items[i];

                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween(begin: 1, end: 1),
                          builder: (context, scale, child) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              hoverColor: colors.secondary.withOpacity(0.08),
                              onTap: () => _openDetail(m),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: m.id,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: m.coverUrl != null
                                            ? Image.network(
                                                m.coverUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(Icons.error,
                                                        color: colors.error),
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                  if (progress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: colors.primary,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: colors.surfaceVariant,
                                                child: Icon(Icons.menu_book,
                                                    size: 40,
                                                    color: colors
                                                        .onSurfaceVariant),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Mantém altura fixa para alinhar todos
                                  SizedBox(
                                    height: 34,
                                    child: Text(
                                      m.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: texts.bodySmall!.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
