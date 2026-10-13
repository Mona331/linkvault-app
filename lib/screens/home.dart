import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  String name = '';
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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
      body: jsonEncode({'name': name}), //converts the Dart map into JSON
    );

    final data = jsonDecode(
      response.body,
    ); //The server sends a response, usually as JSON.

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data['category']);
      //201 means the resource was created.,the function returns the category information to the code that called it.
    }

    throw Exception(data['message'] ?? 'Failed to create category.');
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString('name') ?? 'User';
    });
  }

  Future<void> renameCategory(int id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Please log in first.');
    }

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/api/categories/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    debugPrint('Rename status: ${response.statusCode}');
    debugPrint('Rename response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    debugPrint('Updated category: ${data['category']}');
  }

  Future<void> deleteCategory(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Please log in first.');
    }

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/categories/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete category.');
    }
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
        final data = jsonDecode(
          response.body,
        ); //converts the response from JSON into Dart data.
        final List<dynamic> apiCategories =
            data['categories']; //retrieves the list of categories from the categories key.

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

  void showRenameCategoryDialog(Map<String, dynamic> category) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return RenameCategoryDialog(
          category: category,
          onRename: (newName) async {
            final rawId = category['id'];

            if (rawId is! num) {
              throw Exception('Invalid category ID.');
            }

            await renameCategory(rawId.toInt(), newName);

            if (!mounted) return;

            setState(() {
              category['name'] = newName;
            });
          },
        );
      },
    );
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

  void showDeleteCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Delete Category?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to delete '
                '"${category['name']}"? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final id = category['id'];

                          if (id == null) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Category ID is missing.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isDeleting = true;
                          });

                          try {
                            await deleteCategory((id as num).toInt());

                            if (!mounted) return;

                            setState(() {
                              categories.removeWhere(
                                (item) => item['id'] == id,
                              );
                            });

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Category deleted successfully!'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isDeleting = false;
                            });

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Could not delete category: $e'),
                              ),
                            );
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Yes, Delete'),
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
    loadUsername();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = categories.where((category) {
      final name = (category['name'] as String).toLowerCase();
      return name.contains(searchQuery);
    }).toList();
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
                        Text(
                          'Hi, $name !',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('d MMM yyyy').format(DateTime.now()),
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
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.trim().toLowerCase();
                            });
                          },
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'Clear search',
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
                        : filteredCategories.isEmpty
                        ? const Center(
                            child: Text('No matching categories found.'),
                          )
                        : ListView.builder(
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];

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
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz),
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'rename') {
                                        showRenameCategoryDialog(category);
                                      } else if (value == 'delete') {
                                        showDeleteCategoryDialog(category);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Rename'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                   Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryLinksScreen(
                                              categoryId: int.parse(
                                                category['id'].toString(),
                                              ),
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

class RenameCategoryDialog extends StatefulWidget {
  final Map<String, dynamic> category;
  final Future<void> Function(String newName) onRename;

  const RenameCategoryDialog({
    super.key,
    required this.category,
    required this.onRename,
  });

  @override
  State<RenameCategoryDialog> createState() => _RenameCategoryDialogState();
}

class _RenameCategoryDialogState extends State<RenameCategoryDialog> {
  late final TextEditingController nameController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.category['name'] as String,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveCategory() async {
    final newName = nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }

    if (newName == widget.category['name']) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await widget.onRename(newName);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category renamed successfully!')),
      );
    } catch (e, stackTrace) {
      debugPrint('RENAME ERROR: $e');
      debugPrint('RENAME STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not rename category: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Rename Category',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: nameController,
        autofocus: true,
        enabled: !isSaving,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Category Name',
          hintText: 'Enter a new name',
          prefixIcon: const Icon(Icons.edit_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : saveCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
