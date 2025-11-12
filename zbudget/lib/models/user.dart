class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? city;
  final String? country;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.dateOfBirth,
    this.gender,
    this.city,
    this.country,
    required this.isPremium,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Extract profile data if it exists
    final profile = json['profile'] as Map<String, dynamic>?;
    final location = profile?['location'] as Map<String, dynamic>?;

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: profile?['name'] ?? json['name'] ?? json['fullName'] ?? '',
      email: json['email'] as String,
      phone: profile?['phone'] ?? json['phone'] ?? json['phoneNumber'],
      avatar: profile?['avatar'] ?? json['avatar'] as String?,
      dateOfBirth: profile?['dateOfBirth'] != null
          ? DateTime.parse(profile!['dateOfBirth'] as String)
          : (json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : null),
      gender: profile?['gender'] ?? json['gender'] as String?,
      city: location?['city'] ?? json['city'] as String?,
      country: location?['country'] ?? json['country'] as String?,
      isPremium: json['isPremium'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'city': city,
      'country': country,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    DateTime? dateOfBirth,
    String? gender,
    String? city,
    String? country,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isPremium: $isPremium)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
