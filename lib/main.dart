import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'services/logger_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du système de logging
  _setupLogger();

  // Lancer l'initialisation Supabase en arrière-plan (ne bloque pas le démarrage)
  Log.i('🚀 Lancement initialisation Supabase (background)...', tag: 'Main');
  SupabaseService.initialize()
      .then((_) {
        Log.i('✅ Supabase initialisé (background)', tag: 'Main');
      })
      .catchError((e, stackTrace) {
        Log.e('❌ Erreur initialisation Supabase (background): $e', tag: 'Main');
        Log.e('Stack trace: $stackTrace', tag: 'Main');
      });

  runApp(const SameApp());
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

class _AppInitializer extends StatefulWidget {
  final Widget child;

  const _AppInitializer({required this.child});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Attendre que Supabase soit complètement initialisé avec timeout
      Log.d('Attente initialisation Supabase...', tag: '_AppInitializer');

      await SupabaseService.onInitializationComplete.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Log.w(
            'Timeout initialisation Supabase, continuation...',
            tag: '_AppInitializer',
          );
          return true;
        },
      );

      Log.success(
        'Supabase initialisé, vérification session...',
        tag: '_AppInitializer',
      );

      if (!mounted) return;

      // Maintenant on peut vérifier la session en toute sécurité
      final userProvider = context.read<UserProvider>();
      await userProvider.checkSession();

      if (!mounted) return;

      setState(() {
        _initialized = true;
      });

      Log.success('Initialisation complète', tag: '_AppInitializer');
    } catch (e) {
      Log.e('Erreur initialisation: $e', tag: '_AppInitializer');

      if (!mounted) return;

      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.agriculture, size: 80, color: Colors.green[700]),
                const SizedBox(height: 24),
                const Text(
                  '   daal ak jàmm ci SALAM',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

class SameApp extends StatelessWidget {
  const SameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: _AppInitializer(
        child: Consumer2<UserProvider, ThemeProvider>(
          builder: (context, userProvider, themeProvider, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title:
                  'SALAM - Société Agricole Locale pour l\'Amélioration et la Modernisation',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: userProvider.isAuthenticated
                  ? const MainScreen()
                  : const LoginScreen(),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
                '/forgot-password': (context) => const ForgotPasswordScreen(),
                '/reset-password': (context) => const ResetPasswordScreen(),
                '/main': (context) => const MainScreen(),
                '/chat': (context) {
                  final args =
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>?;
                  return ChatScreen(
                    providerId: args?['providerId'] as String? ?? '',
                    providerName: args?['providerName'] as String? ?? '',
                    providerAvatar: args?['providerAvatar'] as String?,
                  );
                },
              },
            );
          },
        ),
      ),
    );
  }
}
