import 'package:flutter/material.dart';

class Category {
  final String name;
  final int linksCount;
  final IconData icon;

  const Category({
    required this.name,
    required this.linksCount,
    required this.icon,
  });
}
