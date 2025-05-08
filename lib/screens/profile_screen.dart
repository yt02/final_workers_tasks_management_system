import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;

  const ProfileScreen({super.key, required this.workerData});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('worker_data');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  @override
  Widget build(BuildContext context) {
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: const Offset(0, -5),
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
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
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
} 