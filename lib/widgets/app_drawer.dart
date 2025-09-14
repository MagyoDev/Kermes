import 'package:flutter/material.dart';
import '../pages/global_library_page.dart';
import '../pages/catalog_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.redAccent),
            child: Text(
              'kermes',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('Biblioteca'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalLibraryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Catálogo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatalogPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Sobre'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'kermes',
                applicationVersion: '1.0.0',
                children: const [
                  Text(
                    'Leitor de mangás experimental, com suporte a MangaDex e outros serviços.',
                  )
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
