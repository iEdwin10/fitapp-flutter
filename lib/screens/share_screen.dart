import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/playlist.dart';
import '../services/parser_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class ShareScreen extends StatelessWidget {
  final Playlist playlist;
  const ShareScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final code = ParserService.exportPlaylistToText(playlist);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Partager')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(playlist.name, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 24,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${playlist.exerciseCount} exercices · ~${playlist.estimatedDuration} min',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardLight),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13, fontFamily: 'monospace', height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            BouncyButton(
              scaleDown: 0.95,
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                HapticService.success();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('📋 Code copié !'),
                  backgroundColor: AppColors.card,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text('Copier le code', style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800,
                        fontSize: 15)),
                  ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
