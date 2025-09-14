class MangaMeta {
  final String id;
  final String title;
  final String? author;
  final List<String> tags;
  final String lang;
  final bool rightToLeft;
  final String? coverUrl; // 🔴 nova propriedade

  MangaMeta({
    required this.id,
    required this.title,
    this.author,
    this.tags = const [],
    this.lang = 'pt-br',
    this.rightToLeft = true,
    this.coverUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'tags': tags,
        'lang': lang,
        'rightToLeft': rightToLeft,
        'coverUrl': coverUrl,
      };

  factory MangaMeta.fromJson(Map<String, dynamic> m) => MangaMeta(
        id: m['id'],
        title: m['title'],
        author: m['author'],
        tags: (m['tags'] as List?)?.cast<String>() ?? const [],
        lang: m['lang'] ?? 'pt-br',
        rightToLeft: m['rightToLeft'] ?? true,
        coverUrl: m['coverUrl'],
      );
}

class ChapterMeta {
  final String id;
  final String label;
  final String? number;
  final String? title;
  final int pages;

  double progress;
  int lastPage;

  ChapterMeta({
    required this.id,
    required this.label,
    this.number,
    this.title,
    required this.pages,
    this.progress = 0.0,
    this.lastPage = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'number': number,
        'title': title,
        'pages': pages,
        'progress': progress,
        'lastPage': lastPage,
      };

  factory ChapterMeta.fromJson(Map<String, dynamic> m) => ChapterMeta(
        id: m['id'],
        label: m['label'],
        number: m['number'],
        title: m['title'],
        pages: (m['pages'] as num).toInt(),
        progress: (m['progress'] ?? 0.0).toDouble(),
        lastPage: (m['lastPage'] ?? 0) as int,
      );
}

class LibraryIndex {
  MangaMeta meta;
  List<ChapterMeta> chapters;
  Set<String> favorites;

  LibraryIndex({
    required this.meta,
    List<ChapterMeta>? chapters,
    Set<String>? favorites,
  })  : chapters = chapters != null ? List.from(chapters) : [],
        favorites = favorites ?? <String>{};

  Map<String, dynamic> toJson() => {
        'meta': meta.toJson(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'favorites': favorites.toList(),
      };

  factory LibraryIndex.fromJson(Map<String, dynamic> m) => LibraryIndex(
        meta: MangaMeta.fromJson(m['meta']),
        chapters: (m['chapters'] as List<dynamic>?)
                ?.map((c) => ChapterMeta.fromJson(c))
                .toList() ??
            [],
        favorites:
            (m['favorites'] as List?)?.cast<String>().toSet() ?? <String>{},
      );
}
