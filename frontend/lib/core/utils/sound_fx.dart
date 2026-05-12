import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// All recognised sound effect slots. Each maps to an asset file under
/// `assets/sounds/{name}.mp3`. Missing files degrade gracefully — the
/// engine plays a system click instead so UX never breaks.
enum AppSound {
  click,
  hover,
  submit,
  correct,
  wrong,
  countdownTick,
  countdownEnd,
  questionReveal,
  streakCombo,
  rankUp,
  victory,
  joinJingle,
}

/// Premium sound engine.
///
/// Design notes:
///   - Uses [audioplayers] for short SFX. One pooled player per active sound
///     so overlapping triggers don't cut each other off.
///   - All asset paths point inside `assets/sounds/` — register them in
///     pubspec.yaml when you ship real files.
///   - No-asset / load-failure path falls back to platform `SystemSound`.
///   - Disabled state can be toggled at runtime via [enabled].
class SoundFx {
  SoundFx._();
  static bool enabled = true;

  /// Cache: 1 player per concurrent slot. Cleaned up automatically when
  /// playback completes.
  static final List<AudioPlayer> _pool = [];
  static const int _poolMax = 6;
  static final Set<AppSound> _missingAssets = {};

  static String _assetFor(AppSound s) {
    switch (s) {
      case AppSound.click:           return 'sounds/click.mp3';
      case AppSound.hover:           return 'sounds/hover.mp3';
      case AppSound.submit:          return 'sounds/submit.mp3';
      case AppSound.correct:         return 'sounds/correct.mp3';
      case AppSound.wrong:           return 'sounds/wrong.mp3';
      case AppSound.countdownTick:   return 'sounds/tick.mp3';
      case AppSound.countdownEnd:    return 'sounds/buzzer.mp3';
      case AppSound.questionReveal:  return 'sounds/reveal.mp3';
      case AppSound.streakCombo:     return 'sounds/combo.mp3';
      case AppSound.rankUp:          return 'sounds/rank_up.mp3';
      case AppSound.victory:         return 'sounds/victory.mp3';
      case AppSound.joinJingle:      return 'sounds/join.mp3';
    }
  }

  /// Default volume per sound (0.0–1.0). Subtle by default — never blast.
  static double _volume(AppSound s) {
    switch (s) {
      case AppSound.victory:        return 0.85;
      case AppSound.streakCombo:    return 0.75;
      case AppSound.correct:
      case AppSound.wrong:
      case AppSound.countdownEnd:   return 0.65;
      case AppSound.questionReveal: return 0.55;
      case AppSound.click:
      case AppSound.submit:
      case AppSound.countdownTick:
      case AppSound.rankUp:
      case AppSound.joinJingle:     return 0.45;
      case AppSound.hover:          return 0.18;
    }
  }

  static AudioPlayer _acquire() {
    if (_pool.length < _poolMax) {
      final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
      return p;
    }
    // Reuse the oldest one — should already be done playing.
    final p = _pool.removeAt(0);
    _pool.add(p);
    return p;
  }

  static Future<void> play(AppSound sound) async {
    if (!enabled) return;
    if (_missingAssets.contains(sound)) {
      await _systemFallback(sound);
      return;
    }
    try {
      final player = _acquire();
      await player.stop();
      await player.setVolume(_volume(sound));
      await player.play(AssetSource(_assetFor(sound)));
    } catch (e) {
      // Asset missing — remember, don't try again, fall back to a system sound.
      _missingAssets.add(sound);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[SoundFx] missing asset for $sound — using system fallback');
      }
      await _systemFallback(sound);
    }
  }

  static Future<void> _systemFallback(AppSound s) async {
    try {
      switch (s) {
        case AppSound.wrong:
        case AppSound.countdownEnd:
          await SystemSound.play(SystemSoundType.alert);
        default:
          await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {/* silent */}
  }

  /// Eagerly preload a few critical sounds so the first play is instant.
  static Future<void> warmUp() async {
    if (!enabled) return;
    // Touch one player so the engine spins up.
    try {
      final p = _acquire();
      await p.setVolume(0);
      // Playing a missing asset is fine — it just primes the engine.
      await p.play(AssetSource(_assetFor(AppSound.click)));
      await p.stop();
    } catch (_) {/* no-op */}
  }
}
