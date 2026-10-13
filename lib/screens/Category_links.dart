import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:linkvault_app/theme/theme.dart';
import 'package:linkvault_app/widgets/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryLinksScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
 // final int linkId;
  //final String linkTitle;
  const CategoryLinksScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
   // required this.linkId,
    //required this.linkTitle,
  });

  @override
  State<CategoryLinksScreen> createState() => _CategoryLinksScreenState();
}

class _CategoryLinksScreenState extends State<CategoryLinksScreen> {
  final List<Map<String, dynamic>> link = [];
  String title = '';
  final TextEditingController searchController = TextEditingController();
  bool isLoadingLinks = true;
  String searchQuery = '';
  Future<void> fetchLinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Please log in first.');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/links'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // We will filter the links by category in the next step.
        final List<dynamic> apiLinks = data['links'];

        final categoryLinks = apiLinks.where((item) {
          return item['category_id'] != null &&
              item['category_id'].toString() == widget.categoryId.toString();
        }).toList();

        if (!mounted) return;

        setState(() {
          link.clear();
          link.addAll(
            categoryLinks.map((item) => Map<String, dynamic>.from(item)),
          );

          isLoadingLinks = false;
        });
      } else {
        throw Exception(
          'Failed to load links: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingLinks = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load links. Please try again.'),
        ),
      );
    }
  }

 
Future<void> renameLink(
  Map<String, dynamic> selectedLink,
  String newTitle,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    throw Exception('Please log in first.');
  }

  final id = selectedLink['id'];

  final response = await http.put(
    Uri.parse('http://10.0.2.2:8000/api/links/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'title': newTitle,
      'url': selectedLink['url'],
      'description': selectedLink['description'],
      'category_id': selectedLink['category_id'],
    }),
  );

  debugPrint('Rename status: ${response.statusCode}');
  debugPrint('Rename response: ${response.body}');

  if (response.statusCode != 200) {
    throw Exception(
      'Status ${response.statusCode}: ${response.body}',
    );
  }
}

  Future<void> deleteLink(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Please log in first.');
    }

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/links/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete link.');
    }
  }

 void showRenameLinkDialog(Map<String, dynamic> selectedLink) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return RenameLinkDialog(
          link: selectedLink,
          onRename: (newTitle) async {
            final rawId = selectedLink['id'];

            if (rawId is! num) {
              throw Exception('Invalid link ID.');
            }

          await renameLink(selectedLink, newTitle);

            if (!mounted) return;

            setState(() {
              selectedLink['title'] = newTitle;
            });
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
                'Delete Link?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to delete '
                '"? This action cannot be undone.',
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
                                content: Text('link ID is missing.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isDeleting = true;
                          });

                          try {
                            await deleteLink((id as num).toInt());

                            if (!mounted) return;

                            setState(() {
                              link.removeWhere((item) => item['id'] == id);
                            });

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Link deleted successfully!'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isDeleting = false;
                            });

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Could not delete Link: $e'),
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
    fetchLinks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLinks = link.where((link) {
      final name = (link['title'] as String).toLowerCase();
      return name.contains(searchQuery);
    }).toList();
    return CustomScaffold(
      // titlet: Text('data'),
      //backgroundColor: Colors.white,
      //appBar: AppBar(title: Text(widget.categoryName),
      //backgroundColor: Colors.white,),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
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
                        hintText: 'Search Links...',
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
            SizedBox(height: 20),
            Expanded(
              child: isLoadingLinks
                  ? const Center(child: CircularProgressIndicator())
                  : link.isEmpty
                  ? const Center(
                      child: Text(
                        'No links yet. Create your first one!',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    )
                  : filteredLinks.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching links found.',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLinks.length,
                      itemBuilder: (context, index) {
                        final link = filteredLinks[index];

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

                            // leading: Container(
                            //   width: 48,
                            //   height: 48,
                            //   decoration: BoxDecoration(
                            //     color: const Color.fromARGB(30, 5, 99, 142),
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),

                            // ),
                            //  leading: Text(link['description'])as String,
                            title: Text(
                              link['title']?.toString() ?? 'Untitled',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Description
                                  if (link['description'] != null &&
                                      link['description']
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        link['description'].toString(),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),

                                  // URL and copy button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,

                                    children: [
                                      Expanded(
                                        child: Text(
                                          link['url']?.toString() ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      //SizedBox(width: 100,),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Copy URL',
                                        onPressed: () async {
                                          final url =
                                              link['url']?.toString() ?? '';

                                          if (url.isNotEmpty) {
                                            await Clipboard.setData(
                                              ClipboardData(text: url),
                                            );

                                            if (!context.mounted) return;

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Link copied successfully!',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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
                                  showRenameLinkDialog(link);
                                } else if (value == 'delete') {
                                  showDeleteCategoryDialog(link);
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
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class RenameLinkDialog extends StatefulWidget {
  final Map<String, dynamic> link;
  final Future<void> Function(String newTitle) onRename;

  const RenameLinkDialog({
    super.key,
    required this.link,
    required this.onRename,
  });

  @override
  State<RenameLinkDialog> createState() => _RenameLinkDialogState();
}

class _RenameLinkDialogState extends State<RenameLinkDialog> {
  late final TextEditingController nameController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.link['title'] as String,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveLink() async {
    final newTitle = nameController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a link title.')),
      );
      return;
    }

    if (newTitle == widget.link['title']) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await widget.onRename(newTitle);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('link renamed successfully!')),
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
          content: Text('Could not renamed link: $e'),
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
        'Rename Link',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: nameController,
        autofocus: true,
        enabled: !isSaving,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Link Title',
          hintText: 'Enter a new title',
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
          onPressed: isSaving ? null : saveLink,
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
