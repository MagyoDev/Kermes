class MangaMeta {
  final String id;
  final String title;
  final String? author;
  final List<String> tags;
  final String lang;
  final bool rightToLeft;
  final String? coverUrl;

  /// Descrições por idioma. Ex.: {"en": "...", "pt": "...", "pt-br": "..."}
  final Map<String, String> descriptions;

  MangaMeta({
    required this.id,
    required this.title,
    this.author,
    this.tags = const [],
    this.lang = 'pt-br',
    this.rightToLeft = true,
    this.coverUrl,
    Map<String, String>? descriptions,
  }) : descriptions = Map.unmodifiable(descriptions ?? const {});

  String? getDescription(String wantLang) {
    final base = _baseLang(wantLang);
    if (descriptions.containsKey(wantLang)) return descriptions[wantLang];
    if (descriptions.containsKey(base)) return descriptions[base];
    if (descriptions.containsKey('en')) return descriptions['en'];
    return descriptions.values.isNotEmpty ? descriptions.values.first : null;
  }

  MangaMeta withDescription(String code, String text) {
    final map = Map<String, String>.from(descriptions);
    map[code] = text;
    return copyWith(descriptions: map);
  }

  static String _baseLang(String code) =>
      code.contains('-') ? code.split('-').first : code;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'tags': tags,
        'lang': lang,
        'rightToLeft': rightToLeft,
        'coverUrl': coverUrl,
        'descriptions': descriptions,
      };

  factory MangaMeta.fromJson(Map<String, dynamic> m) => MangaMeta(
        id: m['id'],
        title: m['title'],
        author: m['author'],
        tags: List.unmodifiable((m['tags'] as List?)?.cast<String>() ?? const []),
        lang: m['lang'] ?? 'pt-br',
        rightToLeft: m['rightToLeft'] is bool ? m['rightToLeft'] : true,
        coverUrl: m['coverUrl'],
        descriptions: _coerceDescriptions(m['descriptions'] ?? m['description']),
      );

  static Map<String, String> _coerceDescriptions(dynamic raw) {
    if (raw == null) return {};
    if (raw is String) return {'und': raw};
    if (raw is Map) {
      final out = <String, String>{};
      raw.forEach((k, v) {
        if (k is String && v is String && v.trim().isNotEmpty) {
          out[k] = v;
        }
      });
      return out;
    }
    return {};
  }

  MangaMeta copyWith({
    String? id,
    String? title,
    String? author,
    List<String>? tags,
    String? lang,
    bool? rightToLeft,
    String? coverUrl,
    Map<String, String>? descriptions,
  }) {
    return MangaMeta(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      lang: lang ?? this.lang,
      rightToLeft: rightToLeft ?? this.rightToLeft,
      coverUrl: coverUrl ?? this.coverUrl,
      descriptions: descriptions ?? this.descriptions,
    );
  }
}

class ChapterMeta {
  final String id;
  final String label;
  final String? number;
  final String? title;
  final int pages;
  final String lang;

  double progress;
  int lastPage;

  ChapterMeta({
    required this.id,
    required this.label,
    this.number,
    this.title,
    required this.pages,
    this.lang = 'pt-br',
    this.progress = 0.0,
    this.lastPage = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'number': number,
        'title': title,
        'pages': pages,
        'lang': lang,
        'progress': progress,
        'lastPage': lastPage,
      };

  factory ChapterMeta.fromJson(Map<String, dynamic> m) => ChapterMeta(
        id: m['id'],
        label: m['label'],
        number: m['number'],
        title: m['title'],
        pages: (m['pages'] as num?)?.toInt() ?? 0,
        lang: m['lang'] ?? 'pt-br',
        progress: (m['progress'] ?? 0.0).toDouble(),
        lastPage: (m['lastPage'] ?? 0) as int,
      );

  ChapterMeta copyWith({
    String? id,
    String? label,
    String? number,
    String? title,
    int? pages,
    String? lang,
    double? progress,
    int? lastPage,
  }) {
    return ChapterMeta(
      id: id ?? this.id,
      label: label ?? this.label,
      number: number ?? this.number,
      title: title ?? this.title,
      pages: pages ?? this.pages,
      lang: lang ?? this.lang,
      progress: progress ?? this.progress,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

class LibraryIndex {
  MangaMeta meta;
  List<ChapterMeta> chapters;
  Set<String> favorites;         // mangás
  Set<String> favoriteChapters;  // 🔹 capítulos

  LibraryIndex({
    required this.meta,
    List<ChapterMeta>? chapters,
    Set<String>? favorites,
    Set<String>? favoriteChapters,
  })  : chapters = chapters ?? [],
        favorites = favorites ?? <String>{},
        favoriteChapters = favoriteChapters ?? <String>{};

  Map<String, dynamic> toJson() => {
        'meta': meta.toJson(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'favorites': favorites.toList(),
        'favoriteChapters': favoriteChapters.toList(), // 🔹 salva
      };

  factory LibraryIndex.fromJson(Map<String, dynamic> m) => LibraryIndex(
        meta: MangaMeta.fromJson(m['meta']),
        chapters: (m['chapters'] as List<dynamic>? ?? [])
            .map((c) => ChapterMeta.fromJson(c as Map<String, dynamic>))
            .toList(),
        favorites:
            (m['favorites'] as List?)?.cast<String>().toSet() ?? <String>{},
        favoriteChapters:
            (m['favoriteChapters'] as List?)?.cast<String>().toSet() ??
                <String>{}, // 🔹 carrega
      );
}
