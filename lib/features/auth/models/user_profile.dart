// lib/data/models/user_profile.dart

import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String role;
  final String? area;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? phone;

  const UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    required this.role,
    this.area,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        fullName: json['full_name'] as String?,
        role: json['role'] as String? ?? 'vendedor',
        area: json['area'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        phone: json['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'area': area,
        'is_active': isActive,
        'phone': phone,
      };

  String get displayName {
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return '$firstName ${lastName ?? ''}'.trim();
    }
    if (fullName != null && fullName!.trim().isNotEmpty && fullName != email) {
      return fullName!;
    }
    return email;
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        fullName,
        role,
        area,
        isActive,
        phone,
      ];
}
