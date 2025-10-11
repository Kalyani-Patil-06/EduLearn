import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/course_model.dart';
import 'package:intl/intl.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEnrolled = false;
  bool _isLoading = false;
  UserEnrollment? _enrollment;
  List<Assignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
    _loadAssignments();
  }

  Future<void> _checkEnrollment() async {
    final enrolled = await _firestoreService.isEnrolledInCourse(widget.course.id);
    final enrollment = await _firestoreService.getCourseEnrollment(widget.course.id);
    
    if (mounted) {
      setState(() {
        _isEnrolled = enrolled;
        _enrollment = enrollment;
      });
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final assignmentStream = _firestoreService.getCourseAssignmentsStream(widget.course.id);
      final assignments = await assignmentStream.first;
      if (mounted) {
        setState(() => _assignments = assignments);
      }
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  Future<void> _handleEnroll() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final success = await _firestoreService.enrollInCourse(widget.course.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully enrolled in ${widget.course.title}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        await _checkEnrollment();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enroll. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Enrollment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'phone_android':
      case 'phone_android_rounded':
        return Icons.phone_android_rounded;
      case 'design_services':
      case 'design_services_rounded':
        return Icons.design_services_rounded;
      case 'data_object':
      case 'data_object_rounded':
        return Icons.data_object_rounded;
      case 'campaign':
      case 'campaign_rounded':
        return Icons.campaign_rounded;
      case 'psychology':
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'functions':
      case 'functions_rounded':
        return Icons.functions_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(widget.course.colorValue);
    final icon = _getIconFromName(widget.course.iconName);
    final progress = _enrollment?.progress ?? 0.0;
    final completedLessons = _enrollment?.completedLessons ?? 0;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.course.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.course.level,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('About This Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(widget.course.description, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6)),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.schedule_rounded, 'Duration', widget.course.duration, const Color(0xFF6C63FF))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard(Icons.play_circle_outline_rounded, 'Lessons', '${widget.course.lessons}', const Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.people_outline_rounded, 'Students', '${widget.course.students}', const Color(0xFFF59E0B))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard(Icons.school_outlined, 'Level', widget.course.level, const Color(0xFFEC4899))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Instructor
                  const Text('Instructor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.person, size: 32, color: color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.course.instructor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Expert Instructor', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress (if enrolled)
                  if (_isEnrolled) ...[
                    const Text('Your Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Course Completion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Completed: $completedLessons/${widget.course.lessons} lessons', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/course-learning', arguments: widget.course);
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(progress > 0 ? 'Continue Learning' : 'Start Learning'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Assignments
                  if (_isEnrolled && _assignments.isNotEmpty) ...[
                    const Text('Course Assignments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ..._assignments.map((assignment) => _buildAssignmentCard(assignment, color)),
                    const SizedBox(height: 24),
                  ],
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: _isEnrolled ? null : FloatingActionButton.extended(
        onPressed: _isLoading ? null : _handleEnroll,
        icon: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : const Icon(Icons.check_circle_rounded),
        label: Text(_isLoading ? 'Enrolling...' : 'Enroll Now'),
        backgroundColor: color,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment, Color color) {
    final daysUntilDue = assignment.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(assignment.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(assignment.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: isOverdue ? Colors.red : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                isOverdue ? 'Overdue' : 'Due in $daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'}',
                style: TextStyle(fontSize: 12, color: isOverdue ? Colors.red : Colors.grey.shade600, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
              ),
              const Spacer(),
              Text('${assignment.totalMarks} marks', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}