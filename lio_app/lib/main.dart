import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/home/home_page.dart';
import 'screens/onboarding/onboarding_page.dart';
import 'screens/scan/scan_page.dart';

const String kHasSeenOnboardingKey = 'has_seen_onboarding';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool(kHasSeenOnboardingKey) ?? false;
  
  runApp(
    ProviderScope(
      child: LiovaApp(
        prefs: prefs,
        hasSeenOnboarding: hasSeenOnboarding,
      ),
    ),
  );
}

class LiovaApp extends StatelessWidget {
  LiovaApp({
    super.key,
    required this.prefs,
    required this.hasSeenOnboarding,
  });

  final SharedPreferences prefs;
  final bool hasSeenOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Liova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8FF),
        fontFamily: 'Poppins',
      ),
      routerConfig: _router,
    );
  }

  late final GoRouter _router = GoRouter(
    initialLocation: hasSeenOnboarding ? '/signin' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingPage(
          onCompleted: () async {
            await prefs.setBool(kHasSeenOnboardingKey, true);
            if (context.mounted) {
              context.go('/signup');
            }
          },
          onGoToSignIn: () async {
            await prefs.setBool(kHasSeenOnboardingKey, true);
            if (context.mounted) {
              context.go('/signin');
            }
          },
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanPage(),
      ),
    ],
  );
}
