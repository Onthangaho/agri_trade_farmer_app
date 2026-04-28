// lib/features/marketplace/presentation/screens/marketplace_screen.dart
//Marketplace screen for browsing active crop listings across all farmers.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/crop_card.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../crops/domain/entities/crop_entity.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _filters = <String>[
    'All',
    'Maize',
    'Tomatoes',
    'Potatoes',
    'Cabbage',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Provider.of<MarketplaceProvider?>(context, listen: false)?.loadListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileProvider? profileProvider = context.watch<ProfileProvider?>();
    final MarketplaceProvider? provider = context.watch<MarketplaceProvider?>();
    final String farmerName = profileProvider?.farmer?.name ?? 'Farmer';

    if (provider == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: RefreshIndicator(
        onRefresh: provider.loadListings,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildHeader(farmerName),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildSearch(provider),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: _filters.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String value = _filters[index];
                    final bool isSelected = (provider.selectedUnit ?? 'All') == value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(value),
                        selected: isSelected,
                        onSelected: (_) => provider.filterByUnit(value),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildStats(provider.listings.length),
              ),
            ),
            if (provider.isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: const SliverChildBuilderDelegate(
                    _buildShimmerItem,
                    childCount: 6,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                ),
              )
            else if (provider.filteredListings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(provider),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final CropEntity crop = provider.filteredListings[index];
                      return CropCard(
                        crop: crop,
                        index: index,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.cropDetail,
                            arguments: crop,
                          );
                        },
                      )
                          .animate(delay: Duration(milliseconds: index * 60))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
                    },
                    childCount: provider.filteredListings.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildShimmerItem(BuildContext context, int index) {
    return const ShimmerCropCard();
  }

  Widget _buildHeader(String farmerName) {
    final DateTime now = DateTime.now();
    final String date = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Good morning, $farmerName',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.navyText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Nunito Sans',
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.eco, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'AgriTrade',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.navyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearch(MarketplaceProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.search('');
                },
                icon: const Icon(Icons.close),
              )
            : null,
        hintText: 'Search crops...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStats(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count listings available today',
        style: const TextStyle(
          fontFamily: 'Nunito Sans',
          color: Color(0xFF166534),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty(MarketplaceProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_outlined, size: 66, color: AppColors.mutedText.withValues(alpha: 0.8)),
            const SizedBox(height: 10),
            Text(
              "No crops found for '${provider.searchQuery}'",
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.navyText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _searchController.clear();
                provider.search('');
              },
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}
