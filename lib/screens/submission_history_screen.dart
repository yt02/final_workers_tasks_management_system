import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/submission.dart';
import 'edit_submission_screen.dart';

class SubmissionHistoryScreen extends StatefulWidget {
  final int workerId;
  final Map<String, dynamic> workerData;

  const SubmissionHistoryScreen({
    super.key,
    required this.workerId,
    required this.workerData,
  });

  @override
  _SubmissionHistoryScreenState createState() => _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen>
    with TickerProviderStateMixin {
  List<Submission> _submissions = [];
  List<Submission> _filteredSubmissions = [];
  bool _isLoading = true;
  String? _error;
  Set<int> _expandedCards = <int>{}; // Track which cards are expanded

  // Enhanced UI state
  String _selectedFilter = 'all'; // all, completed, pending, overdue
  String _selectedSort = 'newest'; // newest, oldest, title
  String _searchQuery = '';
  bool _showFilters = false;

  // Animation controllers
  late AnimationController _filterAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _filterAnimation;
  late Animation<double> _statsAnimation;

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutBack,
    );

    _fetchSubmissions();
    _statsAnimationController.forward();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _statsAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.submissionsUrl),
        body: {
          'worker_id': widget.workerId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _submissions = (data['submissions'] as List)
                .map((submission) => Submission.fromJson(submission))
                .toList();
            _applyFiltersAndSort();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['error'] ?? 'Failed to load submissions';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'overdue':
        return Icons.error;
      default:
        return Icons.pending;
    }
  }

  // Enhanced filtering and sorting methods
  void _applyFiltersAndSort() {
    List<Submission> filtered = List.from(_submissions);

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((submission) =>
          submission.taskStatus.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((submission) =>
          submission.taskTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          submission.submissionText.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
        break;
      case 'title':
        filtered.sort((a, b) => a.taskTitle.compareTo(b.taskTitle));
        break;
    }

    _filteredSubmissions = filtered;
  }

  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFiltersAndSort();
    });
  }

  void _updateSort(String sort) {
    setState(() {
      _selectedSort = sort;
      _applyFiltersAndSort();
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSort();
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  // Enhanced statistics calculation
  Map<String, int> _getStatistics() {
    final completed = _submissions.where((s) => s.taskStatus.toLowerCase() == 'completed').length;
    final pending = _submissions.where((s) => s.taskStatus.toLowerCase() == 'pending').length;
    final overdue = _submissions.where((s) => s.taskStatus.toLowerCase() == 'overdue').length;

    return {
      'total': _submissions.length,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    };
  }

  // Get recent activity summary
  String _getRecentActivitySummary() {
    if (_submissions.isEmpty) return 'No recent activity';

    final now = DateTime.now();
    final recentSubmissions = _submissions.where((s) {
      final daysDiff = now.difference(s.submittedAt).inDays;
      return daysDiff <= 7;
    }).length;

    if (recentSubmissions == 0) return 'No submissions this week';
    return '$recentSubmissions submissions this week';
  }

  // Get performance indicator
  String _getPerformanceIndicator() {
    final stats = _getStatistics();
    if (stats['total']! == 0) return 'No data';

    final completionRate = (stats['completed']! / stats['total']! * 100).round();

    if (completionRate >= 90) return 'Excellent';
    if (completionRate >= 75) return 'Good';
    if (completionRate >= 50) return 'Average';
    return 'Needs Improvement';
  }

  // Get performance color based on completion rate
  Color _getPerformanceColor(int completionRate) {
    if (completionRate >= 90) return Colors.green.shade600;
    if (completionRate >= 75) return Colors.blue.shade600;
    if (completionRate >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  // Enhanced UI Components
  Widget _buildStatisticsHeader() {
    final stats = _getStatistics();
    final completionRate = stats['total']! > 0
        ? (stats['completed']! / stats['total']! * 100).round()
        : 0;

    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Compact header with enhanced information
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.indigo.shade600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPerformanceColor(completionRate).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getPerformanceIndicator(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getPerformanceColor(completionRate),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_getRecentActivitySummary()} • $completionRate% complete',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quick total display with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 14,
                              color: Colors.indigo.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${stats['total']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Compact statistics grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(child: _buildCompactStatCard('Completed', stats['completed']!, Colors.green, Icons.check_circle_outline)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildCompactStatCard('Pending', stats['pending']!, Colors.orange, Icons.pending_outlined)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildCompactStatCard('Overdue', stats['overdue']!, Colors.red, Icons.error_outline)),
                    ],
                  ),
                ),

                // Enhanced progress section with quick insights
                if (stats['total']! > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      children: [
                        // Progress bar with percentage
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: completionRate / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getPerformanceColor(completionRate)
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPerformanceColor(completionRate).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$completionRate%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getPerformanceColor(completionRate),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Quick action insights
                        if (stats['overdue']! > 0 || stats['pending']! > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: stats['overdue']! > 0
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: stats['overdue']! > 0
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.orange.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  stats['overdue']! > 0 ? Icons.warning_amber : Icons.info_outline,
                                  size: 14,
                                  color: stats['overdue']! > 0 ? Colors.red.shade600 : Colors.orange.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stats['overdue']! > 0
                                      ? '${stats['overdue']} overdue tasks need attention'
                                      : '${stats['pending']} tasks pending completion',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: stats['overdue']! > 0 ? Colors.red.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatCard(String label, int count, MaterialColor color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: 'Search submissions...',
                prefixIcon: Icon(Icons.search, color: Colors.indigo.shade400),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.indigo.shade400),
                        onPressed: () {
                          _searchController.clear();
                          _updateSearch('');
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _showFilters ? Icons.filter_list_off : Icons.filter_list,
                        color: Colors.indigo.shade400,
                      ),
                      onPressed: _toggleFilters,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter controls
          AnimatedBuilder(
            animation: _filterAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _filterAnimation,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status filter
                      Text(
                        'Filter by Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('All', 'all'),
                          _buildFilterChip('Completed', 'completed'),
                          _buildFilterChip('Pending', 'pending'),
                          _buildFilterChip('Overdue', 'overdue'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sort options
                      Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildSortChip('Newest First', 'newest'),
                          _buildSortChip('Oldest First', 'oldest'),
                          _buildSortChip('By Title', 'title'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _updateFilter(value),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.indigo.withValues(alpha: 0.2),
      checkmarkColor: Colors.indigo.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _selectedSort == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _updateSort(value),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.cyan.withValues(alpha: 0.2),
      checkmarkColor: Colors.cyan.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.cyan.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedFilter != 'all'
                    ? Icons.search_off
                    : Icons.history,
                size: 64,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'No Matching Submissions'
                  : 'No Submissions Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                _searchQuery.isNotEmpty || _selectedFilter != 'all'
                    ? 'Try adjusting your search or filter criteria to find submissions'
                    : 'Your submission history will appear here once you start submitting tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'all') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'all';
                    _applyFiltersAndSort();
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Submissions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchSubmissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSubmissionCard(
    Submission submission,
    Color statusColor,
    bool isExpanded,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Main card content (always visible)
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCards.remove(index);
                    } else {
                      _expandedCards.add(index);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with title and status
                      Row(
                        children: [
                          // Status indicator dot
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              submission.taskTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withValues(alpha: 0.1),
                                  statusColor.withValues(alpha: 0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(submission.taskStatus),
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  submission.taskStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Preview text with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isExpanded
                              ? submission.submissionText
                              : submission.submissionText.length > 120
                                  ? '${submission.submissionText.substring(0, 120)}...'
                                  : submission.submissionText,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Enhanced bottom row with date and expand/collapse indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.indigo.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Submitted: ${submission.submittedAt.toString().split(' ')[0]}',
                                  style: TextStyle(
                                    color: Colors.indigo.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                  color: Colors.cyan.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isExpanded ? 'Less' : 'More',
                                  style: TextStyle(
                                    color: Colors.cyan.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable content (shown when expanded)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(submission),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Submission submission) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.indigo.shade200,
              margin: const EdgeInsets.only(bottom: 16),
            ),

            // Task Description
            _buildDetailRow(
              Icons.description,
              'Task Description',
              submission.taskDescription,
              Colors.blue.shade600,
            ),
            const SizedBox(height: 12),

            // Due Date
            _buildDetailRow(
              Icons.event,
              'Due Date',
              submission.dueDate.toString().split(' ')[0],
              Colors.orange.shade600,
            ),
            const SizedBox(height: 12),

            // Submission Date with time
            _buildDetailRow(
              Icons.schedule,
              'Submitted At',
              submission.submittedAt.toString().split('.')[0],
              Colors.green.shade600,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSubmissionScreen(
                            submission: submission,
                            workerId: widget.workerId,
                          ),
                        ),
                      ).then((_) => _fetchSubmissions());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Submission'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade400,
            Colors.cyan.shade400,
          ],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _submissions.isEmpty
                    ? _buildEmptyState()
                    : Column(
                      children: [
                        // Fixed header content
                        Column(
                          children: [
                            // Statistics header
                            _buildStatisticsHeader(),

                            // Search and filter bar
                            _buildSearchAndFilterBar(),

                            const SizedBox(height: 16),

                            // Results count
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    'Showing ${_filteredSubmissions.length} of ${_submissions.length} submissions',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_searchQuery.isNotEmpty || _selectedFilter != 'all')
                                    TextButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedFilter = 'all';
                                          _applyFiltersAndSort();
                                        });
                                      },
                                      icon: const Icon(Icons.clear_all, size: 16),
                                      label: const Text('Clear'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white.withValues(alpha: 0.8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Flexible content area
                        Expanded(
                          child: _filteredSubmissions.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: MediaQuery.of(context).size.height * 0.3,
                                    ),
                                    child: _buildEmptyState(),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchSubmissions,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredSubmissions.length,
                                    itemBuilder: (context, index) {
                                      final submission = _filteredSubmissions[index];
                                      final statusColor = _getStatusColor(submission.taskStatus);
                                      final isExpanded = _expandedCards.contains(index);

                                      return _buildEnhancedSubmissionCard(
                                        submission,
                                        statusColor,
                                        isExpanded,
                                        index,
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
      ),
    );
  }
}
