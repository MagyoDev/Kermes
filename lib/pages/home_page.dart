import 'package:flutter/material.dart';
import 'catalog_page.dart';
import 'global_library_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      CatalogPage(showAppBar: true),       
      GlobalLibraryPage(showAppBar: true), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Catálogo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: "Biblioteca",
          ),
        ],
      ),
    );
  }
}
