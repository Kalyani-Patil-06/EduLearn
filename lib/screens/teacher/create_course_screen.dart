import 'package:flutter/material.dart';
import '/models/course_model.dart';
import '/services/firestore_service.dart';
import '/widgets/custom_button.dart';
import '/widgets/custom_text_field.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  String _selectedCategory = 'Programming';
  String _selectedLevel = 'Beginner';
  String _selectedIcon = 'school';
  String _selectedColor = '6C63FF';

  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Mathematics',
    'Science',
  ];

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  final Map<String, String> _icons = {
    'school': 'school',
    'code': 'data_object_rounded',
    'design': 'design_services_rounded',
    'business': 'campaign_rounded',
    'science': 'psychology_rounded',
    'math': 'functions_rounded',
  };

  final Map<String, String> _colors = {
    'Purple': '6C63FF',
    'Blue': '3B82F6',
    'Green': '10B981',
    'Orange': 'F59E0B',
    'Pink': 'EC4899',
    'Red': 'EF4444',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userData = await _firestoreService.getUserData();
    
    Course newCourse = Course(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      instructor: userData?['name'] ?? 'Teacher',
      instructorId: _firestoreService.currentUserId ?? '',
      duration: _durationController.text.trim(),
      lessons: 0,
      students: 0,
      category: _selectedCategory,
      level: _selectedLevel,
      iconName: _icons[_selectedIcon]!,
      colorValue: _selectedColor,
    );

    final courseId = await _firestoreService.createCourse(newCourse);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (courseId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create course'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Course',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              CustomTextField(
                controller: _titleController,
                label: 'Course Title',
                hint: 'Enter course title',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course title';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter course description',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  if (value.length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Duration Field
              CustomTextField(
                controller: _durationController,
                label: 'Duration',
                hint: 'e.g., 8 weeks, 3 months',
                prefixIcon: Icons.schedule,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 20),

              // Level Dropdown
              const Text(
                'Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                items: _levels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedLevel = value!);
                },
              ),
              const SizedBox(height: 20),

              // Icon Selection
              const Text(
                'Course Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.entries.map((entry) {
                  final isSelected = _selectedIcon == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = entry.key),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF6C63FF).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF6C63FF)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIconData(entry.value),
                        color: isSelected 
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade600,
                        size: 30,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Color Selection
              const Text(
                'Course Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.entries.map((entry) {
                  final isSelected = _selectedColor == entry.value;
                  final color = Color(int.parse('FF${entry.value}', radix: 16));
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = entry.value),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 30)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Create Button
              CustomButton(
                text: 'Create Course',
                isLoading: _isLoading,
                onPressed: _handleCreate,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'data_object_rounded':
        return Icons.data_object_rounded;
      case 'design_services_rounded':
        return Icons.design_services_rounded;
      case 'campaign_rounded':
        return Icons.campaign_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'functions_rounded':
        return Icons.functions_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}