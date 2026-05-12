import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'core/utils/sound_fx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  // Spin up the audio engine in the background — first SFX call should be instant.
  unawaited(SoundFx.warmUp());
  runApp(const ProviderScope(child: KahootApp()));
}

void unawaited(Future<void> _) {} // tiny shim to silence the lint
