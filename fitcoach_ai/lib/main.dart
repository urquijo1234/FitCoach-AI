import 'package:firebase_core/firebase_core.dart';
import 'package:fitcoach_ai/providers/auth_provider.dart';
import 'package:fitcoach_ai/providers/user_profile_provider.dart';
import 'package:fitcoach_ai/providers/weekly_plan_provider.dart';
import 'package:fitcoach_ai/screens/auth_screen.dart';
import 'package:fitcoach_ai/screens/dashboard_screen.dart';
import 'package:fitcoach_ai/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FitCoachApp());
}

class FitCoachApp extends StatelessWidget {
  const FitCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyPlanProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E),
            primary: const Color(0xFF1A237E),
            secondary: const Color(0xFFFF6D00),
            brightness: Brightness.light,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1.5,
            margin: EdgeInsets.zero,
          ),
        ),
        routes: {
          AuthScreen.routeName: (_) => const AuthScreen(),
          OnboardingScreen.routeName: (_) => const OnboardingScreen(),
          '/dashboard': (_) => const DashboardScreen(),
        },
        home: const _EntryGate(),
      ),
    );
  }
}

class _EntryGate extends StatefulWidget {
  const _EntryGate();

  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRoute());
  }

  Future<void> _resolveRoute() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<UserProfileProvider>();
    if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AuthScreen.routeName);
      return;
    }
    final uid = auth.user?.uid;
    if (uid == null) {
      Navigator.pushReplacementNamed(context, AuthScreen.routeName);
      return;
    }
    await profile.loadProfile(uid);
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      profile.hasCompletedOnboarding ? '/dashboard' : OnboardingScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
