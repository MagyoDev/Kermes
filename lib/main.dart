import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/global_library_page.dart';
import 'pages/catalog_page.dart';
import 'pages/manga_detail_page.dart';
import 'services/download_manager.dart';
import 'api/mangadex_client.dart';

void main() {
  DownloadManager.instance.api = MangaDexClient();
  runApp(const KermesApp());
}

class KermesApp extends StatelessWidget {
  const KermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kermes',
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
        if (settings.name == '/reader') {
          final mangaId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => LibraryPage(mangaId: mangaId),
          );
        }
        if (settings.name == '/detail') {
          final mangaId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => MangaDetailPage(mangaId: mangaId),
          );
        }
        return null;
      },
    );
  }
}
