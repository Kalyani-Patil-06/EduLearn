import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';

class CourseLearningScreen extends StatefulWidget {
  final Course course;

  const CourseLearningScreen({super.key, required this.course});

  @override
  State<CourseLearningScreen> createState() => _CourseLearningScreenState();
}

class _CourseLearningScreenState extends State<CourseLearningScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserEnrollment? _enrollment;
  
  // SAMPLE VIDEOS - Replace YouTube links later
  final List<Map<String, String>> sampleVideos = [
    {
      'title': 'Introduction to the Course',
      'duration': '10 min',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Replace with real link
    },
    {
      'title': 'Getting Started - Basics',
      'duration': '15 min',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Replace with real link
    },
    {
      'title': 'Understanding Core Concepts',
      'duration': '20 min',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Replace with real link
    },
    {
      'title': 'Practical Examples',
      'duration': '25 min',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Replace with real link
    },
    {
      'title': 'Advanced Topics',
      'duration': '18 min',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Replace with real link
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    final enrollment = await _firestoreService.getCourseEnrollment(widget.course.id);
    if (mounted) {
      setState(() => _enrollment = enrollment);
    }
  }

  Future<void> _playVideo(String url, int index) async {
    final Uri uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open video')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(widget.course.colorValue);
    final progress = _enrollment?.progress ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(20),
            color: color.withOpacity(0.1),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          
          // Videos List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sampleVideos.length,
              itemBuilder: (context, index) {
                final video = sampleVideos[index];
                final isCompleted = _enrollment?.completedLessonIds.contains('lesson_$index') ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted ? color.withOpacity(0.5) : Colors.grey.shade200,
                      width: isCompleted ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _playVideo(video['url']!, index),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Video Thumbnail/Icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isCompleted ? color : color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  isCompleted ? Icons.check_circle : Icons.play_circle_filled,
                                  color: isCompleted ? Colors.white : color,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Video Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lesson ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    video['title']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        video['duration']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (isCompleted) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Completed',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Play Icon
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}