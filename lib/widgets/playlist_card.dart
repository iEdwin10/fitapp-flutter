import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/playlist.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'bouncy_button.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onPlay,
    required this.onShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: onTap,
      scaleDown: 0.97,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.cardLight,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Difficulty dot
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: playlist.difficultyColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    playlist.difficultyLabel.toUpperCase(),
                    style: TextStyle(
                      color: playlist.difficultyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (playlist.type == PlaylistType.mini)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('MINI',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                playlist.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.fitness_center,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${playlist.exerciseCount} exercices',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 14),
                  const Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('~${playlist.estimatedDuration} min',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BouncyButton(
                      scaleDown: 0.94,
                      onTap: () {
                        HapticService.heavy();
                        onPlay();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 22),
                            SizedBox(width: 4),
                            Text('Lancer',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  BouncyButton(
                    onTap: () {
                      HapticService.medium();
                      onShare();
                    },
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.ios_share_rounded,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
