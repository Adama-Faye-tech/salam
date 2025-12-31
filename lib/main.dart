import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/equipment_provider.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/logger_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du système de logging
  _setupLogger();

  // Charger les variables d'environnement
  try {
    await dotenv.load(fileName: ".env");
    Log.i('✅ Variables d\'environnement chargées', tag: 'Main');
  } catch (e) {
    Log.e('❌ Erreur chargement .env: $e', tag: 'Main');
  }

  // Initialiser Firebase
  try {
    await Firebase.initializeApp();
    Log.i('✅ Firebase initialisé avec succès', tag: 'Main');
  } catch (e) {
    Log.e('❌ Erreur initialisation Firebase: $e', tag: 'Main');
  }

  Log.i('🚀 Lancement de l\'application...', tag: 'Main');

  runApp(const SALAMApp());
}

/// Configure le système de logging selon l'environnement
void _setupLogger() {
  if (kReleaseMode) {
    // En production, n afficher que les warnings et erreurs
    LoggerService.setMinLevel(LogLevel.warning);
    Log.i('Application en mode PRODUCTION', tag: 'Main');
  } else {
    // En développement, afficher tous les logs
    LoggerService.setMinLevel(LogLevel.debug);
    Log.i('Application en mode DEVELOPPEMENT', tag: 'Main');
  }
}


class SALAMApp extends StatelessWidget {
  const SALAMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
      ],
      child: Consumer2<UserProvider, ThemeProvider>(
        builder: (context, userProvider, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SALAM - Société Agricole Locale pour l\'Amélioration et la Modernisation',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: userProvider.isAuthenticated
                ? const MainScreen()
                : const LoginScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}
