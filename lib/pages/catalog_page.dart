import 'package:flutter/material.dart';
import '../api/mangadex_client.dart';
import '../models/models.dart';
import '../services/storage.dart';
import 'manga_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final MangaDexClient _client = MangaDexClient();
  String _query = '';
  List<MangaMeta> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      List<MangaMeta> list;
      if (_query.trim().isEmpty) {
        list = await _client.listPopular(page: 1);
      } else {
        list = await _client.search(_query.trim(), page: 1);
      }
      setState(() => _items = list);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(MangaMeta m) async {
    final meta = await _client.fetchMangaMeta(m.id, lang: 'pt-br');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MangaDetailPage(mangaId: meta.id),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catálogo")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar",
                border: OutlineInputBorder(),
              ),
              onChanged: (s) => _query = s,
              onSubmitted: (_) => _fetch(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final m = _items[i];
                      return InkWell(
                        onTap: () => _openDetail(m),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: m.coverUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          m.coverUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.menu_book, size: 40),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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
