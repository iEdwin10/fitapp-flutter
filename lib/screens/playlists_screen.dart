import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../services/haptic_service.dart';
import '../services/freemium_service.dart';
import '../theme/app_theme.dart';
import '../widgets/playlist_card.dart';
import '../widgets/bouncy_button.dart';
import '../models/playlist.dart';
import 'workout_player_screen.dart';
import 'builder_screen.dart';
import 'share_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  void _showCreateMenu(BuildContext context) {
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _CreateMenu(rootContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistProvider>().playlists.toList().reversed.toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Playlists'),
        actions: [
          BouncyButton(
            onTap: () => _showCreateMenu(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
      body: playlists.isEmpty
          ? _EmptyState(onCreate: () => _showCreateMenu(context))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: playlists.length,
              itemBuilder: (context, i) {
                final p = playlists[i];
                return Dismissible(
                  key: Key(p.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppColors.error),
                  ),
                  confirmDismiss: (_) async {
                    HapticService.error();
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text('Supprimer ?',
                            style: TextStyle(color: AppColors.textPrimary)),
                        content: Text('"${p.name}" sera supprimée définitivement.',
                            style: const TextStyle(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler',
                                  style: TextStyle(color: AppColors.textSecondary))),
                          TextButton(onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer',
                                  style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ) ?? false;
                  },
                  onDismissed: (_) {
                    context.read<PlaylistProvider>().deletePlaylist(p.id);
                    HapticService.heavy();
                  },
                  child: PlaylistCard(
                    playlist: p,
                    onPlay: () => Navigator.push(context, _slideUp(WorkoutPlayerScreen(playlist: p))),
                    onShare: () => Navigator.push(context, _slideUp(ShareScreen(playlist: p))),
                    onTap: () => Navigator.push(context, _slideUp(BuilderScreen(existing: p))),
                  ),
                );
              },
            ),
    );
  }

  PageRouteBuilder _slideUp(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 350),
  );
}

class _CreateMenu extends StatelessWidget {
  final BuildContext rootContext;
  const _CreateMenu({required this.rootContext});

  @override
  Widget build(BuildContext context) {
    final miniCount = context.read<PlaylistProvider>().miniPlaylists.length;
    final canMini = FreemiumService.canCreateMiniPlaylist(miniCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Créer une playlist', style: TextStyle(
              color: AppColors.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _item(context, Icons.queue_music_rounded, 'Playlist complète',
              'Séance standard : EXO + repos', AppColors.textPrimary, true,
              () {
                Navigator.pop(context);
                Navigator.push(rootContext,
                    _slide(const BuilderScreen()));
              }),
          const SizedBox(height: 10),
          _item(context, Icons.bolt_rounded, 'Mini-Playlist',
              canMini ? 'Échauffement / HIIT rapide' : 'Free: 1 seule — Passer Premium',
              AppColors.accent, canMini,
              canMini ? () {
                Navigator.pop(context);
                Navigator.push(rootContext,
                    _slide(const BuilderScreen(isMini: true)));
              } : null),
        ],
      ),
    ).animate().slideY(begin: 0.08, end: 0, duration: 320.ms, curve: Curves.easeOutCubic)
     .fadeIn(duration: 280.ms);
  }

  Widget _item(BuildContext ctx, IconData icon, String title, String sub,
      Color iconColor, bool enabled, VoidCallback? onTap) {
    return BouncyButton(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 15)),
                Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary, size: 14),
          ]),
        ),
      ),
    );
  }

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 350),
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏋️', style: TextStyle(fontSize: 64))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.06,
                duration: 2000.ms, curve: Curves.easeInOut),
        const SizedBox(height: 20),
        const Text('Aucune playlist', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 22,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Crée ta première séance', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        BouncyButton(
          scaleDown: 0.93,
          onTap: onCreate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16)),
            child: const Text('Créer une playlist', style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}
