import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/freemium_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = FreemiumService.isPremium;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!isPremium)
            BouncyButton(
              scaleDown: 0.97,
              onTap: HapticService.success,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent.withOpacity(0.2),
                             AppColors.accent.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.35)),
                ),
                child: const Row(children: [
                  Icon(Icons.bolt_rounded, color: AppColors.accent, size: 32),
                  SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passer Premium',
                          style: TextStyle(color: AppColors.textPrimary,
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('Illimité + sans pubs',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  )),
                  Text('Voir', style: TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w700)),
                ]),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),
          const SizedBox(height: 24),
          _section('Limites Free', [
            _tile(Icons.queue_music_rounded, 'Exercices par playlist',
                '${FreemiumService.maxExercisesPerPlaylist} max'),
            _tile(Icons.bolt_rounded, 'Mini-Playlists',
                isPremium ? 'Illimité' : '1 seule'),
            _tile(Icons.add_circle_outline, 'Exercices custom',
                isPremium ? 'Illimité' : '3 max'),
          ]),
          const SizedBox(height: 16),
          _section('À propos', [
            _tile(Icons.info_outline, 'Version', '1.0.0 MVP'),
            _tile(Icons.storage_rounded, 'Stockage', '100% local — zéro serveur'),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Text(title.toUpperCase(), style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1))),
      Container(
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18)),
        child: Column(children: tiles),
      ),
    ],
  );

  Widget _tile(IconData icon, String title, String sub) => ListTile(
    leading: Icon(icon, color: AppColors.accent),
    title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
    subtitle: Text(sub, style: const TextStyle(
        color: AppColors.textSecondary, fontSize: 12)),
  );
}
