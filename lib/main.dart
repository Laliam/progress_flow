import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Lock orientation to portrait for a focused progress-tracking experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: ProgressFlowApp()));
}

class ProgressFlowApp extends ConsumerWidget {
  const ProgressFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB), // Electric Blue
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF10B981), // Emerald
      tertiary: const Color(0xFFFB7185), // Rose
      brightness: Brightness.dark,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: const Color(0xFF020617),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.white.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
      ),
      cardColor: Colors.white.withValues(alpha: 0.06),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
      ),
    );

    return MaterialApp.router(
      title: 'ProgressFlow',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
