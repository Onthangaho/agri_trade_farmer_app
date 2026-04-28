import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, ConnectivityProvider, SyncProvider>(
      builder: (
        BuildContext context,
        ThemeProvider themeProvider,
        ConnectivityProvider connectivityProvider,
        SyncProvider syncProvider,
        Widget? child,
      ) {
        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          appBar: AppBar(
            backgroundColor: AppColors.primaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SectionCard(
                title: 'Appearance',
                child: DropdownButtonFormField<ThemeMode>(
                  initialValue: themeProvider.themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Theme mode',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  items: const <DropdownMenuItem<ThemeMode>>[
                    DropdownMenuItem<ThemeMode>(
                      value: ThemeMode.system,
                      child: Text('System default'),
                    ),
                    DropdownMenuItem<ThemeMode>(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem<ThemeMode>(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (ThemeMode? mode) {
                    if (mode != null) {
                      themeProvider.setThemeMode(mode);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Connectivity & Sync',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          connectivityProvider.isOnline
                              ? Icons.wifi
                              : Icons.wifi_off_outlined,
                          color: connectivityProvider.isOnline
                              ? AppColors.successGreen
                              : AppColors.errorTerracotta,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          connectivityProvider.isOnline
                              ? 'Online'
                              : 'Offline',
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pending sync items: ${syncProvider.pendingCount}',
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        color: AppColors.navyText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            syncProvider.isSyncing ? null : syncProvider.startSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        icon: syncProvider.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          syncProvider.isSyncing ? 'Syncing...' : 'Sync Now',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Account',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().signOut();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.login,
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorTerracotta,
                      side: const BorderSide(color: AppColors.errorTerracotta),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.navyText,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
