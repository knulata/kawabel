import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Fonts bundled locally for offline PWA support (no network fetch needed)
import 'core/ai/chat_service.dart';
import 'core/models/student.dart';
import 'core/services/question_cache.dart';
import 'core/theme/kawabel_theme.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load question bank cache (downloads in background if stale)
  QuestionCache().initialize();
  runApp(const KawabelApp());
}

class KawabelApp extends StatelessWidget {
  const KawabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => ChatService()),
      ],
      child: MaterialApp(
        title: 'Kawabel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: KColors.green,
            primary: KColors.green,
            secondary: KColors.orange,
            surface: KColors.surfaceWarm,
          ),
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();
    if (student.isLoggedIn) {
      // Wrap in Listener to reset idle timer on any touch
      return Listener(
        onPointerDown: (_) => student.resetIdleTimer(),
        child: const HomeScreen(),
      );
    }
    return const LoginScreen();
  }
}
