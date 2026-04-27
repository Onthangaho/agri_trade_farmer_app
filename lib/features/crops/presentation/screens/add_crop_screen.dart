// lib/features/crops/presentation/screens/add_crop_screen.dart
/// Form screen for creating a crop listing and saving it offline-first.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crop_entity.dart';
import '../providers/crop_provider.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final Uuid _uuid = const Uuid();

  // TODO: Replace with authenticated farmer id from auth state.
  static const String _currentFarmerId = 'demo-farmer-id';

  String _unit = 'kg';
  DateTime? _expiresAt;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _expiresAt = picked;
      _expiryController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final CropProvider provider = context.read<CropProvider>();
    final CropEntity crop = CropEntity(
      id: _uuid.v4(),
      farmerId: _currentFarmerId,
      name: _nameController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unit,
      pricePerUnit: double.parse(_priceController.text.trim()),
      imageUrl: null,
      localImagePath: null,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      listedAt: DateTime.now(),
      expiresAt: _expiresAt,
      status: 'active',
    );

    await provider.saveCrop(crop);
    if (!mounted) {
      return;
    }

    if (provider.errorMessage == null || provider.errorMessage!.contains('offline')) {
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.errorMessage!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropProvider>(
      builder: (BuildContext context, CropProvider provider, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Add Crop Listing')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Crop name'),
                    validator: (String? value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Crop name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (String? value) {
                      final double? parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'kg', child: Text('kg')),
                      DropdownMenuItem<String>(value: 'bags', child: Text('bags')),
                      DropdownMenuItem<String>(value: 'crates', child: Text('crates')),
                      DropdownMenuItem<String>(value: 'litres', child: Text('litres')),
                      DropdownMenuItem<String>(value: 'bunches', child: Text('bunches')),
                    ],
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _unit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price per unit (ZAR)'),
                    validator: (String? value) {
                      final double? parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiryController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Expiry date (optional)',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMist,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Icon(Icons.camera_alt_outlined, color: AppColors.mutedText),
                        const SizedBox(height: 8),
                        const Text('Add photo'),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Photo coming next session'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: provider.isSaving ? null : _submit,
                    child: provider.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('List Crop'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
