// lib/shared/screens/main_shell_screen.dart
/// Main authenticated shell with bottom navigation, FAB, and side drawer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/crops/presentation/screens/my_crops_screen.dart';
import '../../features/farms/presentation/screens/my_farm_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../routes/route_names.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/sync_status_badge.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  /// Index 2 is the bottom-nav Add action only (opens a route); body never shows it.
  final List<Widget> _tabs = const <Widget>[
    MarketplaceScreen(),
    MyCropsScreen(),
    SizedBox.shrink(),
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

  Future<void> _logout() async {
    final bool shouldLogout = await showLogoutConfirmationDialog(context);
    if (!shouldLogout || !mounted) {
      return;
    }
    final AuthProvider? authProvider = context.read<AuthProvider?>();
    if (authProvider != null) {
      try {
        await authProvider.signOut();
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
          ),
        );
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider?>()?.currentUser;
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.mutedText,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'NunitoSans',
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'My Crops'),
          BottomNavigationBarItem(
            icon: _AddNavIcon(),
            activeIcon: _AddNavIcon(isActive: true),
            label: 'Add',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.terrain), label: 'My Farm'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _AddNavIcon extends StatelessWidget {
  const _AddNavIcon({this.isActive = false});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryGreen : AppColors.accentAmber,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add,
        size: 20,
        color: isActive ? Colors.white : AppColors.navyText,
      ),
    );
  }
}
