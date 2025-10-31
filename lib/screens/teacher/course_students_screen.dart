import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/firestore_service.dart';

class CourseStudentsScreen extends StatefulWidget {
  final Course course;
  
  const CourseStudentsScreen({super.key, required this.course});

  @override
  State<CourseStudentsScreen> createState() => _CourseStudentsScreenState();
}

class _CourseStudentsScreenState extends State<CourseStudentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    print('🔍 Loading students for course: ${widget.course.id}');
    print('📚 Course name: ${widget.course.title}');
    print('📊 Course shows ${widget.course.students} students enrolled');
    
    final students = await _firestoreService.getEnrolledStudents(widget.course.id);
    
    print('✅ Loaded ${students.length} actual STUDENT users (teachers excluded)');
    
    // Also get the actual count to verify
    final actualCount = await _firestoreService.getCourseStudentCount(widget.course.id);
    print('🔢 Verified count from database: $actualCount students');
    
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
      
      // Show warning if counts don't match
      if (students.length != widget.course.students) {
        print('⚠️ WARNING: Course shows ${widget.course.students} students but only ${students.length} actual students found');
        print('💡 This might mean teachers/instructors are being counted in the course.students field');
      }
    }
  }

  Future<void> _fixStudentCount() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Student Count'),
        content: Text(
          'This will update the student count from ${widget.course.students} to ${_students.length}.\n\n'
          'This happens when teachers test enrollment. The count will now show only actual students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Fix Count'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Fixing student count...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final success = await _firestoreService.fixCourseStudentCount(widget.course.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Student count fixed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh to show updated count
        _loadStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to fix student count'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enrolled Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Show fix button if counts don't match
          if (_students.length != widget.course.students && !_isLoading)
            IconButton(
              icon: const Icon(Icons.build_circle_outlined),
              onPressed: _fixStudentCount,
              tooltip: 'Fix Student Count',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  child: Column(
                    children: [
                      // Stats Card
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5A52E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total Students',
                              '${_students.length}',
                              Icons.people,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(
                              'Active',
                              '${_students.length}',
                              Icons.check_circle,
                            ),
                          ],
                        ),
                      ),
                      
                      // Students List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final enrollment = student['enrollment'] as UserEnrollment;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.all(16),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                                  child: Text(
                                    _getInitials(student['name']),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            student['email'],
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (student['studentId'] != null && student['studentId'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ID: ${student['studentId']}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getProgressColor(enrollment.progress).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getProgressColor(enrollment.progress).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${(enrollment.progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getProgressColor(enrollment.progress),
                                    ),
                                  ),
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildDetailRow(
                                          'Progress',
                                          '${(enrollment.progress * 100).toInt()}%',
                                          Icons.trending_up,
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: enrollment.progress,
                                            minHeight: 10,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _getProgressColor(enrollment.progress),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDetailRow(
                                          'Completed Lessons',
                                          '${enrollment.completedLessons}/${widget.course.lessons}',
                                          Icons.check_circle,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDetailRow(
                                          'Enrolled On',
                                          _formatDate(enrollment.enrolledAt),
                                          Icons.calendar_today,
                                        ),
                                        if (enrollment.lastAccessedAt != null) ...[
                                          const SizedBox(height: 12),
                                          _buildDetailRow(
                                            'Last Accessed',
                                            _formatDate(enrollment.lastAccessedAt!),
                                            Icons.access_time,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
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
            'No Students Enrolled Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Only students who have enrolled in this course will appear here. Teachers and instructors are excluded.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // Debug info
          if (widget.course.students > 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    'Note: This course shows ${widget.course.students} enrollments, but they may include teachers or instructors who tested the enrollment.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}