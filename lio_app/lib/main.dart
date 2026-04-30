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

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(child: LiovaApp(prefs: prefs)));
}

class LiovaApp extends StatefulWidget {
  const LiovaApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<LiovaApp> createState() => _LiovaAppState();
}

class _LiovaAppState extends State<LiovaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingPage(
            onGoToSignIn: () async {
              await widget.prefs.setBool(kHasSeenOnboardingKey, true);
              if (!context.mounted) {
                return;
              }
              context.go('/signin');
            },
            onCompleted: () async {
              await widget.prefs.setBool(kHasSeenOnboardingKey, true);
              if (!context.mounted) {
                return;
              }
              context.go('/signup');
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
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(path: '/scan', builder: (context, state) => const ScanPage()),
      ],
    );
  }

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
      ),
      routerConfig: _router,
    );
  }
}
