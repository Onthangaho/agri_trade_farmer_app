import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
  final TextEditingController _expiryDateController = TextEditingController();

  final List<String> _units = <String>['kg', 'bags', 'crates', 'litres', 'bunches'];
  final ImagePicker _picker = ImagePicker();

  String _selectedUnit = 'kg';
  DateTime? _expiryDate;
  File? _selectedImageFile;
  String? _localImagePath;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bool proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              'Camera needed',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            content: const Text(
              'AgriTrade uses your camera so buyers can see your crops clearly.',
              style: TextStyle(fontFamily: 'NunitoSans'),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;

    if (!proceed) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final PermissionStatus status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      if (!status.isGranted) {
        return;
      }

      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) {
        return;
      }

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        '${file.path}_compressed.jpg',
        quality: 80,
        minWidth: 800,
        minHeight: 800,
      );

      if (!mounted) {
        return;
      }

      if (compressed != null) {
        final File compressedFile = File(compressed.path);
        final int sizeInBytes = await compressedFile.length();

        // Ensure mobile demo uploads remain lightweight and reliable.
        if (sizeInBytes > 200 * 1024) {
          final XFile? tighterCompressed = await FlutterImageCompress.compressAndGetFile(
            compressed.path,
            '${compressed.path}_200kb.jpg',
            quality: 65,
            minWidth: 720,
            minHeight: 720,
          );
          if (tighterCompressed != null) {
            setState(() {
              _selectedImageFile = File(tighterCompressed.path);
              _localImagePath = tighterCompressed.path;
            });
            return;
          }
        }

        setState(() {
          _selectedImageFile = compressedFile;
          _localImagePath = compressed.path;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _expiryDate = picked;
      _expiryDateController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  Future<void> _listCrop() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();

    final String farmerId = context.read<AuthProvider>().currentUserId;
    if (farmerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    final CropEntity crop = CropEntity(
      id: const Uuid().v4(),
      farmerId: farmerId,
      name: _nameController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      unit: _selectedUnit,
      pricePerUnit: double.parse(_priceController.text.trim()),
      imageUrl: null,
      localImagePath: _localImagePath,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      listedAt: DateTime.now(),
      expiresAt: _expiryDate,
      status: 'active',
    );

    final CropProvider cropProvider = context.read<CropProvider>();
    final bool success = await cropProvider.saveCrop(crop);
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crop listed successfully!',
            style: TextStyle(fontFamily: 'NunitoSans'),
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cropProvider.errorMessage ?? 'Failed',
          style: const TextStyle(fontFamily: 'NunitoSans'),
        ),
        backgroundColor: AppColors.errorTerracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropProvider>(
      builder: (BuildContext context, CropProvider provider, Widget? child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          appBar: AppBar(
            backgroundColor: AppColors.primaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Add Crop Listing',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Crop name'),
                    validator: (String? value) {
                      final String text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Crop name is required';
                      }
                      if (text.length < 2) {
                        return 'Crop name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (String? value) {
                      final double? parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Quantity must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units
                        .map(
                          (String unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedUnit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price per unit (ZAR)'),
                    validator: (String? value) {
                      final double? parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    maxLength: 200,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiryDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Expiry date (optional)',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickExpiryDate,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMist,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_selectedImageFile == null)
                          Semantics(
                            label: 'Take photo of crop',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: _isPickingImage ? null : _pickImage,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 140),
                                side: const BorderSide(color: AppColors.primaryGreenLight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isPickingImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              label: const Text('Add Photo'),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImageFile!,
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (_selectedImageFile != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Take photo of crop',
                            button: true,
                            child: TextButton.icon(
                              onPressed: _isPickingImage ? null : _pickImage,
                              icon: _isPickingImage
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              label: const Text('Change photo'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed:
                          provider.isSaving || _isPickingImage ? null : _listCrop,
                      icon: provider.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: Text(provider.isSaving ? 'Listing...' : 'List Crop'),
                    ),
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
