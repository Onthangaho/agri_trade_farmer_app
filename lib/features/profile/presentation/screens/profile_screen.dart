import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/widgets/logout_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../crops/presentation/providers/crop_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final String userId = context.read<AuthProvider>().currentUserId;
      if (userId.isNotEmpty) {
        context.read<ProfileProvider>().loadProfile(userId);
        context.read<CropProvider>().loadCrops(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProfileProvider, CropProvider, ConnectivityProvider>(
      builder: (
        BuildContext context,
        ProfileProvider profileProvider,
        CropProvider cropProvider,
        ConnectivityProvider connectivityProvider,
        Widget? child,
      ) {
        final int activeListings = cropProvider.crops
            .where((crop) => crop.status.toLowerCase() == 'active')
            .length;

        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: Column(
            children: <Widget>[
              if (!connectivityProvider.isOnline)
                Container(
                  width: double.infinity,
                  color: AppColors.accentAmber.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Cloud is offline. Showing locally available profile data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      color: AppColors.navyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              _HeaderSection(provider: profileProvider),
              Expanded(
                child: profileProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _StatsCard(
                              totalCrops: cropProvider.crops.length,
                              activeListings: activeListings,
                            ),
                            const SizedBox(height: 14),
                            _InfoCard(provider: profileProvider),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final AuthProvider authProvider =
                                      context.read<AuthProvider>();
                                  final ProfileProvider profileProvider =
                                      context.read<ProfileProvider>();
                                  final String userId = authProvider.currentUserId;
                                  await Navigator.of(context).pushNamed(
                                    RouteNames.editProfile,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  if (userId.isNotEmpty) {
                                    await profileProvider.loadProfile(userId);
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.errorTerracotta,
                                  side: const BorderSide(
                                    color: AppColors.errorTerracotta,
                                  ),
                                ),
                                onPressed: () async {
                                  final AuthProvider authProvider =
                                      context.read<AuthProvider>();
                                  final NavigatorState navigator =
                                      Navigator.of(context);
                                  final ScaffoldMessengerState messenger =
                                      ScaffoldMessenger.of(context);
                                  final bool shouldLogout =
                                      await showLogoutConfirmationDialog(context);
                                  if (!shouldLogout || !mounted) {
                                    return;
                                  }
                                  try {
                                    await authProvider.signOut();
                                  } catch (_) {
                                    if (!mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not sign out. Please try again.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (!mounted) {
                                    return;
                                  }
                                  navigator.pushNamedAndRemoveUntil(
                                    RouteNames.login,
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.provider});

  final ProfileProvider provider;

  String _initials(String fullName) {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'AF';
    }
    return parts.take(2).map((value) => value[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = provider.profileImageUrl;
    final ImageProvider<Object>? avatarImage = _profileImageProvider(imageUrl);
    return Container(
      width: double.infinity,
      color: AppColors.primaryGreen,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primaryGreenLight,
            backgroundImage: avatarImage,
            child: imageUrl.isEmpty
                ? Text(
                    _initials(provider.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            provider.displayName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            provider.email,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? _profileImageProvider(String value) {
    if (value.isEmpty) {
      return null;
    }
    if (value.startsWith('data:image')) {
      final int index = value.indexOf(',');
      if (index <= 0) {
        return null;
      }
      try {
        return MemoryImage(base64Decode(value.substring(index + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(value);
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.totalCrops, required this.activeListings});

  final int totalCrops;
  final int activeListings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatItem(
              label: 'My Crops',
              value: '$totalCrops',
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: AppColors.surfaceMist,
          ),
          Expanded(
            child: _StatItem(
              label: 'Active Listings',
              value: '$activeListings',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.provider});

  final ProfileProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: provider.displayName,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: provider.phone.isEmpty ? 'Not set' : provider.phone,
            isMuted: provider.phone.isEmpty,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.info_outline,
            label: 'Bio',
            value: provider.bio.isEmpty ? 'Not set' : provider.bio,
            isMuted: provider.bio.isEmpty,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: AppColors.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 15,
                  color: isMuted ? AppColors.mutedText : AppColors.navyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
