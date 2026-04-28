// lib/shared/screens/main_shell_screen.dart
/// Main authenticated shell with bottom navigation, FAB, and side drawer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/crops/presentation/screens/add_crop_screen.dart';
import '../../features/crops/presentation/screens/my_crops_screen.dart';
import '../../features/farms/presentation/screens/my_farm_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../routes/route_names.dart';
import '../widgets/sync_status_badge.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const <Widget>[
    MarketplaceScreen(),
    MyCropsScreen(),
    AddCropScreen(),
    MyFarmScreen(),
    ProfileScreen(),
  ];

  void _openAddCrop() {
    Navigator.pushNamed(context, RouteNames.addCrop);
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      _openAddCrop();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openRoute(String routeName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }

  void _logout() {
    context.read<AuthProvider>().signOut();
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final String name = user?.displayName ?? 'AgriTrade Farmer';
    final String email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriTrade'),
        actions: const <Widget>[
          SyncStatusBadge(),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: AppColors.navyText,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.primaryGreenDark),
                  accountName: Text(name),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppColors.accentAmber,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSecondary),
                  ),
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Marketplace'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(0);
                  },
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.grass_outlined),
                  title: const Text('My Crops'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(1);
                  },
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('My Farm'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(3);
                  },
                ),
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(4);
                  },
                ),
                const Divider(color: Colors.white24),
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
                ListTile(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _tabs[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'main_add_crop_fab',
        elevation: 4,
        onPressed: _openAddCrop,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'List Crop',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
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
