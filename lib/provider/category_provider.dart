import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:notesapp/model/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];

  List<Category> get categories => _categories;

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesString = prefs.getString('categories');
    if (categoriesString != null) {
      final List<dynamic> categoriesJson = jsonDecode(categoriesString);
      _categories = categoriesJson.map((json) => Category.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = _categories.map((cat) => cat.toJson()).toList();
    await prefs.setString('categories', jsonEncode(categoriesJson));
  }

  Future<void> addCategory(Category category) async {
    _categories.add(category);
    await saveCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((cat) => cat.id == id);
    await saveCategories();
    notifyListeners();
  }

  Future<void> updateCategory(Category updatedCategory) async {
    final index = _categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index != -1) {
      _categories[index] = updatedCategory;
      await saveCategories();
      notifyListeners();
    }
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}