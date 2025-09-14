import '../models/models.dart';

abstract class MangaSourceClient {
  String get key;
  String get label;

  Future<List<MangaMeta>> listPopular({int page = 1});
  Future<List<MangaMeta>> search(String query, {int page = 1});
  Future<MangaMeta> fetchMangaMeta(String mangaId, {String lang = 'pt-br'});
  Future<List<MdChapter>> fetchChapters(
    String mangaId, {
    String lang = 'pt-br',
    int offset = 0,
  });
  Future<MdAtHome> atHomeServer(String chapterId);
}

class MdChapter {
  final String id;
  final String? chapter;
  final String? title;
  final String lang;

  MdChapter({required this.id, this.chapter, this.title, required this.lang});

  String labelForFolder() {
    final ch = (chapter ?? '').trim();
    final numVal = double.tryParse(ch);
    if (numVal != null) {
      final left = numVal.truncate();
      final frac = numVal - left;
      return frac == 0
          ? 'ch_${left.toString().padLeft(4, '0')}'
          : 'ch_${ch.replaceAll('.', '_')}';
    }
    return ch.isEmpty ? 'ch_$id' : 'ch_$ch';
  }
}

class MdAtHome {
  final String baseUrl;
  final String hash;
  final List<String> files;

  MdAtHome({required this.baseUrl, required this.hash, required this.files});
}
