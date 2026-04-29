// lib/features/crops/presentation/screens/my_crops_screen.dart
/// Crop inventory screen showing farmer listings with offline-first CRUD feedback.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/widgets/crop_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../domain/entities/crop_entity.dart';
import '../providers/crop_provider.dart';

class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  CropProvider? _provider;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollForFab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final CropProvider provider = context.read<CropProvider>();
      _provider = provider;
      provider.addListener(_handleProviderEvents);
      final String farmerId = context.read<AuthProvider>().currentUserId;
      if (farmerId.isEmpty) {
        return;
      }
      provider.loadCrops(farmerId);
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderEvents);
    _scrollController
      ..removeListener(_handleScrollForFab)
      ..dispose();
    super.dispose();
  }

  void _handleScrollForFab() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollDirection direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.idle) {
      return;
    }
    if (direction == ScrollDirection.reverse && _showFab) {
      setState(() {
        _showFab = false;
      });
    } else if (direction == ScrollDirection.forward && !_showFab) {
      setState(() {
        _showFab = true;
      });
    }
  }

  void _handleProviderEvents() {
    if (!mounted || _provider == null) {
      return;
    }

    final String? success = _provider!.successMessage;
    if (success != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(success),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      _provider!.clearSuccess();
    }

    final String? error = _provider!.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.errorTerracotta,
            behavior: SnackBarBehavior.floating,
          ),
        );
      _provider!.clearError();
    }
  }

  Future<void> _refreshCrops() async {
    if (!mounted) {
      return;
    }
    final String farmerId = context.read<AuthProvider>().currentUserId;
    if (farmerId.isEmpty) {
      return;
    }
    await context.read<CropProvider>().loadCrops(farmerId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CropProvider, ConnectivityProvider>(
      builder: (
        BuildContext context,
        CropProvider provider,
        ConnectivityProvider connectivityProvider,
        Widget? child,
      ) {
        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: Column(
            children: <Widget>[
              if (!connectivityProvider.isOnline)
                Container(
                  width: double.infinity,
                  color: AppColors.accentAmber.withValues(alpha: 0.18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Cloud is offline. Showing locally saved crops.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      color: AppColors.navyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Expanded(child: _buildBody(provider)),
            ],
          ),
          floatingActionButton: _showFab
              ? FloatingActionButton(
                  heroTag: 'my_crops_fab',
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: AppColors.navyText,
                  tooltip: 'List a crop',
                  onPressed: () => Navigator.pushNamed(context, RouteNames.addCrop),
                  child: const Icon(Icons.add, size: 28),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildBody(CropProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        controller: _scrollController,
        itemCount: 5,
        padding: const EdgeInsets.only(bottom: 100),
        itemBuilder: (BuildContext context, int index) {
          return const ShimmerCropCard();
        },
      );
    }

    if (provider.crops.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _refreshCrops,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 100),
          physics: AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: 120),
            EmptyStateWidget(
              icon: Icons.grass_outlined,
              title: 'No crops listed yet',
              subtitle: 'Tap List Crop (below) or use Add in the bottom bar.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _refreshCrops,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: provider.crops.length,
        padding: const EdgeInsets.only(bottom: 100),
        itemBuilder: (BuildContext context, int index) {
          final CropEntity crop = provider.crops[index];
          return Dismissible(
            key: ValueKey<String>(crop.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorTerracotta,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (DismissDirection direction) async {
              final CropProvider cropProvider = context.read<CropProvider>();
              final bool? shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete crop listing?'),
                        content: Text('Are you sure you want to delete ${crop.name}?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
              if (shouldDelete != true) {
                return false;
              }
              if (!mounted) {
                return false;
              }

              return cropProvider.deleteCrop(crop.id);
            },
            child: CropCard(
              crop: crop,
              index: index,
              layout: CropCardLayout.horizontal,
            )
                .animate(delay: Duration(milliseconds: index * 60))
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
          );
        },
      ),
    );
  }
}
