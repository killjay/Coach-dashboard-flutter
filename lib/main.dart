import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress Flutter web keyboard event errors (known framework bug)
  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Suppress keyboard-related errors on web
      if (details.exception.toString().contains('KeyUpEvent') ||
          details.exception.toString().contains('HardwareKeyboard') ||
          details.exception.toString().contains('physical key is not pressed')) {
        // Silently ignore these known Flutter web keyboard bugs
        return;
      }
      // Log other errors normally
      FlutterError.presentError(details);
    };
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: CoachClientApp(),
    ),
  );
}

class CoachClientApp extends ConsumerWidget {
  const CoachClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Coach-Client App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

