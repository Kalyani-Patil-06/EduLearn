import 'package:flutter/material.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Programming',
    'Design',
    'Business',
    'Mathematics',
  ];

  final List<Map<String, dynamic>> _courses = [
    {
      'id': '1',
      'title': 'Flutter Development',
      'description': 'Learn to build beautiful cross-platform mobile apps with Flutter and Dart.',
      'instructor': 'Dr. Sarah Johnson',
      'duration': '12 weeks',
      'lessons': 48,
      'students': 1250,
      'progress': 0.65,
      'category': 'Programming',
      'level': 'Intermediate',
      'icon': Icons.phone_android_rounded,
      'color': const Color(0xFF6C63FF),
    },
    {
      'id': '2',
      'title': 'UI/UX Design Fundamentals',
      'description': 'Master the principles of user interface and user experience design.',
      'instructor': 'Prof. Michael Chen',
      'duration': '8 weeks',
      'lessons': 32,
      'students': 980,
      'progress': 0.30,
      'category': 'Design',
      'level': 'Beginner',
      'icon': Icons.design_services_rounded,
      'color': const Color(0xFFEC4899),
    },
    {
      'id': '3',
      'title': 'Data Structures & Algorithms',
      'description': 'Deep dive into essential computer science concepts and problem-solving.',
      'instructor': 'Dr. Emily Rodriguez',
      'duration': '16 weeks',
      'lessons': 64,
      'students': 2100,
      'progress': 0.45,
      'category': 'Programming',
      'level': 'Advanced',
      'icon': Icons.data_object_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'id': '4',
      'title': 'Digital Marketing',
      'description': 'Learn strategies to grow your business online with modern marketing techniques.',
      'instructor': 'Prof. David Thompson',
      'duration': '10 weeks',
      'lessons': 40,
      'students': 1500,
      'progress': 0.0,
      'category': 'Business',
      'level': 'Beginner',
      'icon': Icons.campaign_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': '5',
      'title': 'Machine Learning Basics',
      'description': 'Introduction to machine learning concepts, algorithms, and applications.',
      'instructor': 'Dr. Lisa Wang',
      'duration': '14 weeks',
      'lessons': 56,
      'students': 1800,
      'progress': 0.20,
      'category': 'Programming',
      'level': 'Intermediate',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': '6',
      'title': 'Calculus I',
      'description': 'Fundamental concepts of limits, derivatives, and integrals.',
      'instructor': 'Prof. Robert Anderson',
      'duration': '12 weeks',
      'lessons': 48,
      'students': 950,
      'progress': 0.0,
      'category': 'Mathematics',
      'level': 'Beginner',
      'icon': Icons.functions_rounded,
      'color': const Color(0xFF3B82F6),
    },
  ];

  List<Map<String, dynamic>> get _filteredCourses {
    if (_selectedCategory == 'All') {
      return _courses;
    }
    return _courses.where((course) => course['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Courses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
              );
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: const Color(0xFF6C63FF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Course Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${_filteredCourses.length} ${_filteredCourses.length == 1 ? 'Course' : 'Courses'} Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Courses List
          Expanded(
            child: _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No courses found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      return CourseCard(
                        course: course,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/course-detail',
                            arguments: course,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Browse all courses feature coming soon!')),
          );
        },
        icon: const Icon(Icons.explore_rounded),
        label: const Text('Explore'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }
}