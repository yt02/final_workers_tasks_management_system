class AppConfig {
  // Base URL configuration
  static const String baseUrl = 'http://10.0.2.2/workers_tasks_management_system';
  
  // API endpoints
  static String get loginUrl => '$baseUrl/api/login_worker.php';
  static String get registerUrl => '$baseUrl/api/register_worker.php';
  
  // Image URL helper
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    // Remove leading slash if present
    String path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$baseUrl/$path';
  }
} 