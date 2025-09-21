import 'package:flutter/material.dart';
import 'catalog_page.dart';
import 'global_library_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    CatalogPage(key: ValueKey("catalog")),
    GlobalLibraryPage(key: ValueKey("library")),
    SettingsPage(key: ValueKey("settings")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    return Scaffold(
      // troca com animação suave (fade + slide)
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.05, 0), // entra levemente da direita
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _pages[_selectedIndex],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colors.surface,
        indicatorColor: Colors.transparent, // 🔹 sem bolha de fundo
        animationDuration: const Duration(milliseconds: 250),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.explore, color: colors.onSurfaceVariant),
            selectedIcon: Icon(Icons.explore, color: colors.primary, size: 28),
            label: "Catálogo",
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books, color: colors.onSurfaceVariant),
            selectedIcon:
                Icon(Icons.library_books, color: colors.primary, size: 28),
            label: "Biblioteca",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: colors.onSurfaceVariant),
            selectedIcon:
                Icon(Icons.settings, color: colors.primary, size: 28),
            label: "Configurações",
          ),
        ],
      ),
    );
  }
}
