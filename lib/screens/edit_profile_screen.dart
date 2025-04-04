// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final user = await context.read<ProfileService>().getProfile(userId);
    if (user != null) {
      setState(() {
        _nameController.text = user.fullName;
        _phoneController.text = user.phoneNumber;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await context.read<StorageService>().uploadProfileImage(
            userId,
            _imageFile!);
      }

      // Récupérer d'abord l'utilisateur actuel pour conserver les autres propriétés
      final currentUser = await context.read<ProfileService>().getProfile(userId);
      if (currentUser != null) {
        await context.read<ProfileService>().updateProfile(
          UserModel(
            uid: userId,
            email: currentUser.email,
            fullName: _nameController.text,
            photoUrl: photoUrl ?? currentUser.photoUrl,
            role: currentUser.role,
            phoneNumber: _phoneController.text,
            preferences: currentUser.preferences,
            createdAt: currentUser.createdAt,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour du profil')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier le profil'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : null,
                        child: _imageFile == null
                            ? Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Champ requis' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}