import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../models/models.dart';
import 'library_page.dart';

class GlobalLibraryPage extends StatefulWidget {
  const GlobalLibraryPage({super.key});

  @override
  State<GlobalLibraryPage> createState() => _GlobalLibraryPageState();
}

class _GlobalLibraryPageState extends State<GlobalLibraryPage> {
  List<LibraryIndex> _items = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadAllIndexes();
    setState(() => _items = list);
  }

  Future<void> _delete(String mangaId) async {
    await deleteIndex(mangaId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items
        .where((i) => i.meta.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Biblioteca")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar mangá...",
                border: OutlineInputBorder(),
              ),
              onChanged: (s) => setState(() => _query = s),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final idx = filtered[i];
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(idx.meta.title),
                  subtitle:
                      Text("${idx.chapters.length} capítulos • Idioma: ${idx.meta.lang}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _delete(idx.meta.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LibraryPage(mangaId: idx.meta.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
