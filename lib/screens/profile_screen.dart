import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import '../config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/work.dart';
import '../screens/task_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;
  final bool isInTabView;

  const ProfileScreen({
    super.key,
    required this.workerData,
    this.isInTabView = false,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Work> _works = [];
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUpdating = false;

  // Form controllers for editing
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Personal Information Controllers
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedGender = 'prefer_not_to_say';

  Map<String, dynamic> _currentWorkerData = {};

  Future<void> _logout() async {
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

  @override
  void initState() {
    super.initState();
    _currentWorkerData = Map<String, dynamic>.from(widget.workerData);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Fetch fresh profile data from server
    _fetchProfile();
    _fetchWorks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the widget is rebuilt or when returning from another page
    // Only fetch if we're not currently updating to avoid conflicts
    if (!_isUpdating) {
      _fetchProfile();
    }
  }

  // Public method to refresh profile data (can be called from parent widgets)
  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  void _initializeControllers() {
    _nameController.text = _currentWorkerData['full_name'] ?? '';
    _emailController.text = _currentWorkerData['email'] ?? '';
    _phoneController.text = _currentWorkerData['phone'] ?? '';
    _addressController.text = _currentWorkerData['address'] ?? '';

    // Personal Information
    _dobController.text = _currentWorkerData['date_of_birth'] ?? '';
    _nationalityController.text = _currentWorkerData['nationality'] ?? 'Malaysian';
    _emergencyNameController.text = _currentWorkerData['emergency_contact_name'] ?? '';
    _emergencyPhoneController.text = _currentWorkerData['emergency_contact_phone'] ?? '';
    _emergencyRelationshipController.text = _currentWorkerData['emergency_contact_relationship'] ?? '';
    _cityController.text = _currentWorkerData['city'] ?? '';
    _stateController.text = _currentWorkerData['state'] ?? '';
    _postalCodeController.text = _currentWorkerData['postal_code'] ?? '';
    _countryController.text = _currentWorkerData['country'] ?? 'Malaysia';

    // Set dropdown value
    _selectedGender = _currentWorkerData['gender'] ?? 'prefer_not_to_say';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Prepare the request body, ensuring no null values
      Map<String, String> requestBody = {
        'worker_id': _currentWorkerData['id'].toString(),
        'full_name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        // Personal Information
        'gender': _selectedGender,
        'nationality': _nationalityController.text,
        'emergency_contact_name': _emergencyNameController.text,
        'emergency_contact_phone': _emergencyPhoneController.text,
        'emergency_contact_relationship': _emergencyRelationshipController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'postal_code': _postalCodeController.text,
        'country': _countryController.text,
      };

      // Only add date_of_birth if it's not empty
      if (_dobController.text.isNotEmpty) {
        requestBody['date_of_birth'] = _dobController.text;
        print('Adding date_of_birth: ${_dobController.text}'); // Debug log
      }

      print('Request body: $requestBody'); // Debug log

      final response = await http.post(
        Uri.parse(AppConfig.updateProfileUrl),
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug log

        if (data['success'] == true) {
          setState(() {
            _currentWorkerData = data['worker'];
            _isEditing = false;
          });

          // Update shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('worker_data', json.encode(_currentWorkerData));

          // Show success dialog in center of screen
          if (mounted) {
            _showSuccessDialog('Profile Updated Successfully', 'Your profile information has been updated successfully.');
          }
        } else {
          if (mounted) {
            _showErrorDialog('Update Failed', data['error'] ?? 'Failed to update profile');
          }
        }
      } else {
        print('HTTP Error: ${response.statusCode}'); // Debug log
        print('Response body: ${response.body}'); // Debug log
        if (mounted) {
          _showErrorDialog('Network Error', 'Failed to connect to server. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'An error occurred: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    try {
      print('Fetching fresh profile data for worker ID: ${widget.workerData['id']}');

      final response = await http.post(
        Uri.parse(AppConfig.profileUrl),
        body: {'worker_id': widget.workerData['id'].toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Profile fetch response: $data');

        if (data['success'] == true) {
          setState(() {
            _currentWorkerData = data['worker'];
          });

          // Update controllers with fresh data
          _initializeControllers();

          // Update shared preferences with fresh data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('worker_data', json.encode(_currentWorkerData));

          print('Profile data updated successfully');
        } else {
          print('Failed to fetch profile: ${data['error']}');
        }
      } else {
        print('HTTP Error fetching profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchWorks() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.worksUrl),
        body: {'worker_id': widget.workerData['id'].toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _works = (data['works'] as List)
                .map((work) => Work.fromJson(work))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.indigo.shade800,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.indigo.shade600,
                    fontSize: 14,
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    // Personal Information Controllers
    _dobController.dispose();
    _nationalityController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  Widget _buildProfileImage() {
    print('Building profile image widget');
    print('Worker data: ${widget.workerData}');
    
    if (widget.workerData['profile_image'] == null || widget.workerData['profile_image'].toString().isEmpty) {
      print('No profile image found in worker data');
      return const Icon(
        Icons.person,
        size: 40,
        color: Colors.indigo,
      );
    }

    final imageUrl = AppConfig.getImageUrl(widget.workerData['profile_image'].toString());
    print('Attempting to load profile image from: $imageUrl');

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('Image loaded successfully');
            return child;
          }
          print('Loading progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          print('Stack trace: $stackTrace');
          return const Icon(
            Icons.person,
            size: 40,
            color: Colors.indigo,
          );
        },
      ),
    );
  }

  // Enhanced UI Components for better UX
  Widget _buildEnhancedProfileHeader() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Enhanced profile image with status indicator
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: _currentWorkerData['profile_image'] != null
                        ? NetworkImage(AppConfig.getImageUrl(_currentWorkerData['profile_image']))
                        : null,
                    child: _currentWorkerData['profile_image'] == null
                        ? Text(
                            _currentWorkerData['full_name']?.isNotEmpty == true
                                ? _currentWorkerData['full_name'][0].toUpperCase()
                                : 'W',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade600,
                            ),
                          )
                        : null,
                  ),
                ),
                // Online status indicator
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentWorkerData['full_name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentWorkerData['email'] ?? '',
                    style: TextStyle(
                      color: Colors.indigo.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${_currentWorkerData['id']}',
                          style: TextStyle(
                            color: Colors.indigo.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 11,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final completionPercentage = _getProfileCompletionPercentage();
    final progressColor = completionPercentage >= 80
        ? Colors.green
        : completionPercentage >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            progressColor.shade50.withValues(alpha: 0.3),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with completion info and edit button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_circle_outlined,
                    color: progressColor.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Completion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: progressColor.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${completionPercentage.toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 13,
                          color: progressColor.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Integrated Edit Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isEditing
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.indigo.shade400, Colors.indigo.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isEditing ? Colors.red : Colors.indigo).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            _initializeControllers();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isEditing ? Icons.close : Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isEditing ? 'Cancel' : 'Edit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: completionPercentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor.shade600),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 12),

            // Completion message
            Text(
              _getCompletionMessage(completionPercentage),
              style: TextStyle(
                fontSize: 12,
                color: progressColor.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getCompletionMessage(double percentage) {
    if (percentage >= 90) {
      return 'Excellent! Your profile is almost complete.';
    } else if (percentage >= 70) {
      return 'Great progress! Just a few more details needed.';
    } else if (percentage >= 50) {
      return 'Good start! Keep adding more information.';
    } else {
      return 'Let\'s complete your profile for better visibility.';
    }
  }

  double _getProfileCompletionPercentage() {
    int completedFields = 0;
    int totalFields = 8; // Adjust based on your requirements

    if (_currentWorkerData['full_name']?.isNotEmpty == true) completedFields++;
    if (_currentWorkerData['email']?.isNotEmpty == true) completedFields++;
    if (_currentWorkerData['phone']?.isNotEmpty == true) completedFields++;
    if (_currentWorkerData['address']?.isNotEmpty == true) completedFields++;
    if (_currentWorkerData['date_of_birth'] != null) completedFields++;
    if (_currentWorkerData['gender'] != null) completedFields++;
    if (_currentWorkerData['nationality']?.isNotEmpty == true) completedFields++;
    if (_currentWorkerData['emergency_contact_name']?.isNotEmpty == true) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInTabView) {
      // Enhanced tab view layout with better UX
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
          child: CustomScrollView(
            slivers: [
              // Enhanced Profile Header
              SliverToBoxAdapter(
                child: _buildEnhancedProfileHeader(),
              ),

              // Profile Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile completion progress with integrated edit
                        _buildProfileCompletionCard(),

                        const SizedBox(height: 20),

                        // Profile Information
                        if (_isEditing) ...[
                          _buildEditForm(),
                        ] else ...[
                          _buildProfileInfo(),
                        ],

                        const SizedBox(height: 16),

                        // Enhanced task stats
                        _buildTaskStats(),

                        const SizedBox(height: 16),

                        // Settings and logout section
                        _buildLogoutSection(),
                      ],
                    ),
                  ),
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
              // Header Section with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: _buildProfileImage(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.workerData['full_name'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.workerData['email'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
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
              
              // Main Content Section with Animation
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Worker Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildInfoCard(
                              Icons.badge,
                              'Worker ID',
                              widget.workerData['id'].toString(),
                              Colors.indigo.shade100,
                              'Your unique identification number',
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              Icons.phone,
                              'Phone Number',
                              widget.workerData['phone'],
                              Colors.cyan.shade100,
                              'Your contact number',
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              Icons.location_on,
                              'Address',
                              widget.workerData['address'],
                              Colors.orange.shade100,
                              'Your current address',
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Task Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTaskInfoCard(),
                            const SizedBox(height: 32),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.indigo.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.indigo.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStyledTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Personal Information Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.cyan.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth Field
                  _buildDateField(
                    controller: _dobController,
                    label: 'Date of Birth',
                    icon: Icons.cake,
                  ),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  _buildGenderDropdown(),
                  const SizedBox(height: 16),

                  // Nationality Field
                  _buildStyledTextField(
                    controller: _nationalityController,
                    label: 'Nationality',
                    icon: Icons.flag,
                  ),
                  const SizedBox(height: 20),

                  // Emergency Contact Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.emergency,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Emergency Contact Fields
                  _buildStyledTextField(
                    controller: _emergencyNameController,
                    label: 'Emergency Contact Name',
                    icon: Icons.contact_emergency,
                  ),
                  const SizedBox(height: 16),

                  _buildStyledTextField(
                    controller: _emergencyPhoneController,
                    label: 'Emergency Contact Phone',
                    icon: Icons.phone_in_talk,
                  ),
                  const SizedBox(height: 16),

                  _buildStyledTextField(
                    controller: _emergencyRelationshipController,
                    label: 'Relationship',
                    icon: Icons.family_restroom,
                  ),
                  const SizedBox(height: 20),

                  // Address Details Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Address Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address Detail Fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildStyledTextField(
                          controller: _cityController,
                          label: 'City',
                          icon: Icons.location_city,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStyledTextField(
                          controller: _stateController,
                          label: 'State',
                          icon: Icons.map,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStyledTextField(
                          controller: _postalCodeController,
                          label: 'Postal Code',
                          icon: Icons.markunread_mailbox,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStyledTextField(
                          controller: _countryController,
                          label: 'Country',
                          icon: Icons.public,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _initializeControllers();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isUpdating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              _isUpdating ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.indigo.shade600,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.shade400,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.indigo.shade600,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: controller.text.isNotEmpty
                ? DateTime.tryParse(controller.text) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            controller.text = date.toString().split(' ')[0];
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.indigo.shade600,
              size: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.calendar_today,
              color: Colors.indigo.shade400,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.shade400,
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.indigo.shade600,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_outline,
              color: Colors.indigo.shade600,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.indigo.shade400,
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.indigo.shade600,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'male',
            child: Text('Male'),
          ),
          DropdownMenuItem(
            value: 'female',
            child: Text('Female'),
          ),
          DropdownMenuItem(
            value: 'other',
            child: Text('Other'),
          ),
          DropdownMenuItem(
            value: 'prefer_not_to_say',
            child: Text('Prefer not to say'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        // Basic Information Section
        _buildInfoSection(
          title: 'Basic Information',
          icon: Icons.person,
          color: Colors.indigo,
          children: [
            _buildEnhancedInfoCard(
              Icons.badge,
              'Worker ID',
              _currentWorkerData['id'].toString(),
              Colors.indigo.shade100,
              'Your unique identification number',
            ),
            const SizedBox(height: 12),
            _buildEnhancedInfoCard(
              Icons.person,
              'Full Name',
              _currentWorkerData['full_name'] ?? 'Not provided',
              Colors.blue.shade100,
              'Your full name',
            ),
            const SizedBox(height: 12),
            _buildEnhancedInfoCard(
              Icons.email,
              'Email',
              _currentWorkerData['email'] ?? 'Not provided',
              Colors.green.shade100,
              'Your email address',
            ),
            const SizedBox(height: 12),
            _buildPhoneNumberCard(
              Icons.phone,
              'Phone Number',
              _currentWorkerData['phone'] ?? 'Not provided',
              Colors.cyan.shade100,
              'Your contact number',
            ),
            const SizedBox(height: 12),
            _buildEnhancedInfoCard(
              Icons.location_on,
              'Address',
              _currentWorkerData['address'] ?? 'Not provided',
              Colors.orange.shade100,
              'Your current address',
            ),
          ],
        ),

        // Personal Information Section
        if (_hasPersonalInfo()) ...[
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Personal Information',
            icon: Icons.person_outline,
            color: Colors.cyan,
            children: _buildPersonalInfoCards(),
          ),
        ],

        // Emergency Contact Section
        if (_hasEmergencyContact()) ...[
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Emergency Contact',
            icon: Icons.emergency,
            color: Colors.red,
            children: _buildEmergencyContactCards(),
          ),
        ],

        // Address Details Section
        if (_hasAddressDetails()) ...[
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Address Details',
            icon: Icons.location_city,
            color: Colors.orange,
            children: _buildAddressDetailsCards(),
          ),
        ],
      ],
    );
  }







  // Phone number utility methods
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone dialer for $phoneNumber'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching phone dialer: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('$label copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy $label'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildPhoneNumberCard(IconData icon, String label, String phoneNumber, Color iconColor, String description) {
    if (phoneNumber.isEmpty || phoneNumber == 'Not provided') {
      return _buildEnhancedInfoCard(icon, label, phoneNumber, iconColor, description);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.indigo.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.indigo.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _makePhoneCall(phoneNumber),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _copyToClipboard(phoneNumber, label),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.red.shade50.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                      Text(
                        'Manage your account settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for checking if sections have data
  bool _hasPersonalInfo() {
    return _currentWorkerData['date_of_birth'] != null ||
           _currentWorkerData['gender'] != null ||
           _currentWorkerData['nationality']?.isNotEmpty == true;
  }

  bool _hasEmergencyContact() {
    return _currentWorkerData['emergency_contact_name']?.isNotEmpty == true ||
           _currentWorkerData['emergency_contact_phone']?.isNotEmpty == true;
  }

  bool _hasAddressDetails() {
    return _currentWorkerData['city']?.isNotEmpty == true ||
           _currentWorkerData['state']?.isNotEmpty == true ||
           _currentWorkerData['postal_code']?.isNotEmpty == true ||
           _currentWorkerData['country']?.isNotEmpty == true;
  }

  // Helper methods for building section cards
  List<Widget> _buildPersonalInfoCards() {
    List<Widget> cards = [];

    if (_currentWorkerData['date_of_birth'] != null) {
      cards.addAll([
        _buildEnhancedInfoCard(
          Icons.cake,
          'Date of Birth',
          _formatDateOfBirth(_currentWorkerData['date_of_birth']),
          Colors.pink.shade100,
          'Your date of birth',
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (_currentWorkerData['gender'] != null) {
      cards.addAll([
        _buildEnhancedInfoCard(
          Icons.person_outline,
          'Gender',
          _formatGender(_currentWorkerData['gender']),
          Colors.purple.shade100,
          'Your gender',
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (_currentWorkerData['nationality']?.isNotEmpty == true) {
      cards.addAll([
        _buildEnhancedInfoCard(
          Icons.flag,
          'Nationality',
          _currentWorkerData['nationality'] ?? 'Not provided',
          Colors.teal.shade100,
          'Your nationality',
        ),
        const SizedBox(height: 12),
      ]);
    }

    return cards;
  }

  List<Widget> _buildEmergencyContactCards() {
    List<Widget> cards = [];

    // Emergency Contact Name and Relationship
    final name = _currentWorkerData['emergency_contact_name'];
    final relationship = _currentWorkerData['emergency_contact_relationship'];
    if (name?.isNotEmpty == true || relationship?.isNotEmpty == true) {
      String contactInfo = '';
      if (name?.isNotEmpty == true) {
        contactInfo = name;
        if (relationship?.isNotEmpty == true) {
          contactInfo += ' ($relationship)';
        }
      } else if (relationship?.isNotEmpty == true) {
        contactInfo = relationship;
      }

      cards.addAll([
        _buildEnhancedInfoCard(
          Icons.contact_emergency,
          'Emergency Contact',
          contactInfo.isNotEmpty ? contactInfo : 'Not provided',
          Colors.red.shade100,
          'Your emergency contact person',
        ),
        const SizedBox(height: 12),
      ]);
    }

    // Emergency Contact Phone with Call/Copy functionality
    final phone = _currentWorkerData['emergency_contact_phone'];
    if (phone?.isNotEmpty == true) {
      cards.add(
        _buildPhoneNumberCard(
          Icons.phone_in_talk,
          'Emergency Phone',
          phone,
          Colors.red.shade100,
          'Emergency contact phone number',
        ),
      );
    }

    // If no emergency contact info at all, show default message
    if (cards.isEmpty) {
      cards.add(
        _buildEnhancedInfoCard(
          Icons.contact_emergency,
          'Emergency Contact',
          'Not provided',
          Colors.red.shade100,
          'Your emergency contact information',
        ),
      );
    }

    return cards;
  }

  List<Widget> _buildAddressDetailsCards() {
    List<Widget> cards = [];

    if (_currentWorkerData['city']?.isNotEmpty == true ||
        _currentWorkerData['state']?.isNotEmpty == true) {
      cards.addAll([
        _buildEnhancedInfoCard(
          Icons.location_city,
          'City & State',
          _formatCityState(),
          Colors.orange.shade100,
          'Your city and state',
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (_currentWorkerData['postal_code']?.isNotEmpty == true ||
        _currentWorkerData['country']?.isNotEmpty == true) {
      cards.addAll([
        _buildEnhancedInfoCard(
          Icons.public,
          'Postal Code & Country',
          _formatPostalCountry(),
          Colors.orange.shade100,
          'Your postal code and country',
        ),
      ]);
    }

    return cards;
  }

  Widget _buildEnhancedInfoCard(IconData icon, String label, String value, Color iconColor, String description) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.indigo.shade800,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStats() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final completedTasks = _works.where((work) => work.status == 'completed').length;
    final pendingTasks = _works.where((work) => work.status == 'pending').length;
    final overdueTasks = _works.where((work) => work.status == 'overdue').length;
    final totalTasks = _works.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.task_alt,
                    color: Colors.indigo.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Tasks: $totalTasks',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Completed', completedTasks, Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('Pending', pendingTasks, Colors.orange),
                ),
                Expanded(
                  child: _buildStatItem('Overdue', overdueTasks, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color iconColor, String description) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.indigo.shade800,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfoCard() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final completedTasks = _works.where((work) => work.status == 'completed').length;
    final pendingTasks = _works.where((work) => work.status == 'pending').length;
    final overdueTasks = _works.where((work) => work.status == 'overdue').length;
    final totalTasks = _works.length;

    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(
              workerId: int.parse(widget.workerData['id'].toString()),
              workerName: widget.workerData['full_name'].toString(),
              workerData: widget.workerData,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.task_alt,
                      color: Colors.indigo.shade800,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Tasks: $totalTasks',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTaskStat(
                    'Completed',
                    completedTasks.toString(),
                    Colors.green,
                  ),
                  _buildTaskStat(
                    'Pending',
                    pendingTasks.toString(),
                    Colors.orange,
                  ),
                  _buildTaskStat(
                    'Overdue',
                    overdueTasks.toString(),
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskListScreen(
                          workerId: int.parse(widget.workerData['id'].toString()),
                          workerName: widget.workerData['full_name'].toString(),
                          workerData: widget.workerData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View All Tasks'),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Helper methods for formatting personal information
  String _formatDateOfBirth(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return 'Not provided';

    try {
      final date = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      final age = now.year - date.year;
      final hasHadBirthdayThisYear = now.month > date.month ||
          (now.month == date.month && now.day >= date.day);

      final actualAge = hasHadBirthdayThisYear ? age : age - 1;
      final formattedDate = '${date.day}/${date.month}/${date.year}';

      return '$formattedDate ($actualAge years old)';
    } catch (e) {
      return dateOfBirth;
    }
  }

  String _formatGender(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
      default:
        return 'Prefer not to say';
    }
  }



  String _formatCityState() {
    final city = _currentWorkerData['city'];
    final state = _currentWorkerData['state'];

    List<String> parts = [];
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);

    return parts.isNotEmpty ? parts.join(', ') : 'Not provided';
  }

  String _formatPostalCountry() {
    final postalCode = _currentWorkerData['postal_code'];
    final country = _currentWorkerData['country'];

    List<String> parts = [];
    if (postalCode != null && postalCode.isNotEmpty) parts.add(postalCode);
    if (country != null && country.isNotEmpty) parts.add(country);

    return parts.isNotEmpty ? parts.join(', ') : 'Not provided';
  }
}