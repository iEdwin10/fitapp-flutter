# FitFlow 🏋️‍♂️

**Spotify du Workout** — App Flutter locale pour créer et lancer des playlists de musculation.

## Stack
- Flutter 3.x + Dart 3.x
- `provider` — gestion d'état
- `shared_preferences` — stockage local (0 serveur)
- `flutter_animate` — animations spring/bouncy
- `wakelock_plus` — écran allumé pendant la séance

## Architecture
```
lib/
├── main.dart
├── theme/          ← Dark mode premium (fond #121212, accent #BAF266)
├── models/         ← Exercise, Playlist, WorkoutBlock
├── services/
│   ├── haptic_service.dart   ← 7 tons de vibrations (light/medium/heavy/success/timerEnd/swap/error)
│   ├── difficulty_service.dart
│   ├── parser_service.dart   ← Import/Export texte format PokéShowdown-style
│   └── freemium_service.dart
├── providers/      ← LibraryProvider, PlaylistProvider
├── widgets/
│   ├── bouncy_button.dart    ← Effet press spring + elasticOut
│   └── playlist_card.dart    ← Carte style album Spotify
└── screens/
    ├── main_shell.dart       ← Nav bar animée bounce
    ├── playlists_screen.dart ← Liste + swipe to delete
    ├── builder_screen.dart   ← Constructeur EXO + TR + score
    ├── workout_player_screen.dart ← Player + timer + Machine Occupée
    ├── library_screen.dart
    ├── import_screen.dart
    ├── share_screen.dart
    └── settings_screen.dart
```

## Haptics (7 tons)
| Ton | Usage |
|-----|-------|
| `light` | Scroll, recherche, stepper |
| `medium` | Tap carte, nav, modale |
| `heavy` | Drag, suppression, bouton Play |
| `selection` | Tab switch, mode toggle |
| `success` | Sauvegarde, fin de playlist |
| `timerEnd` | Fin de timer (3x heavy croissant) |
| `seriesValidated` | Valider une série |
| `error` | Limite freemium, erreur |
| `swap` | Machine occupée |

## Run
```bash
git clone https://github.com/iEdwin10/fitapp-flutter
cd fitapp-flutter
flutter pub get
flutter run
```
