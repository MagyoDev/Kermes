import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/catalog_page.dart';
import 'pages/manga_detail_page.dart';
import 'pages/global_library_page.dart';
import 'pages/reader_page.dart'; // 🔹 ReaderPage
import 'services/download_manager.dart';
import 'api/mangadex_client.dart';
import 'models/models.dart'; // 🔹 ChapterMeta

void main() {
  DownloadManager.instance.api = MangaDexClient();
  runApp(const KermesApp());
}

class KermesApp extends StatelessWidget {
  const KermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kermes',
      debugShowCheckedModeBanner: false, // 🔹 tira banner DEBUG
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade700,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade700,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/library': (_) => const GlobalLibraryPage(),
        '/catalog': (_) => const CatalogPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail' && settings.arguments is String) {
          final mangaId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => MangaDetailPage(mangaId: mangaId),
          );
        }

        if (settings.name == '/reader' &&
            settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final mangaId = args['mangaId'] as String?;
          final chapter = args['chapter'] as ChapterMeta?;

          if (mangaId != null && chapter != null) {
            return MaterialPageRoute(
              builder: (_) => ReaderPage(mangaId: mangaId, chapter: chapter),
            );
          }
        }

        // fallback caso rota não exista
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Rota não encontrada")),
          ),
        );
      },
    );
  }
}
