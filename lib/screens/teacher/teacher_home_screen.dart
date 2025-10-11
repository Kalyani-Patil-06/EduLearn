import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/auth_service.dart';
import '/services/firestore_service.dart';
import '/widgets/feature_card.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String teacherName = 'Teacher';
  bool _isLoading = true;
  Map<String, int> _stats = {'courses': 0, 'students': 0, 'assignments': 0};

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    
    try {
      final userData = await _firestoreService.getUserData();
      final stats = await _firestoreService.getTeacherStats();
      
      if (mounted) {
        setState(() {
          teacherName = userData?['name'] ?? 'Teacher';
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading teacher data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTeacherData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $teacherName! 👨‍🏫',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your courses and students',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Featured Banner
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Courses',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _stats['courses']! > 0 
                                          ? 'You have ${_stats['courses']} active courses'
                                          : 'Create your first course',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/teacher-courses');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF6C63FF),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Manage Courses'),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.book_rounded,
                                size: 80,
                                color: Colors.white24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Quick Access
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Feature Cards Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            FeatureCard(
                              title: 'My Courses',
                              icon: Icons.school_rounded,
                              color: const Color(0xFF6C63FF),
                              onTap: () {
                                Navigator.pushNamed(context, '/teacher-courses');
                              },
                            ),
                            FeatureCard(
                              title: 'Create Course',
                              icon: Icons.add_circle_rounded,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                Navigator.pushNamed(context, '/create-course');
                              },
                            ),
                            FeatureCard(
                              title: 'Assignments',
                              icon: Icons.assignment_rounded,
                              color: const Color(0xFFF59E0B),
                              onTap: () {
                                Navigator.pushNamed(context, '/teacher-assignments');
                              },
                            ),
                            FeatureCard(
                              title: 'My Profile',
                              icon: Icons.person_rounded,
                              color: const Color(0xFFEC4899),
                              onTap: () {
                                Navigator.pushNamed(context, '/teacher-profile');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Stats Section
                        const Text(
                          'Your Stats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Courses',
                                '${_stats['courses']}',
                                Icons.book_rounded,
                                const Color(0xFF6C63FF),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Students',
                                '${_stats['students']}',
                                Icons.people_rounded,
                                const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Assignments',
                                '${_stats['assignments']}',
                                Icons.assignment_rounded,
                                const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Rating',
                                '4.8',
                                Icons.star_rounded,
                                const Color(0xFFEC4899),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}