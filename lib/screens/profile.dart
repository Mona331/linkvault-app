import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

    await prefs.setString(
      'profile_image_path',
      selectedImage.path,
    );

    await uploadImage();
  } catch (e) {
    debugPrint('PICK IMAGE ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not select image: $e'),
      ),
    );
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
      Uri.parse(
        'http://10.0.2.2:8000/api/profile/image',
      ),
    );

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile!.path,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    debugPrint('UPLOAD STATUS: ${response.statusCode}');
    debugPrint('UPLOAD RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image uploaded successfully!'),
        ),
      );
    } else {
      throw Exception(
        'Status ${response.statusCode}: ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('UPLOAD ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }
}


@override
void initState() {
  super.initState();
  loadProfileImage();
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
                    : null,
                child: imageFile == null
                    ? const Icon(Icons.person, size: 80)
                    : null,
              ),
            ),
          ),
          SizedBox(height: 30,),
        Expanded(child: Container(
           width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
             // child: ,
        ))
        ],
      ),
    );
  }
}
