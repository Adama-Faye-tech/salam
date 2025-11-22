import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'favorites/favorites_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isAuthenticated = userProvider.isAuthenticated;

    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = const HomeScreen();
        break;
      case 1:
        currentScreen = isAuthenticated ? const OrdersScreen() : const HomeScreen();
        break;
      case 2:
        currentScreen = isAuthenticated ? const FavoritesScreen() : const HomeScreen();
        break;
      case 3:
        currentScreen = isAuthenticated ? const ProfileScreen() : const LoginScreen();
        break;
      default:
        currentScreen = const HomeScreen();
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (!isAuthenticated && (index == 1 || index == 2)) {
            setState(() => _currentIndex = 3);
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Commandes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(isAuthenticated ? Icons.person_outline : Icons.login_outlined),
            activeIcon: Icon(isAuthenticated ? Icons.person : Icons.login),
            label: isAuthenticated ? 'Profil' : 'Connexion',
          ),
        ],
      ),
    );
  }
}
