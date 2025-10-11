import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditCourseScreen extends StatefulWidget {
  final Course course;
  
  const EditCourseScreen({super.key, required this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  
  bool _isLoading = false;
  late String _selectedCategory;
  late String _selectedLevel;

  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Mathematics',
    'Science',
  ];

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _descriptionController = TextEditingController(text: widget.course.description);
    _durationController = TextEditingController(text: widget.course.duration);
    _selectedCategory = widget.course.category;
    _selectedLevel = widget.course.level;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updates = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'duration': _durationController.text.trim(),
      'category': _selectedCategory,
      'level': _selectedLevel,
    };

    final success = await _firestoreService.updateCourse(widget.course.id, updates);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update course'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Course Title',
                hint: 'Enter course title',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter course description',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              CustomTextField(
                controller: _durationController,
                label: 'Duration',
                hint: 'e.g., 8 weeks',
                prefixIcon: Icons.schedule,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: _levels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                onChanged: (value) => setState(() => _selectedLevel = value!),
              ),
              const SizedBox(height: 40),
              
              CustomButton(
                text: 'Update Course',
                isLoading: _isLoading,
                onPressed: _handleUpdate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}