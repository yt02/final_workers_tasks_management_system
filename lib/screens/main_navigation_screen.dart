import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_list_screen.dart';
import 'submission_history_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../config/app_config.dart';

class MainNavigationScreen extends StatefulWidget {
  final int workerId;
  final String workerName;
  final Map<String, dynamic> workerData;

  const MainNavigationScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.workerData,
  });

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('worker_data');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 40,
      child: CircleAvatar(
        radius: 38,
        backgroundColor: Colors.indigo.shade100,
        backgroundImage: widget.workerData['profile_image'] != null &&
                widget.workerData['profile_image'].toString().isNotEmpty
            ? NetworkImage(AppConfig.getImageUrl(widget.workerData['profile_image']))
            : null,
        child: widget.workerData['profile_image'] == null ||
                widget.workerData['profile_image'].toString().isEmpty
            ? Text(
                widget.workerName.isNotEmpty
                    ? widget.workerName[0].toUpperCase()
                    : 'W',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade600,
                ),
              )
            : null,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.workerName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
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
              accountName: Text(
                widget.workerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                widget.workerData['email'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: _buildProfileAvatar(),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Tasks'),
              selected: _currentIndex == 0,
              onTap: () {
                _tabController.animateTo(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Submission History'),
              selected: _currentIndex == 1,
              onTap: () {
                _tabController.animateTo(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _currentIndex == 2,
              onTap: () {
                _tabController.animateTo(2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TaskListScreen(
            workerId: widget.workerId,
            workerName: widget.workerName,
            workerData: widget.workerData,
            isInTabView: true,
          ),
          SubmissionHistoryScreen(
            workerId: widget.workerId,
            workerData: widget.workerData,
          ),
          ProfileScreen(
            workerData: widget.workerData,
            isInTabView: true,
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.task_alt),
              text: 'Tasks',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'History',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Profile',
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
    );
  }
}
