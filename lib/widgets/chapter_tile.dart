import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage.dart';
import '../pages/reader_page.dart';

class ChapterTile extends StatelessWidget {
  final String mangaId;
  final ChapterMeta c;
  final bool fav;
  final VoidCallback onFav;
  final VoidCallback onDelete;

  const ChapterTile({
    super.key,
    required this.mangaId,
    required this.c,
    required this.fav,
    required this.onFav,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReaderPage(
              mangaId: mangaId,
              chapter: c,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FutureBuilder<String?>(
              future: firstLocalImagePath(mangaId, c.label),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final path = snap.data;
                if (path == null) {
                  return Container(
                    color: Colors.black12,
                    child: const Icon(Icons.image_not_supported),
                  );
                }
                return Image.file(File(path), fit: BoxFit.cover);
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.number == null ? c.label : 'Cap. ${c.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: onFav,
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 18),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'del') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'del', child: Text('Apagar capítulo')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
