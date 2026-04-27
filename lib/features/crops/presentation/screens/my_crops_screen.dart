// lib/features/crops/presentation/screens/my_crops_screen.dart
/// Crop inventory screen showing farmer listings with offline-first CRUD feedback.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';
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
  // TODO: Replace with authenticated farmer id from auth state.
  static const String _currentFarmerId = 'demo-farmer-id';
  CropProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final CropProvider provider = context.read<CropProvider>();
      _provider = provider;
      provider.addListener(_handleProviderEvents);
      provider.loadCrops(_currentFarmerId);
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderEvents);
    super.dispose();
  }

  void _handleProviderEvents() {
    if (!mounted || _provider == null) {
      return;
    }

    final String? message = _provider!.errorMessage;
    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _provider!.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropProvider>(
      builder: (BuildContext context, CropProvider provider, Widget? child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: _buildBody(provider),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.accentAmber,
            onPressed: () => Navigator.pushNamed(context, RouteNames.addCrop),
            child: const Icon(Icons.add, color: AppColors.navyText),
          ),
        );
      },
    );
  }

  Widget _buildBody(CropProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (BuildContext context, int index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ShimmerLoader(height: 110, borderRadius: 16),
          );
        },
      );
    }

    if (provider.crops.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.grass_outlined,
        title: 'No crops listed yet',
        message: 'Tap + to add your first crop',
      );
    }

    return ListView.builder(
      itemCount: provider.crops.length,
      padding: const EdgeInsets.only(bottom: 96),
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

            return context.read<CropProvider>().deleteCrop(crop.id);
          },
          child: CropCard(
            crop: crop,
            index: index,
          ),
        );
      },
    );
  }
}
