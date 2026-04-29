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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'shell_main_fab',
        backgroundColor: AppColors.accentAmber,
        foregroundColor: AppColors.navyText,
        elevation: 4,
        tooltip: 'Add crop listing',
        onPressed: _openAddCrop,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _ShellNavItem(
                  label: 'Market',
                  icon: Icons.storefront,
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onTabSelected(0),
                ),
              ),
              Expanded(
                child: _ShellNavItem(
                  label: 'My Crops',
                  icon: Icons.inventory_2,
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onTabSelected(1),
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: _ShellNavItem(
                  label: 'My Farm',
                  icon: Icons.terrain,
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onTabSelected(3),
                ),
              ),
              Expanded(
                child: _ShellNavItem(
                  label: 'Profile',
                  icon: Icons.person,
                  isSelected: _selectedIndex == 4,
                  onTap: () => _onTabSelected(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isSelected ? AppColors.primaryGreen : AppColors.mutedText;
    final Color textColor = isSelected ? AppColors.primaryGreen : AppColors.mutedText;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: isSelected ? 'Poppins' : 'NunitoSans',
              fontWeight: FontWeight.w600,
              fontSize: isSelected ? 12 : 11,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
