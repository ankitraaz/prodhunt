import 'package:flutter/material.dart';
import 'package:prodhunt/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dark / Light Theme",
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
