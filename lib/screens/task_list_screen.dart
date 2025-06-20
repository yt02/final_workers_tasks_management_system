import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/work.dart';
import '../models/submission.dart';
import 'submit_work_screen.dart';
import 'edit_submission_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskListScreen extends StatefulWidget {
  final int workerId;
  final String workerName;
  final Map<String, dynamic> workerData;
  final bool isInTabView;

  const TaskListScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.workerData,
    this.isInTabView = false,
  });

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Work> _works = [];
  bool _isLoading = true;
  String? _error;
  String? _message;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _fetchWorks();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImage = prefs.getString('profile_image');
    });
  }

  Future<void> _fetchWorks() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.worksUrl),
        body: {'worker_id': widget.workerId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Log debug information if available
          if (data['debug'] != null) {
            print('Debug Info: ${data['debug']}');
            print('Overdue tasks updated: ${data['debug']['overdue_updated']}');
            print('Current date: ${data['debug']['current_date']}');
            print('Pending tasks:');
            for (var task in data['debug']['pending_tasks']) {
              print('- Task: ${task['title']}, Due: ${task['due_date']}, Status: ${task['status']}');
            }
            print('Update query: ${data['debug']['query_debug']['update_query']}');
          }
          
          setState(() {
            _works = (data['works'] as List)
                .map((work) => Work.fromJson(work))
                .toList();
            _message = data['message'];
            _isLoading = false;
            _error = null;
          });
        } else {
          setState(() {
            _error = data['error'];
            _isLoading = false;
            _message = null;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load works';
          _isLoading = false;
          _message = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _message = null;
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: widget.isInTabView ? Colors.white.withOpacity(0.5) : Colors.indigo.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            _message ?? 'No tasks assigned yet',
            style: TextStyle(
              fontSize: 18,
              color: widget.isInTabView ? Colors.white.withOpacity(0.8) : Colors.indigo.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchWorks,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isInTabView ? Colors.white : Colors.indigo,
              foregroundColor: widget.isInTabView ? Colors.indigo : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
            color: widget.isInTabView ? Colors.white.withOpacity(0.5) : Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Tasks',
            style: TextStyle(
              fontSize: 18,
              color: widget.isInTabView ? Colors.white.withOpacity(0.8) : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: widget.isInTabView ? Colors.white.withOpacity(0.6) : Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchWorks,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isInTabView ? Colors.white : Colors.red,
              foregroundColor: widget.isInTabView ? Colors.red : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Work work, Color statusColor, bool isOverdue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.indigo.shade200,
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.indigo.shade50.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title, status, and tap indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    work.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    work.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Tap to interact indicator
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: Colors.indigo.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    work.status == 'completed' ? 'Tap to edit submission' : 'Tap to submit work',
                    style: TextStyle(
                      color: Colors.indigo.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              work.description,
              style: TextStyle(
                color: Colors.indigo.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Date information with better styling
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.indigo.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.indigo.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                work.dueDate.toString().split(' ')[0],
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.indigo.shade800,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.assignment_turned_in,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                work.dateAssigned.toString().split(' ')[0],
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
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
            if (work.status == 'completed') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade50,
                      Colors.indigo.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submission Completed',
                                style: TextStyle(
                                  color: Colors.indigo.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Submitted: ${work.submittedAt?.toString().split(' ')[0] ?? 'N/A'}',
                                style: TextStyle(
                                  color: Colors.indigo.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 12,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Editable',
                                style: TextStyle(
                                  color: Colors.orange.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.indigo.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Submission:',
                            style: TextStyle(
                              color: Colors.indigo.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            work.submissionText ?? 'No submission text provided',
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // For pending tasks, add a call-to-action
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade50,
                      Colors.yellow.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        size: 18,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to Submit',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Tap anywhere on this card to start working',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to convert Work to Submission for completed tasks
  Submission _workToSubmission(Work work) {
    // Use the actual submission ID from the database
    final submissionId = work.submissionId;
    if (submissionId == null) {
      throw Exception('No submission found for this completed task');
    }

    return Submission(
      submissionId: submissionId, // Using actual submission ID from database
      workId: work.id,
      taskTitle: work.title,
      taskDescription: work.description,
      submissionText: work.submissionText ?? '',
      taskStatus: work.status,
      dueDate: work.dueDate,
      submittedAt: work.submittedAt ?? DateTime.now(),
    );
  }

  void _navigateToTaskScreen(Work work) {
    if (work.status == 'completed') {
      // Check if submission ID exists before navigating
      if (work.submissionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('No submission found for this task. Please contact support.'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Navigate to EditSubmissionScreen for completed tasks
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditSubmissionScreen(
              submission: _workToSubmission(work),
              workerId: widget.workerId,
            ),
          ),
        ).then((_) => _fetchWorks());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } else {
      // Navigate to SubmitWorkScreen for pending tasks
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmitWorkScreen(
            work: work,
            workerId: widget.workerId,
            isEditing: false,
          ),
        ),
      ).then((_) => _fetchWorks());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInTabView) {
      // When in tab view, return just the content without Scaffold
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _works.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchWorks,
                        child: Column(
                          children: [
                            // Help hint at the top
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.indigo.withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Colors.indigo.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tap any task card to submit work or edit submissions',
                                      style: TextStyle(
                                        color: Colors.indigo.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Task list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _works.length,
                                itemBuilder: (context, index) {
                                  final work = _works[index];
                                  final isOverdue = work.dueDate.isBefore(DateTime.now());
                                  final statusColor = work.status == 'completed'
                                      ? Colors.green
                                      : isOverdue
                                          ? Colors.red
                                          : Colors.orange;

                                  return Card(
                                    elevation: 6,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _navigateToTaskScreen(work),
                                        borderRadius: BorderRadius.circular(16),
                                        splashColor: Colors.indigo.withValues(alpha: 0.1),
                                        highlightColor: Colors.indigo.withValues(alpha: 0.05),
                                        child: _buildTaskCard(work, statusColor, isOverdue),
                                      ),
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

    // Original full screen layout when not in tab view
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'Welcome, ${widget.workerName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _fetchWorks,
                    tooltip: 'Refresh Tasks',
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: widget.workerData['profile_image'] != null && 
                               widget.workerData['profile_image'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        AppConfig.getImageUrl(widget.workerData['profile_image'].toString()),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.indigo,
                              ),
                      ),
                    ),
                    offset: const Offset(0, 5),
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    elevation: 8,
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.indigo.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Your Profile',
                              style: TextStyle(
                                color: Colors.indigo.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String value) {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              workerData: widget.workerData,
                            ),
                          ),
                        );
                      } else if (value == 'logout') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('worker_data');
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: Colors.red.shade100,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red.shade50,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _fetchWorks,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _works.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _fetchWorks,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _works.length,
                                  itemBuilder: (context, index) {
                                    final work = _works[index];
                                    final isOverdue = work.dueDate.isBefore(DateTime.now());
                                    final statusColor = work.status == 'completed'
                                        ? Colors.green
                                        : isOverdue
                                            ? Colors.red
                                            : Colors.orange;

                                    return Card(
                                      elevation: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: InkWell(
                                        onTap: () => _navigateToTaskScreen(work),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.indigo.shade100,
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        work.title,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.indigo.shade800,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(
                                                          color: statusColor,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        work.status.toUpperCase(),
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  work.description,
                                                  style: TextStyle(
                                                    color: Colors.indigo.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.calendar_today,
                                                            size: 16,
                                                            color: isOverdue
                                                                ? Colors.red
                                                                : Colors.indigo.shade600,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Due: ${work.dueDate.toString().split(' ')[0]}',
                                                            style: TextStyle(
                                                              color: isOverdue
                                                                  ? Colors.red
                                                                  : Colors.indigo.shade600,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.assignment_turned_in,
                                                          size: 16,
                                                          color: Colors.indigo.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Assigned: ${work.dateAssigned.toString().split(' ')[0]}',
                                                          style: TextStyle(
                                                            color: Colors.indigo.shade600,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                if (work.status == 'completed') ...[
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.indigo.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.indigo.shade200,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.check_circle,
                                                              size: 16,
                                                              color: Colors.green.shade600,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              'Submission',
                                                              style: TextStyle(
                                                                color: Colors.indigo.shade800,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                            Text(
                                                              'Submitted: ${work.submittedAt?.toString().split(' ')[0] ?? 'N/A'}',
                                                              style: TextStyle(
                                                                color: Colors.indigo.shade600,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          work.submissionText ?? 'No submission text provided',
                                                          style: TextStyle(
                                                            color: Colors.indigo.shade700,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => _navigateToTaskScreen(work),
                                                      icon: const Icon(Icons.edit),
                                                      label: const Text('Edit Submission'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.indigo,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 