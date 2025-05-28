# Workers Tasks Management System

A Flutter application for managing worker tasks and profiles.

## Features

- Worker Registration
- Worker Login
- Profile Management
  - View personal information
  - Profile image upload
  - Task statistics
  - Quick access to task list
- Task Management
  - View assigned tasks
  - Submit work
  - Edit submissions
  - Track task status (pending, completed, overdue)
  - Automatic overdue status update
- Task Statistics
  - View completed tasks
  - View pending tasks
  - View overdue tasks
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

## Database Schema

### Tables

1. `tbl_workers`
   - `id` (Primary Key)
   - `full_name`
   - `email` (Unique)
   - `password`
   - `phone`
   - `address`
   - `profile_image`
   - `created_at`

2. `tbl_works`
   - `id` (Primary Key)
   - `title`
   - `description`
   - `assigned_to` (Foreign Key to tbl_workers)
   - `date_assigned`
   - `due_date`
   - `status` (pending/completed/overdue)

3. `tbl_submissions`
   - `id` (Primary Key)
   - `work_id` (Foreign Key to tbl_works)
   - `worker_id` (Foreign Key to tbl_workers)
   - `submission_text`
   - `submitted_at`

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
  - Success overlay message

### Task Management
- **Task List Screen**
  - View all assigned tasks
  - Task status indicators with color coding
    - Green: Completed
    - Orange: Pending
    - Red: Overdue
  - Due date tracking
  - Submission management
  - Edit submission functionality
  - Pull-to-refresh
  - Profile quick access
  - Automatic overdue status update

- **Submit Work Screen**
  - Submit new work
  - Edit existing submissions
  - Success feedback
  - Form validation
  - Consistent task card UI
  - Status color indicators

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

1. Open  [/lib/config/app_config.dart](/lib/config/app_config.dart)
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

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / VS Code
- XAMPP (for local server)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yt02/task_management_system_flutter.git
```

2. Navigate to the project directory:
```bash
cd task_management_system_flutter
```

3. Install dependencies:
```bash
flutter pub get
```

4. Set up the local server:
   - Install XAMPP
   - Place the `api` folder in the htdocs directory
   - Start Apache and MySQL services

5. Import the database:
   - Open phpMyAdmin
   - Create a new database named `workers_tasks_db`
   - Import the [/api/workers_tasks_db.sql](/api/workers_tasks_db.sql) file 

6. Run the application:
```bash
flutter run
```

## Screenshots

| Login Page | Register Page | Profile Page | Task List Page |
|------------|---------------|--------------|----------------|
| ![Login](https://github.com/user-attachments/assets/06aa404e-0205-4dcd-8ab0-523790c2e15c) | ![Register](https://github.com/user-attachments/assets/85ba7b6c-f422-494f-9ea9-7b60a9ae3ae8) | ![Profile](https://github.com/user-attachments/assets/03401071-5149-47e2-8a1b-2585eaa4c77d) | ![Task List](https://github.com/user-attachments/assets/your-task-list-screenshot) |





