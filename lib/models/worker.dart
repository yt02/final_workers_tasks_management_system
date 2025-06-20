class Worker {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? profileImage;
  final DateTime createdAt;
  
  // Personal Information Fields
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;
  
  // Emergency Contact Information
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  
  // Address Fields
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  
  final DateTime? updatedAt;

  Worker({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.profileImage,
    required this.createdAt,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.updatedAt,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: int.parse(json['id'].toString()),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      gender: json['gender'],
      nationality: json['nationality'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'nationality': nationality,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String get displayName => fullName.isNotEmpty ? fullName : 'No Name';
  
  String get displayGender {
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

  String get displayNationality => nationality ?? 'Not specified';
  
  String get displayCountry => country ?? 'Not specified';
  
  String get fullAddress {
    List<String> addressParts = [];
    
    if (address.isNotEmpty) addressParts.add(address);
    if (city != null && city!.isNotEmpty) addressParts.add(city!);
    if (state != null && state!.isNotEmpty) addressParts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) addressParts.add(postalCode!);
    if (country != null && country!.isNotEmpty) addressParts.add(country!);
    
    return addressParts.join(', ');
  }
  
  String? get ageString {
    if (dateOfBirth == null) return null;
    
    final now = DateTime.now();
    final age = now.year - dateOfBirth!.year;
    final hasHadBirthdayThisYear = now.month > dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day >= dateOfBirth!.day);
    
    return hasHadBirthdayThisYear ? '$age years old' : '${age - 1} years old';
  }
  
  bool get hasEmergencyContact {
    return emergencyContactName != null && 
           emergencyContactName!.isNotEmpty &&
           emergencyContactPhone != null && 
           emergencyContactPhone!.isNotEmpty;
  }
  
  String get emergencyContactDisplay {
    if (!hasEmergencyContact) return 'Not provided';
    
    String display = emergencyContactName!;
    if (emergencyContactRelationship != null && emergencyContactRelationship!.isNotEmpty) {
      display += ' (${emergencyContactRelationship!})';
    }
    display += ' - ${emergencyContactPhone!}';
    
    return display;
  }

  // Calculate profile completion percentage for personal info
  double get personalInfoCompletionPercentage {
    int totalFields = 10; // Total personal info fields
    int completedFields = 0;
    
    // Basic required fields
    if (fullName.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (phone.isNotEmpty) completedFields++;
    if (address.isNotEmpty) completedFields++;
    
    // Personal info fields
    if (dateOfBirth != null) completedFields++;
    if (gender != null && gender != 'prefer_not_to_say') completedFields++;
    if (nationality != null && nationality!.isNotEmpty) completedFields++;
    
    // Emergency contact
    if (hasEmergencyContact) completedFields++;
    
    // Address details
    if (city != null && city!.isNotEmpty) completedFields++;
    if (country != null && country!.isNotEmpty) completedFields++;
    
    return (completedFields / totalFields) * 100;
  }

  // Create a copy with updated fields
  Worker copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? profileImage,
    DateTime? createdAt,
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    DateTime? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
