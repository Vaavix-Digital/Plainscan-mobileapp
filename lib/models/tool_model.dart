import 'package:flutter/material.dart';

class ToolModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String categoryId;
  final String? category;
  final bool? isFree;

  const ToolModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.categoryId,
    this.category,
    this.isFree,
  });
}