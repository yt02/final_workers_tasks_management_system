# Workers Tasks Management System

A Flutter application for managing worker tasks and profiles.

## Features

- Worker Registration
- Worker Login
- Profile Management
- Profile Image Upload
- Task Management
  - View assigned tasks
  - Submit work
  - Edit submissions
  - Track task status
- Task Statistics
  - View completed tasks
  - View pending tasks
  - Total task count

## Development

The application is built using:
- Flutter
- PHP (Backend)
- MySQL (Database)

## File Structure

```
lib/
├── config/
│   └── app_config.dart    # Configuration settings
├── models/
│   └── work.dart         # Work model
├── screens/
│   ├── login_screen.dart
│   ├── registration_screen.dart
│   ├── profile_screen.dart
│   ├── task_list_screen.dart
│   └── submit_work_screen.dart
└── main.dart
```

## Screenshots

| Login Page | Register Page | Profile Page | Task List Page |
|------------|---------------|--------------|----------------|
| ![Login](https://github.com/user-attachments/assets/06aa404e-0205-4dcd-8ab0-523790c2e15c) | ![Register](https://github.com/user-attachments/assets/85ba7b6c-f422-494f-9ea9-7b60a9ae3ae8) | ![Profile](https://github.com/user-attachments/assets/03401071-5149-47e2-8a1b-2585eaa4c77d) | ![Task List](https://github.com/user-attachments/assets/your-task-list-screenshot) |

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / VS Code
- XAMPP (for local server)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yt02/workers_tasks_management_system.git
```

2. Navigate to the project directory:
```bash
cd workers_tasks_management_system
```

3. Install dependencies:
```bash
flutter pub get
```

4. Set up the local server:
   - Install XAMPP
   - Place the PHP files in the htdocs directory
   - Start Apache and MySQL services
     ![XAMPP Setup](https://github.com/user-attachments/assets/9d6094bf-0eef-41b7-9ea4-76fb5f74e787)

## Database Setup

### Database Structure

The application uses MySQL database with the following structure:

```sql
CREATE DATABASE IF NOT EXISTS workers_tasks_db;
USE workers_tasks_db;

   CREATE TABLE IF NOT EXISTS workers (
      id INT AUTO_INCREMENT PRIMARY KEY,
      full_name VARCHAR(100) NOT NULL,
      email VARCHAR(100) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      phone VARCHAR(20) NOT NULL,
      address TEXT NOT NULL,
      profile_image VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

### Database Configuration

1. Open phpMyAdmin in your XAMPP installation
2. Create a new database named `workers_tasks_db`
3. Import the SQL files:
   - `api/create_workers_table.sql`
   - `api/create_works_tables.sql`

5. Run the application:
```bash
flutter run
```

## Features in Detail

### User Authentication
- **Login Screen**
  - Email validation
  - Password visibility toggle
  - Error handling with user-friendly messages
  - Session persistence
  - Automatic login for existing sessions

- **Registration Screen**
  - Form validation for all fields
  - Optional profile picture upload
  - Password visibility toggle
  - Phone number validation
  - Multiline address input

### Task Management
- **Task List Screen**
  - View all assigned tasks
  - Task status indicators (pending/completed)
  - Due date tracking
  - Submission management
  - Edit submission functionality
  - Pull-to-refresh
  - Profile quick access

- **Submit Work Screen**
  - Submit new work
  - Edit existing submissions
  - Success feedback
  - Form validation

### Profile Management
- **Profile Screen**
  - Display worker information
  - Profile picture display
  - Task statistics overview
  - Quick access to task list
  - Secure logout with confirmation
  - Session management

### Security Features
- Password hashing using SHA1
- Session management using SharedPreferences
- Form validation on both client and server side
- Secure file upload handling
- Input sanitization
- Confirmation dialogs for important actions

### UI/UX Features
- Gradient backgrounds
- Card-based layouts
- Smooth animations
- Loading indicators
- Error message displays
- Responsive design
- Modern form inputs with icons
- Password visibility toggle
- Profile picture upload preview
- Task status color coding
- Interactive task cards
- Pull-to-refresh functionality
- Confirmation dialogs
- Profile dropdown menu

## API Endpoints

The application uses the following API endpoints:
- Login: `$baseUrl/api/login_worker.php`
- Registration: `$baseUrl/api/register_worker.php`
- Get Works: `$baseUrl/api/get_works.php`
- Submit Work: `$baseUrl/api/submit_work.php`

## API Configuration

The application uses a centralized configuration system located in `lib/config/app_config.dart`. This makes it easy to modify the base URL and API endpoints across the application.

### Changing the IP Address

To change the IP address or base URL of the application:

1. Open `lib/config/app_config.dart`
2. Locate the `baseUrl` constant:
```dart
static const String baseUrl = 'http://10.0.2.2';
```
3. Update the IP address to your desired value.

For different environments:
- **Android Emulator**: Use `10.0.2.2`
- **Physical Android Device**: Use your computer's local IP address
- **iOS Simulator**: Use `localhost` or `127.0.0.1`
- **Production**: Use your actual server domain/IP





