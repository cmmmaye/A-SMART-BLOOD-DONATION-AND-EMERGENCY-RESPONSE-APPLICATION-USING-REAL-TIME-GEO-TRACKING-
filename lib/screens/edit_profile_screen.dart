import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../utils/blood_types.dart';
import '../utils/image_storage.dart';
import '../widgets/action_button.dart';
import '../widgets/profile_image.dart';

class EditProfileScreen extends StatefulWidget {
  static const route = 'edit-profile';
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

const kProfileDiameter = 120.0;

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _bloodType = '';
  Map<String, dynamic>? _oldUser;
  bool _isLoading = false;

  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserSession.getCurrentUser();
    if (user != null) {
      setState(() {
        _nameController.text = user['name'] as String? ?? '';
        _emailController.text = user['email'] as String? ?? '';
        _oldUser = user;
        _bloodType = user['blood_type'] as String? ?? 
            Hive.box(ConfigBox.key)
                .get(ConfigBox.bloodType, defaultValue: BloodType.aPos.name) as String;
      });
    } else {
      _bloodType = Hive.box(ConfigBox.key)
          .get(ConfigBox.bloodType, defaultValue: BloodType.aPos.name) as String;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = (_oldUser?['is_admin'] as bool?) ?? false;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _imageRow(),
                  const SizedBox(height: 36),
                  _nameField(),
                  const SizedBox(height: 18),
                  _emailField(),
                  // Only show blood type selector for non-admins
                  if (!isAdmin) ...[
                    const SizedBox(height: 18),
                    _bloodTypeSelector(),
                  ],
                  const SizedBox(height: 36),
                  ActionButton(
                    text: 'Save',
                    callback: _save,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageRow() => InkWell(
        onTap: _getImage,
        borderRadius: BorderRadius.circular(90),
        child: Container(
          width: kProfileDiameter,
          height: kProfileDiameter,
          decoration: const BoxDecoration(
            color: MainColors.accent,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (_image != null)
                Image.file(
                  _image!,
                  fit: BoxFit.cover,
                  height: kProfileDiameter,
                  width: kProfileDiameter,
                )
              else if (_oldUser?['profile_image_url'] != null)
                ProfileImage(
                  imagePath: _oldUser!['profile_image_url'] as String,
                  width: kProfileDiameter,
                  height: kProfileDiameter,
                  fit: BoxFit.cover,
                )
              else
                SvgPicture.asset(IconAssets.donor),
              Container(
                height: 30,
                width: kProfileDiameter,
                color: MainColors.primary,
                child: const Icon(FontAwesomeIcons.upload, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      );

  Widget _nameField() => TextFormField(
        controller: _nameController,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Name',
          prefixIcon: const Icon(FontAwesomeIcons.user),
        ),
      );

  Widget _emailField() => TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Email',
          prefixIcon: const Icon(FontAwesomeIcons.envelope),
        ),
      );

  Widget _bloodTypeSelector() => DropdownButtonFormField<String>(
        value: _bloodType,
        onChanged: (v) => setState(() => _bloodType = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Blood Type',
          prefixIcon: const Icon(FontAwesomeIcons.droplet),
        ),
        items: BloodTypeUtils.bloodTypes
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v),
                ))
            .toList(),
      );

  Future _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }


  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = UserSession.getCurrentUserId();
        if (userId == null) {
          Fluttertoast.showToast(msg: 'Please login to update profile');
          setState(() => _isLoading = false);
          return;
        }

        // Save profile image locally (offline storage)
        String? profileImageUrl;
        if (_image != null) {
          // Save image to local storage
          final savedPath = await ImageStorage.saveImageLocally(_image!, userId);
          if (savedPath != null) {
            profileImageUrl = savedPath;
            
            // Delete old image if it exists and is a local file
            final oldImagePath = _oldUser?['profile_image_url'] as String?;
            if (oldImagePath != null && ImageStorage.isLocalPath(oldImagePath)) {
              await ImageStorage.deleteOldImage(oldImagePath);
            }
          } else {
            Fluttertoast.showToast(
              msg: 'Failed to save image. Please try again.',
              toastLength: Toast.LENGTH_SHORT,
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        final isAdmin = (_oldUser?['is_admin'] as bool?) ?? false;
        final hasNameChange = _nameController.text != (_oldUser?['name'] ?? '');
        final hasEmailChange = _emailController.text != (_oldUser?['email'] ?? '');
        final initialBloodType = _oldUser?['blood_type'] as String? ?? 
            Hive.box(ConfigBox.key)
                .get(ConfigBox.bloodType, defaultValue: BloodType.aPos.name) as String;
        final hasBloodTypeChange = !isAdmin && _bloodType != initialBloodType;

        if (hasNameChange || hasEmailChange || hasBloodTypeChange || profileImageUrl != null) {
          await DatabaseHelper.instance.updateUser(
            id: userId,
            name: hasNameChange ? _nameController.text : null,
            email: hasEmailChange ? _emailController.text : null,
            bloodType: hasBloodTypeChange ? _bloodType : null,
            profileImageUrl: profileImageUrl,
          );

          if (hasBloodTypeChange) {
            Hive.box(ConfigBox.key).put(ConfigBox.bloodType, _bloodType);
          }

          // Reload user data
          await _loadUser();
        }

        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error updating profile: $e');
        Fluttertoast.showToast(msg: 'Something went wrong. Please try again');
      }
      setState(() => _isLoading = false);
    }
  }
}
