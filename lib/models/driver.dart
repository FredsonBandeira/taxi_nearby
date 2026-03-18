// lib/models/driver.dart
import 'user.dart';

class DriverModel extends UserModel {
  final String vehicleModel;
  final String licensePlate;
  final String color;
  final int year;
  final String? vehiclePhotoUrl;
  bool isAvailable;
  double latitude;
  double longitude;
  double rating;
  int totalRides;

  DriverModel({
    required String id,
    required String name,
    required String email,
    required String phone,
    required this.vehicleModel,
    required this.licensePlate,
    required this.color,
    required this.year,
    this.vehiclePhotoUrl,
    this.isAvailable = false,
    this.latitude = 16.7421003,
    this.longitude = -22.9349121,
    this.rating = 4.8,
    this.totalRides = 0,
    String? photoUrl,
    String? address,
    String? city,
    String? country,
    DateTime? createdAt,
    bool isVerified = false,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          role: UserRole.driver,
          photoUrl: photoUrl,
          address: address,
          city: city,
          country: country,
          createdAt: createdAt,
          isVerified: isVerified,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'vehicleModel': vehicleModel,
      'licensePlate': licensePlate,
      'color': color,
      'year': year,
      'vehiclePhotoUrl': vehiclePhotoUrl,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalRides': totalRides,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      vehicleModel: map['vehicleModel'] ?? 'Toyota Corolla',
      licensePlate: map['licensePlate'] ?? 'CV-00-00',
      color: map['color'] ?? 'Amarelo',
      year: map['year'] ?? 2020,
      vehiclePhotoUrl: map['vehiclePhotoUrl'],
      isAvailable: map['isAvailable'] ?? false,
      latitude: map['latitude']?.toDouble() ?? 16.7421003,
      longitude: map['longitude']?.toDouble() ?? -22.9349121,
      rating: map['rating']?.toDouble() ?? 4.8,
      totalRides: map['totalRides'] ?? 0,
      photoUrl: map['photoUrl'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      isVerified: map['isVerified'] ?? false,
    );
  }
  
  DriverModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    String? city,
    String? country,
    DateTime? createdAt,
    bool? isVerified,
    // UserModel fields
    List<PaymentMethod>? availablePaymentMethods,
    PaymentMethod? defaultPaymentMethod,
    String? fcmToken,
    bool? isActive,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? lastLoginAt,
    bool? locationSharingEnabled,
    bool? notificationsEnabled,
    String? postalCode,
    String? preferredCurrency,
    String? preferredLanguage,
    UserRole? role,
    DateTime? updatedAt,
    // DriverModel fields
    String? vehicleModel,
    String? licensePlate,
    String? color,
    int? year,
    String? vehiclePhotoUrl,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalRides,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      year: year ?? this.year,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get vehicleFullInfo => '$year $vehicleModel $color';
}