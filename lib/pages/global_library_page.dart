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
    final colors = Theme.of(context).colorScheme;

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
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await storage.deleteIndex(mangaId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Mangá removido da biblioteca"),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    var filtered = _items
        .where((i) => i.meta.title.toLowerCase().contains(_query.toLowerCase()))
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
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              actions: [
                IconButton(
                  icon: Icon(
                    _showFavorites ? Icons.star : Icons.star_border,
                    color: _showFavorites ? colors.secondary : colors.onPrimary,
                  ),
                  tooltip:
                      _showFavorites ? "Mostrar todos" : "Mostrar favoritos",
                  onPressed: () =>
                      setState(() => _showFavorites = !_showFavorites),
                ),
                IconButton(
                  icon: Icon(
                    _orderDesc ? Icons.arrow_downward : Icons.arrow_upward,
                    color: colors.onPrimary,
                  ),
                  tooltip: _orderDesc ? "Ordenar Z–A" : "Ordenar A–Z",
                  onPressed: () => setState(() => _orderDesc = !_orderDesc),
                ),
              ],
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _loading
            ? Center(
                key: const ValueKey("loading"),
                child: CircularProgressIndicator(color: colors.primary),
              )
            : Column(
                key: const ValueKey("content"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Buscar mangá...",
                        filled: true,
                        fillColor: colors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.search, color: colors.primary),
                      ),
                      onChanged: (s) => setState(() => _query = s),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: colors.primary,
                      onRefresh: _load,
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                _showFavorites
                                    ? "Nenhum favorito encontrado."
                                    : "Nenhum mangá encontrado.",
                                style: TextStyle(color: colors.error),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: colors.outline),
                              itemBuilder: (_, i) {
                                final idx = filtered[i];
                                final downloadedCount = idx.chapters
                                    .where((c) => c.pages > 0)
                                    .length;

                                return AnimatedOpacity(
                                  opacity: 1,
                                  duration: const Duration(milliseconds: 400),
                                  child: InkWell(
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
                                    borderRadius: BorderRadius.circular(8),
                                    splashColor: colors.primary.withOpacity(0.2),
                                    child: ListTile(
                                      leading: idx.meta.coverUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.network(
                                                idx.meta.coverUrl!,
                                                width: 45,
                                                height: 65,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                  Icons.menu_book,
                                                  size: 40,
                                                  color: colors.secondary,
                                                ),
                                              ),
                                            )
                                          : Icon(Icons.menu_book,
                                              size: 40,
                                              color: colors.secondary),
                                      title: Text(
                                        idx.meta.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: colors.onSurface),
                                      ),
                                      subtitle: Text(
                                        "$downloadedCount capítulos baixados • Idioma: ${idx.meta.lang}",
                                        style: TextStyle(
                                            color: colors.onSurfaceVariant),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: colors.error),
                                        onPressed: () => _delete(idx.meta.id),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
