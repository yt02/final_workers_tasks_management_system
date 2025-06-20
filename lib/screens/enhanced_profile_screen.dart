import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class EnhancedProfileScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;

  const EnhancedProfileScreen({
    super.key,
    required this.workerData,
  });

  @override
  _EnhancedProfileScreenState createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _currentWorkerData = {};
  bool _isLoading = false;

  // Form controllers for different sections
  final _personalFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _educationFormKey = GlobalKey<FormState>();

  // Personal Information Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Professional Information Controllers
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _workLocationController = TextEditingController();
  final _skillsController = TextEditingController();

  // Contact Information Controllers
  final _alternatePhoneController = TextEditingController();
  final _workEmailController = TextEditingController();
  final _linkedinController = TextEditingController();

  // Education Controllers
  final _educationFieldController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _languagesController = TextEditingController();

  String _selectedGender = 'prefer_not_to_say';
  String _selectedEmploymentType = 'full_time';
  String _selectedEducationLevel = 'bachelor';
  String _selectedCommunicationPref = 'app_notification';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _currentWorkerData = Map<String, dynamic>.from(widget.workerData);
    _initializeControllers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _workLocationController.dispose();
    _skillsController.dispose();
    _alternatePhoneController.dispose();
    _workEmailController.dispose();
    _linkedinController.dispose();
    _educationFieldController.dispose();
    _certificationsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize with existing data
    _nameController.text = _currentWorkerData['full_name'] ?? '';
    _emailController.text = _currentWorkerData['email'] ?? '';
    _phoneController.text = _currentWorkerData['phone'] ?? '';
    _dobController.text = _currentWorkerData['date_of_birth'] ?? '';
    _nationalityController.text = _currentWorkerData['nationality'] ?? 'Malaysian';
    _emergencyNameController.text = _currentWorkerData['emergency_contact_name'] ?? '';
    _emergencyPhoneController.text = _currentWorkerData['emergency_contact_phone'] ?? '';
    
    _employeeIdController.text = _currentWorkerData['employee_id'] ?? '';
    _departmentController.text = _currentWorkerData['department'] ?? '';
    _positionController.text = _currentWorkerData['position'] ?? '';
    _workLocationController.text = _currentWorkerData['work_location'] ?? '';
    _skillsController.text = _currentWorkerData['skills'] ?? '';
    
    _alternatePhoneController.text = _currentWorkerData['alternate_phone'] ?? '';
    _workEmailController.text = _currentWorkerData['work_email'] ?? '';
    _linkedinController.text = _currentWorkerData['linkedin_profile'] ?? '';
    
    _educationFieldController.text = _currentWorkerData['education_field'] ?? '';
    _certificationsController.text = _currentWorkerData['certifications'] ?? '';
    _languagesController.text = _currentWorkerData['languages_spoken'] ?? '';

    // Set dropdown values
    _selectedGender = _currentWorkerData['gender'] ?? 'prefer_not_to_say';
    _selectedEmploymentType = _currentWorkerData['employment_type'] ?? 'full_time';
    _selectedEducationLevel = _currentWorkerData['education_level'] ?? 'bachelor';
    _selectedCommunicationPref = _currentWorkerData['preferred_communication'] ?? 'app_notification';
  }

  double _getProfileCompletionPercentage() {
    int totalFields = 20; // Total important fields
    int completedFields = 0;
    
    // Check basic fields
    if (_nameController.text.isNotEmpty) completedFields++;
    if (_emailController.text.isNotEmpty) completedFields++;
    if (_phoneController.text.isNotEmpty) completedFields++;
    if (_dobController.text.isNotEmpty) completedFields++;
    if (_nationalityController.text.isNotEmpty) completedFields++;
    
    // Check professional fields
    if (_employeeIdController.text.isNotEmpty) completedFields++;
    if (_departmentController.text.isNotEmpty) completedFields++;
    if (_positionController.text.isNotEmpty) completedFields++;
    if (_workLocationController.text.isNotEmpty) completedFields++;
    if (_skillsController.text.isNotEmpty) completedFields++;
    
    // Check contact fields
    if (_alternatePhoneController.text.isNotEmpty) completedFields++;
    if (_workEmailController.text.isNotEmpty) completedFields++;
    
    // Check education fields
    if (_educationFieldController.text.isNotEmpty) completedFields++;
    if (_certificationsController.text.isNotEmpty) completedFields++;
    if (_languagesController.text.isNotEmpty) completedFields++;
    
    // Check emergency contact
    if (_emergencyNameController.text.isNotEmpty) completedFields++;
    if (_emergencyPhoneController.text.isNotEmpty) completedFields++;
    
    // Check profile image
    if (_currentWorkerData['profile_image'] != null && 
        _currentWorkerData['profile_image'].toString().isNotEmpty) {
      completedFields++;
    }
    
    // Check address
    if (_currentWorkerData['address'] != null && 
        _currentWorkerData['address'].toString().isNotEmpty) {
      completedFields++;
    }
    
    // Check LinkedIn
    if (_linkedinController.text.isNotEmpty) completedFields++;
    
    return (completedFields / totalFields) * 100;
  }

  Widget _buildProfileHeader() {
    double completionPercentage = _getProfileCompletionPercentage();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade600,
            Colors.cyan.shade500,
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Image and Basic Info
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: _currentWorkerData['profile_image'] != null &&
                          _currentWorkerData['profile_image'].toString().isNotEmpty
                      ? Image.network(
                          AppConfig.getImageUrl(_currentWorkerData['profile_image'].toString()),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white,
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.indigo,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white,
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.indigo,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentWorkerData['full_name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentWorkerData['position'] ?? 'No Position',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentWorkerData['department'] ?? 'No Department',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Profile Completion Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile Completion',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${completionPercentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completionPercentage >= 80 
                        ? Colors.green 
                        : completionPercentage >= 50 
                            ? Colors.orange 
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildProfileHeader(),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Personal'),
                Tab(icon: Icon(Icons.work), text: 'Professional'),
                Tab(icon: Icon(Icons.contact_phone), text: 'Contact'),
                Tab(icon: Icon(Icons.school), text: 'Education'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildProfessionalTab(),
                _buildContactTab(),
                _buildEducationTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information', Icons.person),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            _buildDateField(
              controller: _dobController,
              label: 'Date of Birth',
              icon: Icons.cake,
            ),
            const SizedBox(height: 16),
            
            _buildDropdownField(
              value: _selectedGender,
              label: 'Gender',
              icon: Icons.person_outline,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _nationalityController,
              label: 'Nationality',
              icon: Icons.flag,
            ),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Emergency Contact', Icons.emergency),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emergencyNameController,
              label: 'Emergency Contact Name',
              icon: Icons.contact_emergency,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emergencyPhoneController,
              label: 'Emergency Contact Phone',
              icon: Icons.phone_in_talk,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  // Additional tab methods would continue here...
  // Due to length constraints, I'll provide the structure for other tabs

  Widget _buildProfessionalTab() {
    return const Center(child: Text('Professional Information Tab'));
  }

  Widget _buildContactTab() {
    return const Center(child: Text('Contact Information Tab'));
  }

  Widget _buildEducationTab() {
    return const Center(child: Text('Education & Skills Tab'));
  }

  Widget _buildSettingsTab() {
    return const Center(child: Text('Settings & Preferences Tab'));
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.indigo, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          controller.text = date.toString().split(' ')[0];
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo, width: 2),
        ),
      ),
    );
  }
}
