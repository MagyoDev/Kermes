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

  final String _lang = 'en'; // 🔹 fixo em inglês
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
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text("Catálogo"),
              actions: [
                PopupMenuButton<String>(
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'popular', child: Text("Popular")),
                    PopupMenuItem(value: 'recent', child: Text("Recent")),
                    PopupMenuItem(value: 'updated', child: Text("Updated")),
                  ],
                  icon: const Icon(Icons.sort),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // 🔹 Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search manga...",
                border: OutlineInputBorder(),
              ),
              onChanged: (s) => _query = s,
              onSubmitted: (_) => _fetch(reset: true),
            ),
          ),

          const SizedBox(height: 4),

          // 🔹 Grid with results
          Expanded(
            child: _items.isEmpty && !_loading
                ? const Center(child: Text("No manga found"))
                : GridView.builder(
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
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final m = _items[i];
                      return InkWell(
                        onTap: () => _openDetail(m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: m.coverUrl != null
                                    ? Image.network(
                                        m.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.error),
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.black12,
                                        child: const Center(
                                          child: Icon(Icons.menu_book, size: 40),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 32,
                              child: Text(
                                m.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
