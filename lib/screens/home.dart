import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:linkvault_app/theme/theme.dart';
import 'package:linkvault_app/widgets/custom_scaffold.dart';
import 'package:linkvault_app/screens/category_links.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
final List<Map<String, dynamic>> categories = [];

  bool isLoadingCategories = true;
  Future<Map<String, dynamic>> createCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Please log in first.');
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/categories'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data['category']);
    }

    throw Exception(data['message'] ?? 'Failed to create category.');
  }
  Future<void> fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

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
          categories.clear();

          for (final category in apiCategories) {
            categories.add({
              'id': category['id'],
              'name': category['name'],
              'count': category['links_count'] ?? 0,
              'icon': _getCategoryIcon(category['name']),
            });
          }
        });
      } else {
        throw Exception('Failed to load categories (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load categories: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }
  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'flutter libraries':
        return Icons.code;
      case 'ui/ux resources':
        return Icons.palette_outlined;
      case 'github repositories':
        return Icons.folder_outlined;
      case 'learning resources':
        return Icons.school_outlined;
      case 'work':
        return Icons.work_outline;
      case 'favorites':
        return Icons.favorite_outline;
      default:
        return Icons.folder_outlined;
    }
  }
  void showAddCategoryDialog() {
    
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.folder_outlined;

    final List<IconData> categoryIcons = [
      Icons.folder_outlined,
      Icons.code,
      Icons.palette_outlined,
      Icons.school_outlined,
      Icons.work_outline,
      Icons.book_outlined,
      Icons.favorite_outline,
      Icons.link,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Create Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category Name'),
                    const SizedBox(height: 8),

                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter category name',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Choose an Icon',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categoryIcons.map((icon) {
                        final isSelected = selectedIcon == icon;

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? lightColorScheme.primary.withOpacity(0.12)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? lightColorScheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? lightColorScheme.primary
                                  : Colors.grey.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    nameController.dispose();
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightColorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                 onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a category name'),
                        ),
                      );
                      return;
                    }

                    try {
                      final newCategory = await createCategory(name);

                      if (!mounted) return;

                      setState(() {
                        categories.add({
                          'id': newCategory['id'],
                          'name': newCategory['name'],
                          'count': newCategory['links_count'] ?? 0,
                          'icon': selectedIcon,
                        });
                      });

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Category created successfully!'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Could not create category: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
@override
  void initState() {
    super.initState();
    fetchCategories();
  }
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hi, Mona!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '10 Oct 2026',
                          style: TextStyle(
                            color: Colors.blue[100],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: lightColorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(197, 5, 99, 142),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Search categories...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: showAddCategoryDialog,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color.fromARGB(255, 5, 99, 142),
                          size: 28,
                        ),
                        tooltip: 'Add Category',
                      ),
                    ],
                  ),

                Expanded(
                    child: isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : categories.isEmpty
                        ? const Center(
                            child: Text(
                              'No categories yet. Create your first one!',
                            ),
                          )
                        : ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];

                              return Card(
                                elevation: 1,
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        30,
                                        5,
                                        99,
                                        142,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      category['icon'] as IconData,
                                      color: const Color.fromARGB(
                                        255,
                                        5,
                                        99,
                                        142,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    category['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${category['count']} links',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      // Add edit and delete actions later.
                                    },
                                    icon: const Icon(Icons.more_horiz),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryLinksScreen(
                                              categoryName:
                                                  category['name'] as String,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

