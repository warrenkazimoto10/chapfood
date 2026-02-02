import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'config/supabase_config.dart';
import 'config/mapbox_config.dart';
import 'services/session_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_wizard_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/active_delivery_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/revenue_history_screen.dart';
import 'models/order_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ Impossible de charger le fichier .env: $e');
  }

  // Initialiser Supabase
  await SupabaseConfig.initialize();

  // Initialiser SessionService
  await SessionService.initialize();

  // Initialiser Mapbox
  try {
    final accessToken = MapboxConfig.accessToken;
    if (accessToken.isNotEmpty) {
      MapboxOptions.setAccessToken(accessToken);
      print('✅ Mapbox initialisé avec succès');
    } else {
      print('⚠️ MAPBOX_ACCESS_TOKEN non trouvé dans .env');
    }
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation de Mapbox: $e');
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ChapFoodDriverApp());
}

class ChapFoodDriverApp extends StatelessWidget {
  const ChapFoodDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'ChapFood Livreur',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = SessionService.isLoggedIn;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToRegister = state.matchedLocation == '/signup-wizard';

    // Si l'utilisateur est connecté et essaie d'accéder au login/register, rediriger vers home
    if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
      return '/home';
    }

    // Si l'utilisateur n'est pas connecté et essaie d'accéder à home, rediriger vers login
    if (!isLoggedIn && state.matchedLocation == '/home') {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/signup-wizard',
      builder: (context, state) => const SignupWizardScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/active-delivery',
      builder: (context, state) {
        final order = state.extra as OrderModel?;
        print('📍 Route /active-delivery - Order extra: ${order?.id}');
        if (order == null) {
          print('⚠️ Aucune commande passée, redirection vers dashboard');
          // Rediriger vers le dashboard si pas de commande
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/home');
            }
          });
          return const DashboardScreen();
        }
        print('✅ Affichage de ActiveDeliveryScreen pour commande #${order.id}');
        return ActiveDeliveryScreen(order: order);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/revenue-history',
      builder: (context, state) => const RevenueHistoryScreen(),
    ),
  ],
);
