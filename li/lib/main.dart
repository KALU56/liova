import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/onboarding/onboarding_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/home/home_page.dart';
import 'scan/scan_page.dart';
import 'scan/result_page.dart';
import 'history/history_page.dart';
import 'profile/profile_page.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LiovaApp());
}

class LiovaApp extends StatelessWidget {
  const LiovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liova',
      debugShowCheckedModeBanner: false,
      theme: liovaTheme(),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => OnboardingPage(
              onGetStarted: () => Navigator.pushNamed(context, '/signup'),
              onSignIn: () => Navigator.pushNamed(context, '/login'),
            ),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/result': (context) => const ResultPage(),
        '/history': (context) => const HistoryPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
