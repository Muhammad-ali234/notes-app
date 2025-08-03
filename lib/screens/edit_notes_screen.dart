import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/model/notes_model.dart';
import 'package:provider/provider.dart';
import '../provider/notes_provider.dart';
import '../provider/category_provider.dart';
import '../model/category_model.dart';
import 'package:image_picker/image_picker.dart';

class NewNoteScreen extends StatefulWidget {
  final Note? note; // null for new notes, non-null for editing
  
  NewNoteScreen({this.note});
  
  @override
  _NewNoteScreenState createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _lastSaved;
  String? _selectedCategoryId;
  bool _isModified = false;
  Timer? _autosaveTimer;
  List<String> _attachedImages = [];
  
  final FocusNode _contentFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data for edits
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _lastSaved = widget.note?.updatedAt ?? DateTime.now();
    _selectedCategoryId = widget.note?.categoryId;
    
    // Add listeners to detect changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    
    // Set up autosave timer
    _autosaveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isModified) {
        _saveNote();
      }
    });
  }
  
  void _onTextChanged() {
    setState(() {
      _isModified = true;
    });
  }
  
  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;
    
    if (title.isEmpty && content.isEmpty) return;
    
    _lastSaved = DateTime.now();
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    
    try {
      if (widget.note == null) {
        // Create new note
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryId: _selectedCategoryId ?? 'default',
        );
        await notesProvider.addNote(newNote);
      } else {
        // Update existing note
        final updatedNote = Note(
          id: widget.note!.id,
          title: title,
          content: content,
          createdAt: widget.note!.createdAt,
          updatedAt: DateTime.now(),
          categoryId: _selectedCategoryId ?? widget.note!.categoryId,
        );
        await notesProvider.updateNote(updatedNote);
      }
      
      Navigator.pop(context);
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
    }
  }
  
  Future<bool> _onWillPop() async {
    if (_isModified) {
      // Save before leaving
      await _saveNote();
    }
    return true;
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _attachedImages.add(image.path);
        _isModified = true;
      });
      
      // Add image reference to content
      final currentPosition = _contentController.selection.baseOffset;
      final text = _contentController.text;
      final newText = text.substring(0, currentPosition) + 
                     '\n[Image: ${image.name}]\n' + 
                     text.substring(currentPosition);
      
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: currentPosition + '[Image: ${image.name}]'.length + 2,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<CategoryProvider>(context).categories;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _saveNote();
            Navigator.pop(context);
          },
        ),
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _saveNote();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
         
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Last saved ${DateFormat('h:mm a').format(_lastSaved)}',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _applyFormatting(String type) {
    final selection = _contentController.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final text = _contentController.text;
    final start = selection.start;
    final end = selection.end;
    String formatted;
    switch (type) {
      case 'bold':
        formatted = text.replaceRange(start, end, '**${text.substring(start, end)}**');
        break;
      case 'italic':
        formatted = text.replaceRange(start, end, '_${text.substring(start, end)}_');
        break;
      case 'underline':
        formatted = text.replaceRange(start, end, '<u>${text.substring(start, end)}</u>');
        break;
      default:
        formatted = text;
    }
    _contentController.value = _contentController.value.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: start + (type == 'bold' ? 2 : type == 'italic' ? 1 : 3) + (end - start) + (type == 'bold' ? 2 : type == 'italic' ? 1 : 4)),
    );
  }
  
  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.grey[700]),
      tooltip: tooltip,
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(),
      onPressed: onPressed,
    );
  }
  
  String _formatLastSaved() {
    final now = DateTime.now();
    final difference = now.difference(_lastSaved);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday, ${DateFormat('h:mm a').format(_lastSaved)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(_lastSaved);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _autosaveTimer?.cancel();
    super.dispose();
  }
}