import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/submission.dart';

class EditSubmissionScreen extends StatefulWidget {
  final Submission submission;
  final int workerId;

  const EditSubmissionScreen({
    super.key,
    required this.submission,
    required this.workerId,
  });

  @override
  _EditSubmissionScreenState createState() => _EditSubmissionScreenState();
}

class _EditSubmissionScreenState extends State<EditSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _submissionController = TextEditingController();
  bool _isUpdating = false;
  String? _error;

  Color get statusColor {
    switch (widget.submission.taskStatus.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  void initState() {
    super.initState();
    _submissionController.text = widget.submission.submissionText;
    _submissionController.addListener(() {
      setState(() {}); // Update character counter
    });
  }

  Future<void> _updateSubmission() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Are you sure you want to update this submission?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.editSubmissionUrl),
        body: {
          'submission_id': widget.submission.submissionId.toString(),
          'updated_text': _submissionController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                });
                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Submission Updated Successfully',
                          style: TextStyle(
                            color: Colors.indigo.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        } else {
          setState(() {
            _error = data['error'] ?? 'Failed to update submission';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_document,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Submission',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.submission.taskStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade400,
              Colors.cyan.shade300,
              Colors.blue.shade200,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Task Info Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.indigo.shade50,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.8),
                              blurRadius: 15,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with icon and title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.indigo.shade400,
                                          Colors.indigo.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.indigo.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.assignment,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Task Information',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo.shade600,
                                          ),
                                        ),
                                        Text(
                                          widget.submission.taskTitle,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Task description
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          size: 16,
                                          color: Colors.indigo.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.submission.taskDescription,
                                      style: TextStyle(
                                        color: Colors.indigo.shade700,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Submission details
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.schedule,
                                      'Due Date',
                                      widget.submission.dueDate.toString().split(' ')[0],
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.check_circle,
                                      'Submitted',
                                      widget.submission.submittedAt.toString().split(' ')[0],
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Enhanced Edit Form Section
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.cyan.shade50,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.cyan.shade400,
                                          Colors.cyan.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyan.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit_note,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Edit Your Submission',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo.shade800,
                                          ),
                                        ),
                                        Text(
                                          'Update your work details below',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.indigo.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Enhanced text field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.indigo.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _submissionController,
                                  decoration: InputDecoration(
                                    labelText: 'Submission Details',
                                    hintText: 'Describe the work you completed in detail...',
                                    hintStyle: TextStyle(
                                      color: Colors.indigo.shade400,
                                      fontSize: 14,
                                    ),
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.indigo.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.indigo.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.indigo.shade500,
                                        width: 3,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(12),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.edit_document,
                                        color: Colors.indigo.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 20,
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.indigo.shade600,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  maxLines: 6,
                                  minLines: 4,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.indigo.shade800,
                                    height: 1.5,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please describe the work you completed';
                                    }
                                    if (value.length < 10) {
                                      return 'Please provide more details (at least 10 characters)';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // Character counter
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_submissionController.text.length} characters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Enhanced Error Display
                      if (_error != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade50,
                                Colors.red.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Update Failed',
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Enhanced Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isUpdating
                                      ? [Colors.grey.shade400, Colors.grey.shade500]
                                      : [Colors.indigo.shade500, Colors.indigo.shade700],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isUpdating
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.indigo.withValues(alpha: 0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isUpdating ? null : _updateSubmission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: _isUpdating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.save_alt, size: 22),
                                label: Text(
                                  _isUpdating ? 'Updating...' : 'Update Submission',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Help text
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.indigo.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.indigo.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your changes will be saved and visible to your supervisor immediately.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
