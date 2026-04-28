import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/farm_provider.dart';

class MyFarmScreen extends StatefulWidget {
  const MyFarmScreen({super.key});

  @override
  State<MyFarmScreen> createState() => _MyFarmScreenState();
}

class _MyFarmScreenState extends State<MyFarmScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  FarmProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final FarmProvider provider = context.read<FarmProvider>();
      _provider = provider;
      provider.addListener(_handleProviderMessages);
      final String userId = context.read<AuthProvider>().currentUserId;
      if (userId.isNotEmpty) {
        provider.loadFarm(userId);
      }
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderMessages);
    _farmNameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _handleProviderMessages() {
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

  Future<void> _saveFarm(FarmProvider provider) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String userId = context.read<AuthProvider>().currentUserId;
    if (userId.isEmpty) {
      return;
    }

    final double? size = _sizeController.text.trim().isEmpty
        ? null
        : double.tryParse(_sizeController.text.trim());
    await provider.saveFarm(
      userId,
      _farmNameController.text.trim(),
      size,
    );
  }

  Future<void> _tagFarmLocation(FarmProvider provider) async {
    final String userId = context.read<AuthProvider>().currentUserId;
    if (userId.isEmpty) {
      return;
    }
    await provider.tagLocation(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProvider>(
      builder: (BuildContext context, FarmProvider provider, Widget? child) {
        if (provider.isLoading && !provider.hasFarm) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundCream,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: provider.hasFarm ? _buildFarmDetails(provider) : _buildAddFarmForm(provider),
        );
      },
    );
  }

  Widget _buildAddFarmForm(FarmProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.landscape_outlined,
                size: 80,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Your Farm',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: AppColors.navyText,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _farmNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Farm name',
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Farm name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Farm size (ha) - optional',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: provider.isSaving ? null : () => _saveFarm(provider),
                  icon: provider.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(provider.isSaving ? 'Saving...' : 'Save Farm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmDetails(FarmProvider provider) {
    final String farmName = provider.farmName;
    final String farmAddress = provider.address;
    final double? lat = provider.latitude;
    final double? lng = provider.longitude;
    final bool hasLocation = provider.hasLocation;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.agriculture_outlined, color: AppColors.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  farmName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppColors.navyText,
                  ),
                ),
              ),
              const Icon(Icons.edit_outlined, color: AppColors.mutedText),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (hasLocation)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF6E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Location tagged: ${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  farmAddress.isEmpty ? 'Address not available' : farmAddress,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    color: AppColors.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: provider.isTagging ? null : () => _tagFarmLocation(provider),
                  icon: provider.isTagging
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Re-tag Location'),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Location not tagged',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A6700),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        provider.isTagging ? null : () => _tagFarmLocation(provider),
                    icon: provider.isTagging
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      provider.isTagging
                          ? 'Tagging...'
                          : 'Tag My Farm Location',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
