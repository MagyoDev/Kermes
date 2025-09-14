import 'package:flutter/material.dart';
import '../api/mangadex_client.dart';
import '../api/manga_source.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import '../models/models.dart';

class MangaDetailPage extends StatefulWidget {
  final String mangaId;
  const MangaDetailPage({super.key, required this.mangaId});

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  final _dex = MangaDexClient();
  final _dm = DownloadManager.instance;

  MangaMeta? _meta;
  List<MdChapter> _caps = [];
  int _baixados = 0;
  bool _loading = false;

  final _lang = ValueNotifier<String>('pt-br');
  final _langs = const ['pt-br', 'en', 'es', 'ja'];

  final _countCtrl = TextEditingController(text: '5');
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dm.addListener(_refresh);
    _loadMeta();
  }

  @override
  void dispose() {
    _dm.removeListener(_refresh);
    _countCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadMeta() async {
    setState(() => _loading = true);
    try {
      final meta = await _dex.fetchMangaMeta(widget.mangaId, lang: _lang.value);
      final idx = await loadIndex(widget.mangaId, seed: meta);
      setState(() {
        _meta = meta;
        _baixados = idx.chapters.length;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCaps() async {
  setState(() => _loading = true);
  try {
    // pega número total direto do endpoint count
    final total = await _dex.countChapters(
      mangaId: widget.mangaId,
      lang: _lang.value,
    );

    final List<MdChapter> all = [];
    int offset = 0;
    const limit = 100;

    while (all.length < total) {
      final batch = await _dex.fetchChapters(
        widget.mangaId,
        lang: _lang.value,
        offset: offset,
      );
      if (batch.isEmpty) break;
      all.addAll(batch);
      offset += limit;
    }

    // carrega índice local para saber baixados
    final idx = await loadIndex(widget.mangaId, seed: _meta);

    setState(() {
      _caps = all;
      _baixados = idx.chapters.length;
    });
  } finally {
    setState(() => _loading = false);
  }
}


  Future<void> _download() async {
    final meta = _meta;
    if (meta == null) return;

    int? from = int.tryParse(_fromCtrl.text.trim());
    int? to = int.tryParse(_toCtrl.text.trim());
    int? count = int.tryParse(_countCtrl.text.trim());

    final chapters = _caps;

    final tasks = chapters.where((ch) {
      final n = double.tryParse(ch.chapter ?? '');
      final inRange = (from != null && to != null && n != null)
          ? (n >= from && n <= to)
          : true;
      return inRange;
    }).take(count ?? chapters.length).map((ch) {
      return DownloadTask(widget.mangaId, ch);
    });

    if (tasks.isEmpty) return;

    _dm.enqueue(tasks);
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;

    return Scaffold(
      appBar: AppBar(title: Text(meta?.title ?? "Detalhes")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (meta != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: meta.coverUrl != null
                          ? Image.network(
                              meta.coverUrl!,
                              width: 120,
                              height: 160,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 120,
                              height: 160,
                              color: Colors.black12,
                              child: const Center(child: Icon(Icons.menu_book)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meta.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (meta.author != null) ...[
                    const SizedBox(height: 4),
                    Text("Autor: ${meta.author}",
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _lang.value,
                    items: _langs
                        .map((l) => DropdownMenuItem(
                              value: l,
                              child: Text(l),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        _lang.value = v;
                        _loadMeta();
                        _loadCaps();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: "Idioma",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _loadCaps,
                        child: const Text("Verificar Caps"),
                      ),
                      Text("Total: ${_caps.length}"),
                      Text("Baixados: $_baixados"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _countCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "N Caps",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _fromCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "De",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _toCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Até",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _download,
                    child: const Text("Baixar"),
                  ),
                  const SizedBox(height: 16),
                  Text("Status: ${_dm.status}"),
                  LinearProgressIndicator(value: _dm.progress),
                  Text("Concluídos: ${_dm.done}"),
                  const SizedBox(height: 20),

                  /// 🔹 Lista de capítulos
                  if (_caps.isNotEmpty) ...[
                    const Text(
                      "Capítulos disponíveis:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._caps.map((c) => ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: Text(
                            c.title ?? "Cap. ${c.chapter ?? c.id}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text("Número: ${c.chapter ?? '-'}"),
                        )),
                  ],
                ],
              ],
            ),
    );
  }
}
