// lib/shared/screens/main_shell_screen.dart
/// Main authenticated shell with bottom navigation, FAB, and side drawer.

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';
import 'placeholder_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const <Widget>[
    AppPlaceholderScreen(
      title: 'Market',
      message: 'Browse active crop listings from local farmers.',
    ),
    AppPlaceholderScreen(
      title: 'My Crops',
      message: 'Manage your crop inventory and sync status here.',
    ),
    AppPlaceholderScreen(
      title: 'Add Crop',
      message: 'Use the FAB to create a new crop listing.',
    ),
    AppPlaceholderScreen(
      title: 'My Farm',
      message: 'Store farm details, location, and profile information.',
    ),
    AppPlaceholderScreen(
      title: 'Profile',
      message: 'Update your farmer profile and preferences.',
    ),
  ];

  void _onTabSelected(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, RouteNames.addCrop);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openRoute(String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgriTrade')),
      drawer: Drawer(
        child: Container(
          color: AppColors.navyText,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.primaryGreenDark),
                  accountName: const Text('AgriTrade Farmer'),
                  accountEmail: const Text('farmer@agritrade.co.za'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppColors.accentAmber,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSecondary),
                  ),
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () => _openRoute(RouteNames.settings),
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.message),
                  title: const Text('Messages'),
                  onTap: () => _openRoute(RouteNames.messages),
                ),
                const Spacer(),
                const Divider(color: Colors.white24),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () => Navigator.pushNamed(context, RouteNames.login),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _tabs[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, RouteNames.addCrop),
        icon: const Icon(Icons.add),
        label: const Text('Add Crop'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'My Crops'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.terrain), label: 'My Farm'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
