import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../services/pdf_service.dart';
import '../services/search_service.dart';
import '../services/cache_service.dart';
import '../models/course_model.dart';
import 'package:intl/intl.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Assignment> _assignments = [];
  List<Assignment> _filteredAssignments = [];
  Map<String, Submission?> _submissions = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'dueDate';
  bool _showOnlyUrgent = false;
  List<String> _searchSuggestions = [];
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _searchSuggestions = SearchService.getSearchSuggestions(_assignments, _searchQuery);
      _applyFilters();
    });
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Loading assignments...');
      
      // Try to load from cache first
      final cachedAssignments = await CacheService.getCachedAssignments();
      final isCacheExpired = await CacheService.isCacheExpired();
      
      if (cachedAssignments != null && !isCacheExpired) {
        print('📱 Using cached assignments');
        setState(() {
          _assignments = cachedAssignments;
          _isLoading = false;
          _applyFilters();
        });
      }
      
      // Try to fetch fresh data
      print('🌐 Fetching fresh assignments...');
      final assignments = await _firestoreService.getUserAssignments();
      print('✅ Got ${assignments.length} assignments');
      
      // Process assignments
      Map<String, Submission?> submissions = {};
      List<Assignment> processedAssignments = [];
      
      for (var assignment in assignments) {
        try {
          final status = await _firestoreService.getSubmissionStatus(assignment.id);
          processedAssignments.add(Assignment(
            id: assignment.id,
            courseId: assignment.courseId,
            title: assignment.title,
            description: assignment.description,
            dueDate: assignment.dueDate,
            totalMarks: assignment.totalMarks,
            createdBy: assignment.createdBy,
            status: status ?? 'pending',
          ));
          submissions[assignment.id] = null;
        } catch (e) {
          print('Error processing assignment ${assignment.id}: $e');
          // Add assignment with default status
          processedAssignments.add(assignment);
          submissions[assignment.id] = null;
        }
      }
      
      // Cache the fresh data
      try {
        await CacheService.cacheAssignments(processedAssignments);
      } catch (e) {
        print('Cache error: $e');
      }
      
      if (mounted) {
        setState(() {
          _assignments = processedAssignments;
          _submissions = submissions;
          _isLoading = false;
          _isOffline = false;
          _applyFilters();
        });
        print('✅ Assignments loaded successfully');
      }
    } catch (e) {
      print('❌ Error loading assignments: $e');
      
      // Try to load from cache if network fails
      try {
        final cachedAssignments = await CacheService.getCachedAssignments();
        if (cachedAssignments != null && mounted) {
          setState(() {
            _assignments = cachedAssignments;
            _isLoading = false;
            _isOffline = true;
            _applyFilters();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Showing cached data - limited connectivity'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadAssignments,
              ),
            ),
          );
          return;
        }
      } catch (cacheError) {
        print('Cache error: $cacheError');
      }
      
      // If all else fails, show error
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to load assignments. Please check your connection.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAssignments,
            ),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Assignment> filtered = _assignments;
    
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((assignment) => assignment.status == _selectedFilter.toLowerCase())
          .toList();
    }
    
    // Apply advanced search filter
    if (_searchQuery.isNotEmpty) {
      filtered = SearchService.searchAssignments(filtered, _searchQuery);
    }
    
    if (_showOnlyUrgent) {
      filtered = filtered
          .where((assignment) => _getAssignmentPriority(assignment) == 'High')
          .toList();
    }
    
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'priority':
          return _getPriorityValue(b) - _getPriorityValue(a);
        case 'title':
          return a.title.compareTo(b.title);
        case 'dueDate':
        default:
          return a.dueDate.compareTo(b.dueDate);
      }
    });
    
    _filteredAssignments = filtered;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'submitted':
        return const Color(0xFF6C63FF);
      case 'graded':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_outlined;
      case 'submitted':
        return Icons.check_circle_outline;
      case 'graded':
        return Icons.grade_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _getAssignmentPriority(Assignment assignment) {
    final daysUntilDue = assignment.dueDate.difference(DateTime.now()).inDays;
    final isHighMarks = assignment.totalMarks >= 50;
    
    if (daysUntilDue < 0) return 'Overdue';
    if (daysUntilDue <= 1) return 'High';
    if (daysUntilDue <= 3 && isHighMarks) return 'High';
    if (daysUntilDue <= 7) return 'Medium';
    return 'Low';
  }

  int _getPriorityValue(Assignment assignment) {
    switch (_getAssignmentPriority(assignment)) {
      case 'Overdue': return 4;
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 0;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Overdue': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.blue;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assignments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Offline',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          Consumer<ThemeService>(
            builder: (context, themeService, child) => IconButton(
              onPressed: themeService.toggleTheme,
              icon: Icon(
                themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: const Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
                onTap: _exportToPDF,
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'dueDate',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Due Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.priority_high, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Priority'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.title, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Title'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value != 'export') {
                setState(() {
                  _sortBy = value;
                  _applyFilters();
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Advanced Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search assignments, descriptions, status...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchSuggestions = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
                if (_searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Wrap(
                      spacing: 8,
                      children: _searchSuggestions.map((suggestion) => 
                        GestureDetector(
                          onTap: () {
                            _searchController.text = suggestion;
                            _onSearchChanged();
                          },
                          child: Chip(
                            label: Text(suggestion),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
              ],
            ),
          ),
          
          // Statistics Card
          _buildStatsCard(),
          
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Pending'),
                _buildFilterChip('Submitted'),
                _buildFilterChip('Graded'),
                _buildUrgentToggle(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Assignments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssignments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAssignments,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _filteredAssignments.length,
                          itemBuilder: (context, index) {
                            final assignment = _filteredAssignments[index];
                            return _buildAssignmentCard(assignment);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalAssignments = _assignments.length;
    final pendingCount = _assignments.where((a) => a.status == 'pending').length;
    final urgentCount = _assignments.where((a) => _getAssignmentPriority(a) == 'High').length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
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
        children: [
          _buildStatItem('Total', totalAssignments.toString(), Icons.assignment),
          _buildStatItem('Pending', pendingCount.toString(), Icons.pending),
          _buildStatItem('Urgent', urgentCount.toString(), Icons.priority_high),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
      ),
    );
  }

  Widget _buildUrgentToggle() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.priority_high, size: 16),
            SizedBox(width: 4),
            Text('Urgent'),
          ],
        ),
        selected: _showOnlyUrgent,
        onSelected: (selected) {
          setState(() {
            _showOnlyUrgent = selected;
            _applyFilters();
          });
        },
        backgroundColor: Colors.orange.shade50,
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: _showOnlyUrgent ? Colors.white : Colors.orange.shade700,
          fontWeight: _showOnlyUrgent ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _showOnlyUrgent ? Colors.orange : Colors.orange.shade200,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
            _applyFilters();
          });
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
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final daysUntilDue = assignment.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0 && assignment.status == 'pending';
    final statusColor = _getStatusColor(assignment.status);
    final priority = _getAssignmentPriority(assignment);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: priority == 'High' || priority == 'Overdue' 
            ? Border.all(color: _getPriorityColor(priority), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showAssignmentDetails(assignment);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and priority
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(assignment.status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPriorityColor(priority),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(priority),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  assignment.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Footer with due date and marks
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue 
                          ? 'Overdue by ${-daysUntilDue} days'
                          : daysUntilDue == 0 
                              ? 'Due today'
                              : 'Due in $daysUntilDue days',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${assignment.totalMarks} marks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Quick Actions for pending assignments
                if (assignment.status == 'pending')
                  Row(
                    children: [
                      _buildQuickAction(
                        'Remind Me',
                        Icons.notifications_outlined,
                        () => _setReminder(assignment),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        'Mark Important',
                        Icons.star_outline,
                        () => _toggleImportant(assignment),
                      ),
                      const Spacer(),
                      _buildQuickAction(
                        'Submit',
                        Icons.upload_outlined,
                        () => _showAssignmentDetails(assignment),
                        isPrimary: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF6C63FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isPrimary ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
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
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No assignments found for "$_searchQuery"'
                : _selectedFilter != 'All'
                    ? 'No ${_selectedFilter.toLowerCase()} assignments'
                    : 'No assignments yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try searching with different keywords'
                : 'New assignments will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetails(Assignment assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              assignment.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Due Date',
                              DateFormat('MMM dd, yyyy').format(assignment.dueDate),
                              Icons.schedule,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailItem(
                              'Total Marks',
                              '${assignment.totalMarks}',
                              Icons.grade,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(
                        'Status',
                        assignment.status.toUpperCase(),
                        _getStatusIcon(assignment.status),
                        color: _getStatusColor(assignment.status),
                      ),
                      const SizedBox(height: 24),
                      if (assignment.status == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to submission screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit Assignment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color ?? Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _setReminder(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${assignment.title}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleImportant(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${assignment.title} marked as important'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _exportToPDF() async {
    try {
      final file = await PdfService.generateAssignmentReport(_filteredAssignments);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF exported to ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              // You can add file opening logic here
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}