import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/catalog_page.dart';
import 'pages/manga_detail_page.dart';
import 'pages/global_library_page.dart';
import 'pages/reader_page.dart';
import 'pages/settings_page.dart';

import 'services/download_manager.dart';
import 'api/mangadex_client.dart';
import 'models/models.dart';
import 'widgets/theme_provider.dart';

void main() {
  // 🔹 Inicializa API padrão
  DownloadManager.instance.api = MangaDexClient();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const KermesApp(),
    ),
  );
}

class KermesApp extends StatelessWidget {
  const KermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Kermes',
      debugShowCheckedModeBanner: false,

      // 🔹 Temas do ThemeProvider (já com cores, hovers, erros, success etc.)
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,

      // 🔹 Rotas principais
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/library': (_) => const GlobalLibraryPage(),
        '/catalog': (_) => const CatalogPage(),
        '/settings': (_) => const SettingsPage(),
      },

      // 🔹 Rotas dinâmicas
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

        // 🔹 Fallback
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Rota não encontrada")),
          ),
        );
      },
    );
  }
}
