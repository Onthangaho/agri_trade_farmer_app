// lib/features/profile/presentation/screens/profile_screen.dart
/// Farmer profile screen showing account details and edit action.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../auth/domain/entities/farmer_entity.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Replace with authenticated farmer id from AuthProvider once auth domain is wired.
  static const String _defaultFarmerId = 'demo-farmer-id';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ProfileProvider>().loadProfile(_defaultFarmerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (BuildContext context, ProfileProvider provider, Widget? child) {
        if (provider.isLoading) {
          return _buildLoadingState();
        }

        final FarmerEntity? farmer = provider.farmer;
        if (farmer == null) {
          return const Center(
            child: Text('No profile found yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _ProfileHeader(farmer: farmer),
            const SizedBox(height: 16),
            _StatsRow(
              // TODO: Replace placeholder values with profile/farm/listing use case data.
              activeListings: 0,
              farmName: 'Farm not set',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, RouteNames.editProfile),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'My Listings',
              child: Text(
                '0 active listings',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Account',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _AccountRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: farmer.email,
                  ),
                  const SizedBox(height: 12),
                  _AccountRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: farmer.phone ?? 'Not set',
                  ),
                ],
              ),
            ),
            if (provider.errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: AppColors.errorTerracotta),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        ShimmerLoader(height: 140, borderRadius: 20),
        SizedBox(height: 16),
        ShimmerLoader(height: 70, borderRadius: 16),
        SizedBox(height: 16),
        ShimmerLoader(height: 48, borderRadius: 12),
        SizedBox(height: 16),
        ShimmerLoader(height: 120, borderRadius: 16),
        SizedBox(height: 12),
        ShimmerLoader(height: 120, borderRadius: 16),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.farmer});

  final FarmerEntity farmer;

  @override
  Widget build(BuildContext context) {
    final String initials = farmer.name.trim().isEmpty
        ? 'F'
        : farmer.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((String element) => element.isNotEmpty)
            .take(2)
            .map((String e) => e[0].toUpperCase())
            .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryGreen,
            backgroundImage: farmer.profileImageUrl != null && farmer.profileImageUrl!.isNotEmpty
                ? NetworkImage(farmer.profileImageUrl!)
                : null,
            child: farmer.profileImageUrl == null || farmer.profileImageUrl!.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  farmer.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: AppColors.navyText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  farmer.email,
                  style: const TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.activeListings, required this.farmName});

  final int activeListings;
  final String farmName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SectionCard(
            title: 'Active Listings',
            child: Text(
              '$activeListings',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SectionCard(
            title: 'Farm Name',
            child: Text(
              farmName,
              style: const TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 14,
                color: AppColors.navyText,
              ),
            ),
          ),
        ),
      ],
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  fontFamily: 'Nunito Sans',
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontSize: 16,
                  color: AppColors.navyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
