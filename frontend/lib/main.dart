import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view/login/widgets/splash_screen.dart';
import 'view/login/login_page.dart';
import 'view/login/register_page.dart';
import 'view/dashboard/dashboard.dart';
import 'package:travelex/services/notification_service.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://msvugvsvtxfwooqbdqak.supabase.co', 
    anonKey: 'sb_publishable_W5ZT8SC93LNsBxqcIylKZw_QXkcdMt7',
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  await NotificationService.inicializarNotificaciones();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp()
      ),
    );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
        scaffoldBackgroundColor: const Color.fromARGB(255, 48, 47, 47),
      ),
      themeMode: themeProvider.themeMode,
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _antenasEncendidas = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(isLoggedIn: false);
        }

        final session = snapshot.data?.session;

        if (session != null) {
          if (!_antenasEncendidas) {
          NotificationService.escucharEventosEnTiempoReal(session.user.id); 
          _antenasEncendidas = true;
          }

          final userName = session.user.userMetadata?['username'] ?? 'Usuario';
          return DashboardPage(userName: userName);
        } else {
          if (_antenasEncendidas) {
            NotificationService.apagarAntenasEnTiempoReal();
            _antenasEncendidas = false;
          }
          return const LoginPage();
        }
      },
    );
  }
}