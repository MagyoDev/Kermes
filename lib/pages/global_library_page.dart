import 'package:flutter/material.dart';
import '../services/storage.dart' as storage;
import '../models/models.dart';
import 'library_page.dart';

class GlobalLibraryPage extends StatefulWidget {
  final bool showAppBar;
  const GlobalLibraryPage({super.key, this.showAppBar = true});

  @override
  State<GlobalLibraryPage> createState() => _GlobalLibraryPageState();
}

class _GlobalLibraryPageState extends State<GlobalLibraryPage> {
  List<LibraryIndex> _items = [];
  String _query = '';
  bool _loading = true;
  bool _orderDesc = false;
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await storage.listIndexes();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(String mangaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: const Text("Deseja remover este mangá da biblioteca?"),
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
      await storage.deleteIndex(mangaId);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _items
        .where((i) =>
            i.meta.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    if (_showFavorites) {
      filtered =
          filtered.where((i) => i.favorites.contains(i.meta.id)).toList();
    }

    filtered.sort((a, b) {
      final cmp = a.meta.title.compareTo(b.meta.title);
      return _orderDesc ? -cmp : cmp;
    });

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text("Biblioteca"),
              actions: [
                IconButton(
                  icon: Icon(_showFavorites ? Icons.star : Icons.star_border),
                  tooltip: _showFavorites ? "Mostrar todos" : "Mostrar favoritos",
                  onPressed: () =>
                      setState(() => _showFavorites = !_showFavorites),
                ),
                IconButton(
                  icon: Icon(
                      _orderDesc ? Icons.arrow_downward : Icons.arrow_upward),
                  tooltip: _orderDesc ? "Ordenar Z–A" : "Ordenar A–Z",
                  onPressed: () => setState(() => _orderDesc = !_orderDesc),
                ),
              ],
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Buscar mangá...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (s) => setState(() => _query = s),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _showFavorites
                                  ? "Nenhum favorito encontrado."
                                  : "Nenhum mangá encontrado.",
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final idx = filtered[i];
                              final downloadedCount =
                                  idx.chapters.where((c) => c.pages > 0).length;

                              return ListTile(
                                leading: idx.meta.coverUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          idx.meta.coverUrl!,
                                          width: 45,
                                          height: 65,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.menu_book,
                                                  size: 40),
                                        ),
                                      )
                                    : const Icon(Icons.menu_book, size: 40),
                                title: Text(
                                  idx.meta.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  "$downloadedCount capítulos baixados • Idioma: ${idx.meta.lang}",
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _delete(idx.meta.id),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LibraryDetailPage(
                                        mangaId: idx.meta.id,
                                      ),
                                    ),
                                  ).then((_) => _load());
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
