import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/course_model.dart';
import '../widgets/course_card_dynamic.dart';

class EnrolledCoursesScreen extends StatefulWidget {
  const EnrolledCoursesScreen({super.key});

  @override
  State<EnrolledCoursesScreen> createState() => _EnrolledCoursesScreenState();
}

class _EnrolledCoursesScreenState extends State<EnrolledCoursesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Course> _enrolledCourses = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  
  final List<String> _filters = ['All', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Loading enrolled courses for current user...');
      
      // Get all enrollments for current user
      final enrollments = await _firestoreService.getUserEnrollments();
      
      print('📚 Found ${enrollments.length} enrollments');
      
      // Get course details for each enrollment
      List<Course> courses = [];
      for (var enrollment in enrollments) {
        try {
          final course = await _firestoreService.getCourse(enrollment.courseId);
          if (course != null) {
            courses.add(course);
          }
        } catch (e) {
          print('Error loading course ${enrollment.courseId}: $e');
        }
      }
      
      print('✅ Loaded ${courses.length} enrolled courses');
      
      if (mounted) {
        setState(() {
          _enrolledCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading enrolled courses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Course> _getFilteredCourses() {
    if (_selectedFilter == 'All') {
      return _enrolledCourses;
    }
    // You can add progress filtering logic here if needed
    return _enrolledCourses;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _getFilteredCourses();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Enrolled Courses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Banner
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Enrolled',
                  '${_enrolledCourses.length}',
                  Icons.school,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  'In Progress',
                  '${_enrolledCourses.length}',
                  Icons.trending_up,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  'Completed',
                  '0',
                  Icons.check_circle,
                ),
              ],
            ),
          ),
          
          // Filters (optional - you can remove if not needed)
          // SizedBox(
          //   height: 50,
          //   child: ListView.builder(
          //     scrollDirection: Axis.horizontal,
          //     padding: const EdgeInsets.symmetric(horizontal: 20),
          //     itemCount: _filters.length,
          //     itemBuilder: (context, index) {
          //       final filter = _filters[index];
          //       final isSelected = filter == _selectedFilter;
          //       
          //       return Padding(
          //         padding: const EdgeInsets.only(right: 12),
          //         child: FilterChip(
          //           label: Text(filter),
          //           selected: isSelected,
          //           onSelected: (selected) {
          //             setState(() => _selectedFilter = filter);
          //           },
          //           backgroundColor: Colors.grey.shade100,
          //           selectedColor: const Color(0xFF4ECDC4),
          //           labelStyle: TextStyle(
          //             color: isSelected ? Colors.white : Colors.grey.shade700,
          //             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          
          // Course Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              '${filteredCourses.length} ${filteredCourses.length == 1 ? 'Course' : 'Courses'} Enrolled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          
          // Courses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCourses.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadEnrolledCourses,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            return CourseCardDynamic(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No Enrolled Courses Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start learning by enrolling in courses',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/courses');
            },
            icon: const Icon(Icons.explore),
            label: const Text('Browse Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}