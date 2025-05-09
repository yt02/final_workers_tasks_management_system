# Workers Tasks Management System

A Flutter-based mobile application for managing worker tasks and profiles. This system provides a seamless interface for workers to register, login, and manage their information.

## Features

- **User Authentication**
  - Secure login system with password visibility toggle
  - New worker registration with optional profile picture
  - Profile management with image display
  - Session persistence using SharedPreferences

- **Worker Profile Management**
  - View and manage personal information
  - Update contact details
  - Profile picture upload and display
  - Secure profile access

- **Modern UI/UX**
  - Clean and intuitive interface
  - Smooth animations and transitions
  - Responsive design
  - Password visibility toggle for better user experience
  - Form validation with user-friendly error messages

## Screenshots
<div style="width:100px">![Screenshot_1746553061](https://github.com/user-attachments/assets/1f8d3dde-18bb-42e9-bd90-2a9d380802c7)</div>

![Screenshot_1746553054](https://github.com/user-attachments/assets/01b753f4-28af-49d5-ad58-397b6c3d2407)



## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / VS Code
- XAMPP (for local server)

### Installation

1. Clone the repository:
```bash
git clone [your-repository-url]
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
   3. Import the SQL file (api/create_workers_table.sql) or run the above SQL commands
   4. The table will be created with the following fields:
      - `id`: Auto-incrementing primary key
      - `full_name`: Worker's full name (required)
      - `email`: Worker's email address (unique, required)
      - `password`: Hashed password (required)
      - `phone`: Contact number (required)
      - `address`: Worker's address (required)
      - `profile_image`: Path to profile image (optional)
      - `created_at`: Timestamp of record creation


5. Run the application:
```bash
flutter run
```

## Project Structure

```
lib/
├── screens/
│   ├── login_screen.dart
│   ├── registration_screen.dart
│   └── profile_screen.dart
├── models/
├── services/
└── main.dart
```

## API Endpoints

- Login: `http://10.0.2.2/workers_tasks_management_system/api/login_worker.php`
- Registration: `http://10.0.2.2/workers_tasks_management_system/api/register_worker.php`

### API Configuration

The application uses `10.0.2.2` as the localhost IP address when running on an Android emulator. This is because:
- `10.0.2.2` is a special alias to your host machine's loopback interface (127.0.0.1) when using Android emulator
- It allows the emulator to access services running on your development machine

For different environments, you'll need to modify the IP address:

1. **Physical Android Device**:
   - Use your computer's local IP address (e.g., `192.168.1.100`)
   - Both your device and computer must be on the same network
   - Find your IP using `ipconfig` (Windows) or `ifconfig` (Linux/Mac)

2. **iOS Simulator**:
   - Use `localhost` or `127.0.0.1` directly
   - No special IP configuration needed

3. **Production Environment**:
   - Replace with your actual server domain/IP
   - Example: `https://api.yourdomain.com`

## Features in Detail

### User Authentication
- **Login Screen**
  - Email validation
  - Password visibility toggle
  - Error handling with user-friendly messages
  - Session persistence

- **Registration Screen**
  - Form validation for all fields
  - Optional profile picture upload
  - Password visibility toggle
  - Phone number validation (digits only)
  - Multiline address input

### Profile Management
- **Profile Screen**
  - Display worker information
  - Profile picture display
  - Session management
  - Secure logout functionality

### Security Features
- Password hashing using SHA1
- Session management using SharedPreferences
- Form validation on both client and server side
- Secure file upload handling
- Input sanitization

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





