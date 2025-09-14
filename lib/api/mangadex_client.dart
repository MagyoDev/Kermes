import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'manga_source.dart';

class MangaDexClient implements MangaSourceClient {
  static const _apiBase = 'https://api.mangadex.org';
  final http.Client _http;

  MangaDexClient([http.Client? client]) : _http = client ?? http.Client();

  @override
  String get key => 'mangadex';

  @override
  String get label => 'MangaDex (API)';

  Future<String?> _getCover(Map d) async {
    final rels = (d['relationships'] as List?) ?? [];
    final coverRel =
        rels.firstWhere((r) => r['type'] == 'cover_art', orElse: () => null);

    if (coverRel == null) return null;
    final fileName = coverRel['attributes']?['fileName'];
    if (fileName == null) return null;

    return "https://uploads.mangadex.org/covers/${d['id']}/$fileName.512.jpg";
  }

  @override
  Future<List<MangaMeta>> listPopular({int page = 1}) async {
    final uri = Uri.parse(
      '$_apiBase/manga?limit=20&offset=${(page - 1) * 20}&order[followedCount]=desc&includes[]=cover_art',
    );

    final r = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return [];

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final data = (j['data'] as List?) ?? [];

    return Future.wait(data.map((d) async {
      final attrs = d['attributes'] as Map;
      final titleMap = (attrs['title'] as Map?) ?? {};
      String title = titleMap['en'] ?? titleMap.values.first ?? 'Sem título';

      final coverUrl = await _getCover(d);

      return MangaMeta(
        id: d['id'],
        title: title,
        coverUrl: coverUrl,
      );
    }));
  }

  @override
  Future<List<MangaMeta>> search(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '$_apiBase/manga?limit=20&offset=${(page - 1) * 20}&title=${Uri.encodeQueryComponent(query)}&includes[]=cover_art',
    );

    final r = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return [];

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final data = (j['data'] as List?) ?? [];

    return Future.wait(data.map((d) async {
      final attrs = d['attributes'] as Map;
      final titleMap = (attrs['title'] as Map?) ?? {};
      String title = titleMap['en'] ?? titleMap.values.first ?? 'Sem título';

      final coverUrl = await _getCover(d);

      return MangaMeta(
        id: d['id'],
        title: title,
        coverUrl: coverUrl,
      );
    }));
  }

  @override
  Future<MangaMeta> fetchMangaMeta(
    String mangaId, {
    String lang = 'pt-br',
    bool rightToLeft = true,
  }) async {
    final uri = Uri.parse(
      '$_apiBase/manga/$mangaId?includes[]=author&includes[]=cover_art',
    );

    final r = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      return MangaMeta(
        id: mangaId,
        title: 'Sem título',
        lang: lang,
        rightToLeft: rightToLeft,
      );
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final d = (j['data'] as Map);
    final attrs = (d['attributes'] as Map);

    final titleMap = (attrs['title'] as Map?) ?? {};
    final alt = (attrs['altTitles'] as List?)?.cast<Map>() ?? [];

    String title = titleMap[lang] ??
        titleMap['en'] ??
        (titleMap.isNotEmpty ? titleMap.values.first : null) ??
        'Sem título';

    if (title == 'Sem título' && alt.isNotEmpty) {
      final m =
          alt.firstWhere((e) => e.containsKey(lang), orElse: () => alt.first);
      if (m.isNotEmpty) title = m.values.first;
    }

    String? author;
    final rels = (d['relationships'] as List?) ?? [];
    for (final r in rels) {
      if (r['type'] == 'author') {
        author = (r['attributes']?['name'] as String?);
        break;
      }
    }

    final tags = ((attrs['tags'] as List?) ?? [])
        .map((e) => (e as Map?)?['attributes']?['name']?['en'])
        .whereType<String>()
        .take(10)
        .toList();

    final coverUrl = await _getCover(d);

    return MangaMeta(
      id: mangaId,
      title: title,
      author: author,
      tags: tags,
      lang: lang,
      rightToLeft: rightToLeft,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<List<MdChapter>> fetchChapters(
    String mangaId, {
    String lang = 'pt-br',
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '$_apiBase/manga/$mangaId/feed?limit=100&translatedLanguage[]=$lang&offset=$offset&order[chapter]=asc',
    );

    final r = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return [];

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final data = (j['data'] as List?) ?? [];

    final chapters = data.map<MdChapter>((d) {
      final attrs = d['attributes'] as Map;
      return MdChapter(
        id: d['id'],
        chapter: attrs['chapter'] as String?,
        title: attrs['title'] as String?,
        lang: lang,
      );
    }).toList();

    // 🔹 remove duplicados
    final seen = <String>{};
    final unique = <MdChapter>[];
    for (final ch in chapters) {
      final num = ch.chapter ?? ch.id;
      if (seen.contains(num)) continue;
      seen.add(num);
      unique.add(ch);
    }

    return unique;
  }

  @override
  Future<MdAtHome> atHomeServer(String chapterId) async {
    final uri = Uri.parse('$_apiBase/at-home/server/$chapterId');
    final r = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('Erro servidor MangaDex');

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final chapter = j['chapter'] as Map;

    return MdAtHome(
      baseUrl: j['baseUrl'],
      hash: chapter['hash'],
      files: (chapter['data'] as List).cast<String>(),
    );
  }

  Future<int> countChapters({
    required String mangaId,
    String lang = 'pt-br',
  }) async {
    final uri = Uri.parse('$_apiBase/chapter').replace(queryParameters: {
      'manga': mangaId,
      'translatedLanguage[]': lang,
      'order[chapter]': 'asc',
      'limit': '0', // não traz dados, só conta
      'offset': '0',
    });

    final r = await _http.get(uri).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw Exception('Erro ao contar capítulos: ${r.statusCode}');
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final total = (j['total'] as num?)?.toInt() ?? 0;
    return total;
  }
}
