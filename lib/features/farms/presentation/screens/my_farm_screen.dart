// lib/features/farms/presentation/screens/my_farm_screen.dart
/// Farm screen for setup and GPS tagging with visible coordinates and address.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/farm_entity.dart';
import '../providers/farm_provider.dart';

class MyFarmScreen extends StatefulWidget {
  const MyFarmScreen({super.key});

  @override
  State<MyFarmScreen> createState() => _MyFarmScreenState();
}

class _MyFarmScreenState extends State<MyFarmScreen> {
  static const String _currentFarmerId = 'demo-farmer-id';
  final TextEditingController _farmNameController = TextEditingController();

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
      provider.loadFarm(_currentFarmerId);
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderMessages);
    _farmNameController.dispose();
    super.dispose();
  }

  void _handleProviderMessages() {
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

  Future<void> _createFarm(FarmProvider provider) async {
    final String name = _farmNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a farm name.')),
      );
      return;
    }

    final FarmEntity farm = provider.createDraftFarm(
      farmerId: _currentFarmerId,
      name: name,
    );
    await provider.saveFarm(farm);
  }

  Future<void> _editFarmName(FarmProvider provider, FarmEntity farm) async {
    final TextEditingController controller = TextEditingController(text: farm.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit farm name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Farm name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == farm.name) {
      return;
    }

    await provider.saveFarm(
      farm.copyWith(name: newName, updatedAt: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProvider>(
      builder: (BuildContext context, FarmProvider provider, Widget? child) {
        if (provider.isLoading && provider.farm == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.farm == null) {
          return _buildSetupState(provider);
        }

        final FarmEntity farm = provider.farm!;
        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _buildMapPlaceholder(farm),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: provider.isTagging ? null : () => provider.tagLocation(context),
                  icon: provider.isTagging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(provider.isTagging ? 'Tagging location...' : 'Tag my farm location'),
                ),
              ),
              const SizedBox(height: 12),
              if (provider.locationTagged) _buildSuccessCard(farm),
              if (provider.locationTagged) const SizedBox(height: 12),
              _buildFarmDetailsCard(provider, farm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetupState(FarmProvider provider) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.terrain, size: 64, color: AppColors.primaryGreen),
              const SizedBox(height: 12),
              const Text(
                'Add your farm',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _farmNameController,
                decoration: const InputDecoration(
                  labelText: 'Farm name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : () => _createFarm(provider),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save farm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(FarmEntity farm) {
    final String coordinates = farm.isTagged
        ? '${farm.latitude!.toStringAsFixed(3)}, ${farm.longitude!.toStringAsFixed(3)}'
        : 'No coordinates tagged yet';

    return Container(
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1B8E3E), Color(0xFF51B26D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Farm Coordinates',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            coordinates,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito Sans',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(FarmEntity farm) {
    final String lat = farm.latitude?.toStringAsFixed(3) ?? '-';
    final String lng = farm.longitude?.toStringAsFixed(3) ?? '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Farm tagged! Lat: $lat | Long: $lng',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito Sans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            farm.address ?? 'Unknown location',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontFamily: 'Nunito Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDetailsCard(FarmProvider provider, FarmEntity farm) {
    final bool tagged = farm.isTagged;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => _editFarmName(provider, farm),
            child: Row(
              children: <Widget>[
                const Text(
                  'Farm name:',
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyText,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    farm.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito Sans',
                      color: AppColors.navyText,
                    ),
                  ),
                ),
                const Icon(Icons.edit, size: 16, color: AppColors.mutedText),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Farm size: ${farm.sizeHa == null ? 'Not provided' : '${farm.sizeHa!.toStringAsFixed(1)} ha'}',
            style: const TextStyle(
              fontFamily: 'Nunito Sans',
              color: AppColors.navyText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Text(
                'GPS status:',
                style: TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagged ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tagged ? 'Tagged' : 'Not tagged yet',
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                    color: tagged ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
