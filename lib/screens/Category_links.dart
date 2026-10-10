import 'package:flutter/material.dart';

class CategoryLinksScreen extends StatelessWidget {
  final String categoryName;

  const CategoryLinksScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Flutter Documentation'),
            subtitle: const Text('docs.flutter.dev'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open the saved link later.
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Flutter Packages'),
            subtitle: const Text('pub.dev'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open the saved link later.
            },
          ),
        ],
      ),
    );
  }
}
