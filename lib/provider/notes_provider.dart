import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:notesapp/model/notes_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  
  List<Note> get notes => _notes;
  
  NotesProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString('notes');
    if (notesString != null) {
      final List<dynamic> notesJson = jsonDecode(notesString);
      _notes = notesJson.map((json) => Note.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = _notes.map((note) => note.toJson()).toList();
    await prefs.setString('notes', jsonEncode(notesJson));
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      await saveNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await saveNotes();
    notifyListeners();
  }
  
  Future<void> deleteNotesByCategory(String categoryId) async {
    _notes.removeWhere((n) => n.categoryId == categoryId);
    await saveNotes();
    notifyListeners();
  }
  
  List<Note> getNotesByCategory(String categoryId) {
    return _notes.where((note) => note.categoryId == categoryId).toList();
  }
  
  List<Note> searchNotes(String query) {
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
             note.content.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}