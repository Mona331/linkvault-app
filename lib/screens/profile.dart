import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:linkvault_app/theme/theme.dart';
import 'package:linkvault_app/widgets/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? imageFile;
  bool isUploading = false;
  String? profileImageUrl;

Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  try {
    if (token != null && token.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Logout status: ${response.statusCode}');
      debugPrint('Logout response: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed. Please try again.'),
          ),
        );

        return;
      }
    }

    // Clear local login data after successful logout.
    await prefs.remove('token');
    await prefs.remove('id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('isLogin');

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/welcome',
      (route) => false,
    );
  } catch (e) {
    debugPrint('Logout error: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not connect to the server.'),
      ),
    );
  }
}


  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      final selectedImage = File(picked.path);

      if (!mounted) return;

      setState(() {
        imageFile = selectedImage;
      });

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('profile_image_path', selectedImage.path);

      await uploadImage();
    } catch (e) {
      debugPrint('PICK IMAGE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select image: $e')));
    }
  }

  Future<void> changeEmail({
    required String currentEmail,
    required String newEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Please log in again.');
      }

      final response = await http
          .put(
            Uri.parse('http://10.0.2.2:8000/api/profile/email'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_email': currentEmail,
              'email': newEmail,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('CHANGE EMAIL STATUS: ${response.statusCode}');
      debugPrint('CHANGE EMAIL RESPONSE: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await prefs.setString('email', newEmail);

        if (!mounted) return;

        setState(() {
          email = newEmail;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email changed successfully!')),
        );
      } else {
        throw Exception(data['message'] ?? 'Could not change email.');
      }
    } catch (e) {
      debugPrint('CHANGE EMAIL ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Please log in again.');
      }

      final response = await http
          .put(
            Uri.parse('http://10.0.2.2:8000/api/profile/password'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('CHANGE PASSWORD STATUS: ${response.statusCode}');
      debugPrint('CHANGE PASSWORD RESPONSE: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
      } else {
        throw Exception(data['message'] ?? 'Could not change password.');
      }
    } catch (e) {
      debugPrint('CHANGE PASSWORD ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> uploadImage() async {
    if (imageFile == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      debugPrint('Token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        throw Exception('No login token found. Please log in again.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/profile/image'),
      );

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile!.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('UPLOAD STATUS: ${response.statusCode}');
      debugPrint('UPLOAD RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image uploaded successfully!')),
        );
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  String name = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadProfileImage();
    getUserData();
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    final imagePath = prefs.getString('profile_image_path');

    if (imagePath == null || imagePath.isEmpty) return;

    final file = File(imagePath);

    if (await file.exists() && mounted) {
      setState(() {
        imageFile = file;
      });
    }
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      debugPrint('No authentication token found.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('User status: ${response.statusCode}');
      debugPrint('User response: ${response.body}');

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);

        final String? imagePath = user['profile_image'];

        String? imageUrl;

        if (imagePath != null && imagePath.isNotEmpty) {
          imageUrl = imagePath.startsWith('http')
              ? imagePath
              : 'http://10.0.2.2:8000/storage/${imagePath.replaceFirst(RegExp(r'^storage/'), '')}';
        }

        if (!mounted) return;

        setState(() {
          name = user['name'] ?? '';
          email = user['email'] ?? '';
          profileImageUrl = imageUrl;
        });

        await prefs.setString('username', name);
        await prefs.setString('email', email);
      } else {
        debugPrint('Failed to load user profile.');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 80,

                backgroundImage: imageFile != null
                    ? FileImage(imageFile!)
                    : (profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : null),

                child: imageFile == null && profileImageUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),

                  const SizedBox(height: 15),

                  Text(
                    name,
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      color: lightColorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        email,
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: 4,),
                        IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          final currentEmailController =
                              TextEditingController();
                          final newEmailController = TextEditingController();

                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Change Email'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: currentEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Current Email',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    TextField(
                                      controller: newEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'New Email',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final currentEmail =
                                          currentEmailController.text.trim();
                                      final newEmail = newEmailController.text
                                          .trim();

                                      if (currentEmail.isEmpty ||
                                          newEmail.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill in both fields.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (newEmail == currentEmail) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Enter a different email.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.pop(dialogContext);

                                      await changeEmail(
                                        currentEmail: currentEmail,
                                        newEmail: newEmail,
                                      );

                                      currentEmailController.dispose();
                                      newEmailController.dispose();
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                

                  const SizedBox(height: 20),

                ElevatedButton(
                  
                    onPressed: () {
                      final currentPasswordController = TextEditingController();
                      final newPasswordController = TextEditingController();

                      showDialog(
                        
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('Change Password'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: currentPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Current Password',
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: newPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'New Password',
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final currentPassword =
                                      currentPasswordController.text;
                                  final newPassword =
                                      newPasswordController.text;

                                  if (currentPassword.isEmpty ||
                                      newPassword.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in both fields.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (newPassword.length < 8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'New password must be at least 8 characters.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(dialogContext);

                                  await changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword,
                                  );

                                  currentPasswordController.dispose();
                                  newPasswordController.dispose();
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Change Password'),
                  ),
                  SizedBox(height: 20,),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightColorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: logout,

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Logout',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: 10,),
                          Icon(
                            Icons.logout,
                            color:Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
