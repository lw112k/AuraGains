import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../view_models/edit_profile_viewmodel.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Edit Profile'),
          actions: [
            // Save Button in AppBar
            Consumer<EditProfileViewModel>(
              builder: (context, viewModel, child) {
                return viewModel.isSaving
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Color(0xFF0066FF), strokeWidth: 2),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: () => viewModel.saveProfile(context),
                        child: const Text('Save', style: TextStyle(color: Color(0xFF0066FF), fontSize: 16)),
                      );
              },
            ),
          ],
        ),
        body: Consumer<EditProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Avatar Picker
                  GestureDetector(
                    onTap: viewModel.pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF1E1E1E),
                          backgroundImage: viewModel.selectedImage != null
                              ? FileImage(viewModel.selectedImage!) as ImageProvider
                              : (viewModel.currentAvatarUrl != null ? NetworkImage(viewModel.currentAvatarUrl!) : null),
                          child: (viewModel.selectedImage == null && viewModel.currentAvatarUrl == null)
                              ? const Icon(Icons.person, size: 50, color: Colors.white54)
                              : null,
                        ),
                        // Edit icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0066FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Display Name Field
                  TextFormField(
                    controller: viewModel.nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF161616),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Bio Field
                  TextFormField(
                    controller: viewModel.bioController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF161616),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}