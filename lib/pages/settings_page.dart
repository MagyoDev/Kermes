import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: ListView(
        children: [
          // Modo escuro
          SwitchListTile(
            title: const Text("Modo escuro"),
            subtitle: const Text("Ativa/desativa o tema noturno do app"),
            activeColor: colors.primary,
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleDarkMode(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? "Modo escuro ativado" : "Modo claro ativado",
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: colors.primaryContainer,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          // Tema do sistema
          ListTile(
            leading: Icon(Icons.settings_brightness, color: colors.secondary),
            title: const Text("Seguir tema do sistema"),
            onTap: () {
              themeProvider.setSystemTheme();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Agora seguindo tema do sistema"),
                  duration: const Duration(seconds: 2),
                  backgroundColor: colors.secondaryContainer,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const Divider(),

          // Seção Sobre
          ListTile(
            leading: Icon(Icons.info_outline, color: colors.secondary),
            title: const Text("Sobre"),
            subtitle: const Text("Informações do aplicativo"),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: colors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.book, size: 32, color: ThemeProvider.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Kermes",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text("Versão 0.0.3"),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Aplicativo para leitura de mangás."),
                      const SizedBox(height: 8),
                      const Text(
                        "O Kermes é um leitor de mangás simples e rápido, integrado com a API do MangaDex.",
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text("Fechar"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
