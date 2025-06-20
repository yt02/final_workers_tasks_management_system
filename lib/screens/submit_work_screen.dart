import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/work.dart';

class SubmitWorkScreen extends StatefulWidget {
  final Work work;
  final int workerId;
  final bool isEditing;

  const SubmitWorkScreen({
    super.key,
    required this.work,
    required this.workerId,
    this.isEditing = false,
  });

  @override
  _SubmitWorkScreenState createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends State<SubmitWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _submissionController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  Color get statusColor {
    if (widget.work.status == 'completed') {
      return Colors.green;
    } else if (widget.work.dueDate.isBefore(DateTime.now())) {
      return Colors.red;
    }
    return Colors.orange;
  }

  bool get isOverdue => widget.work.dueDate.isBefore(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.work.submissionText != null) {
      _submissionController.text = widget.work.submissionText!;
    }
    _submissionController.addListener(() {
      setState(() {}); // Update character counter
    });
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

  Future<void> _submitWork() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.submitWorkUrl),
        body: {
          'work_id': widget.work.id.toString(),
          'worker_id': widget.workerId.toString(),
          'submission_text': _submissionController.text,
          'is_editing': widget.isEditing.toString(),
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
                          widget.isEditing 
                              ? 'Submission Updated Successfully'
                              : 'Work Submitted Successfully',
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
            _error = data['error'];
          });
        }
      } else {
        setState(() {
          _error = 'Failed to submit work';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
              child: Icon(
                widget.isEditing ? Icons.edit_document : Icons.assignment_add,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.isEditing ? 'Edit Submission' : 'Submit Work',
              style: const TextStyle(
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
                  widget.work.status.toUpperCase(),
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
                                          widget.work.title,
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
                                      widget.work.description,
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

                              // Task details
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.schedule,
                                      'Due Date',
                                      widget.work.dueDate.toString().split(' ')[0],
                                      isOverdue ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.assignment_turned_in,
                                      'Assigned',
                                      widget.work.dateAssigned.toString().split(' ')[0],
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),

                              // Show existing submission for completed tasks
                              if (widget.work.status == 'completed') ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
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
                                                  'Current Submission',
                                                  style: TextStyle(
                                                    color: Colors.indigo.shade800,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Submitted: ${widget.work.submittedAt?.toString().split(' ')[0] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: Colors.indigo.shade600,
                                                    fontSize: 12,
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
                                        child: Text(
                                          widget.work.submissionText ?? 'No submission text provided',
                                          style: TextStyle(
                                            color: Colors.indigo.shade700,
                                            fontSize: 14,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Enhanced Submit Form Section
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
                                    child: Icon(
                                      widget.isEditing ? Icons.edit_note : Icons.assignment_add,
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
                                          widget.isEditing ? 'Edit Your Submission' : 'Submit Your Work',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo.shade800,
                                          ),
                                        ),
                                        Text(
                                          widget.isEditing
                                              ? 'Update your submission details below'
                                              : 'Describe the work you completed',
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
                                      'Submission Failed',
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
                                  colors: _isSubmitting
                                      ? [Colors.grey.shade400, Colors.grey.shade500]
                                      : [Colors.indigo.shade500, Colors.indigo.shade700],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isSubmitting
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
                                onPressed: _isSubmitting ? null : _submitWork,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: _isSubmitting
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
                                    : Icon(
                                        widget.isEditing ? Icons.save_alt : Icons.send,
                                        size: 22,
                                      ),
                                label: Text(
                                  _isSubmitting
                                      ? (widget.isEditing ? 'Updating...' : 'Submitting...')
                                      : (widget.isEditing ? 'Update Submission' : 'Submit Work'),
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
                                widget.isEditing
                                    ? 'Your changes will be saved and visible to your supervisor immediately.'
                                    : 'Your submission will be sent to your supervisor for review.',
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