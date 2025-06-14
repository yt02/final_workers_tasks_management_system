class AppConfig {
  // Base URL configuration
  static const String baseUrl = 'http://192.168.65.233';

  // API endpoints
  static String get loginUrl => '$baseUrl/api/login_worker.php';
  static String get registerUrl => '$baseUrl/api/register_worker.php';
  static String get worksUrl => '$baseUrl/api/get_works.php';
  static String get submitWorkUrl => '$baseUrl/api/submit_work.php';
  static String get submissionsUrl => '$baseUrl/api/get_submissions.php';
  static String get editSubmissionUrl => '$baseUrl/api/edit_submission.php';
  static String get profileUrl => '$baseUrl/api/get_profile.php';
  static String get updateProfileUrl => '$baseUrl/api/update_profile.php';

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