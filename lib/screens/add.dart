import 'package:flutter/material.dart';
import 'package:linkvault_app/theme/theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddLink extends StatefulWidget {
  const AddLink({super.key});

  @override
  State<AddLink> createState() => _AddLinkState();
}

class _AddLinkState extends State<AddLink> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  List<Map<String, dynamic>> categories = [];

  int? selectedCategoryId;

  bool isLoadingCategories = true;

  Future<void> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Please log in first.');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> apiCategories = data['categories'];

        if (!mounted) return;

        setState(() {
          categories = apiCategories
              .map((category) => Map<String, dynamic>.from(category))
              .toList();

          isLoadingCategories = false;
        });
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load categories: $e')));
    }
  }

  Future<void> addLink() async {
    // Check required fields
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final url = urlController.text.trim();

    if (title.isEmpty || url.isEmpty || selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title, URL, and select a category.'),
        ),
      );
      return;
    }

    // Get the authentication token
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Please log in first.');
      }

      // Send the link to Laravel
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/links'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description.isEmpty ? null : description,
          'url': url,
          'category_id': selectedCategoryId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link added successfully!')),
        );

        // Navigator.pop(context, true);

        setState(() {
          titleController.clear();
          descriptionController.clear();
          urlController.clear();
          selectedCategoryId = null;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to add link.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add link: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Add link',
          style: TextStyle(
            fontSize: 18,
            color: lightColorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(11.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            const Text(
              'Link Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                // label: const Text('Title'),
                hintText: 'Enter Title Link',
                hintStyle: const TextStyle(color: Colors.black26),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black12, // Default border color
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black12, // Default border color
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.title, color: Colors.black38),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                //  label: const Text('Enter a description (optional).'),
                hintText: 'Enter a description (optional).',
                hintStyle: const TextStyle(color: Colors.black26),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black12, // Default border color
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black12, // Default border color
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: Colors.black38,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('URL', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                hintStyle: const TextStyle(color: Colors.black26),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black12, // Default border color
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black12, // Default border color
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.link, color: Colors.black38),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (isLoadingCategories)
              const Center(child: CircularProgressIndicator())
            else if (categories.isEmpty)
              const Text(
                'No categories available. Please create a category first.',
              )
            else
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_outlined),
                  hintText: 'Select a category',
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: (category['id'] as num).toInt(),
                    child: Text(category['name'].toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
              ),

            const SizedBox(height: 20),
            const SizedBox(height: 70),
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
                onPressed: addLink,

                child: const Text('Add Link', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
