import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view/login/widgets/splash_screen.dart';
import 'view/login/login_page.dart';
import 'view/login/register_page.dart';
import 'view/dashboard/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travelex/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://msvugvsvtxfwooqbdqak.supabase.co', 
    anonKey: 'sb_publishable_W5ZT8SC93LNsBxqcIylKZw_QXkcdMt7',

    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  await Firebase.initializeApp();

  await NotificationService.inicializarNotificaciones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel X',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212)
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(userName: 'Usuario'),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(isLoggedIn: false);
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const SplashScreen(isLoggedIn: true);
        } else {
          return const SplashScreen(isLoggedIn: false);
        }
      },
    );
  }
}