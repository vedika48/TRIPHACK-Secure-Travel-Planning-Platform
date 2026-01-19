import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travel_agent/screens/explore/explore_screen.dart';
import 'package:travel_agent/services/agent_service.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/home/trip_plan_screen.dart';
import 'providers/trip_provider.dart';
import 'providers/agent_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripPlanningProvider()),
        ChangeNotifierProvider(create: (_) => AgentProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '', // Set to empty string
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue.shade700,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => AuthWrapper(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/chat': (context) => ChatScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/trip-planning': (context) => const TripPlanningScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}