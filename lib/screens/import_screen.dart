import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../services/parser_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _ctrl = TextEditingController();
  String? _error;

  void _import() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final playlist = ParserService.importTextToPlaylist(text);
    if (playlist == null) {
      HapticService.error();
      setState(() => _error = 'Format invalide. Vérifie la syntaxe.');
      return;
    }
    context.read<PlaylistProvider>().addPlaylist(playlist);
    HapticService.success();
    setState(() => _error = null);
    _ctrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ "${playlist.name}" importée !'),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Importer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coller le code playlist', style: TextStyle(
                color: AppColors.textPrimary, fontSize: 20,
                fontWeight: FontWeight.w700))
                .animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14)),
              child: const Text(
                '=== NAME: Pecs | TYPE: standard ===\nEXO: bench_press | S:4 | R:10 | P:80 | PAUSE:60\nTR: 30\nEXO: push_up | S:3 | R:15',
                style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 8,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13,
                  fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '=== NAME: Ma Séance | TYPE: standard ===\n...',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                filled: true, fillColor: AppColors.card,
                errorText: _error,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardLight)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardLight)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 16),
            BouncyButton(
              scaleDown: 0.95,
              onTap: _import,
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Importer',
                    style: TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w800, fontSize: 16))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
