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
    final texts = Theme.of(context).textTheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmar exclusão", style: texts.titleMedium),
        content: Text("Deseja remover este mangá da biblioteca?",
            style: texts.bodyMedium),
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
    final texts = Theme.of(context).textTheme;

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
              title: Text(
                "Biblioteca",
                style: texts.titleLarge!.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  // 🔹 Barra de busca estilizada
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: colors.outline.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: colors.primary, width: 1.6),
                        ),
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
                                style: texts.bodyMedium!
                                    .copyWith(color: colors.error),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1, color: colors.outline.withOpacity(0.4)),
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
                                        style: texts.bodyLarge!.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "$downloadedCount capítulos baixados • Idioma: ${idx.meta.lang}",
                                        style: texts.bodySmall!.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
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
