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
                  onTap: _logout,
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
