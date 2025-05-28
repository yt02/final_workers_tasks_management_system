class AppConfig {
  // Base URL configuration
  static const String baseUrl = 'http://192.168.70.241';
  
  // API endpoints
  static String get loginUrl => '$baseUrl/api/login_worker.php';
  static String get registerUrl => '$baseUrl/api/register_worker.php';
  static String get worksUrl => '$baseUrl/api/get_works.php';
  static String get submitWorkUrl => '$baseUrl/api/submit_work.php';
  
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