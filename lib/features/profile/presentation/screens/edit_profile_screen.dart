import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final ProfileProvider provider = context.read<ProfileProvider>();
    _nameController.text = provider.displayName;
    _phoneController.text = provider.phone;
    _bioController.text = provider.bio;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final String userId = authProvider.currentUserId;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first.'),
          backgroundColor: AppColors.errorTerracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final bool success = await profileProvider.saveProfile(
      userId: userId,
      name: _nameController.text.trim(),
      email: profileProvider.email,
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      profileImageUrl: profileProvider.profileImageUrl,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved!'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(profileProvider.errorMessage ?? 'Failed to save profile.'),
        backgroundColor: AppColors.errorTerracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    if (source == ImageSource.camera) {
      final PermissionStatus status = await Permission.camera.request();
      if (!mounted) {
        return;
      }
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      if (!status.isGranted) {
        return;
      }
    }

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (!mounted || file == null) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    final ProfileProvider provider = context.read<ProfileProvider>();
    await provider.updateImage(File(file.path));
    if (!mounted) {
      return;
    }
    setState(() {
      _isUploadingImage = false;
    });

    if (provider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated!'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppColors.errorTerracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (BuildContext context, ProfileProvider provider, Widget? child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.surfaceMist,
                          backgroundImage: provider.profileImageUrl.isNotEmpty
                              ? NetworkImage(provider.profileImageUrl)
                              : null,
                          child: provider.profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person_outline,
                                  size: 40,
                                  color: AppColors.mutedText,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed:
                              provider.isSaving || _isUploadingImage ? null : _pickProfileImage,
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            _isUploadingImage ? 'Uploading...' : 'Change Profile Photo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (String? value) {
                      final String name = (value ?? '').trim();
                      if (name.isEmpty) {
                        return 'Full name is required';
                      }
                      if (name.length < 2) {
                        return 'Full name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    maxLength: 200,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                      label: Text(provider.isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
