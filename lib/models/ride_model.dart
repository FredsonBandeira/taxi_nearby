// lib/models/ride_model.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum RideStatus { requested, accepted, in_progress, completed, cancelled }

class RideModel {
  final String id;
  final String passengerId;
  final String? driverId;
  final String? driverName;
  final String? vehicleInfo;
  final double pickupLat;
  final double pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final RideStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final double? fare;
  final String? paymentMethod;
  final int? rating;
  final String? notes;

  RideModel({
    String? id,
    required this.passengerId,
    this.driverId,
    this.driverName,
    this.vehicleInfo,
    required this.pickupLat,
    required this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.status = RideStatus.requested,
    DateTime? requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.fare,
    this.paymentMethod,
    this.rating,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerId': passengerId,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleInfo': vehicleInfo,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'status': status.toString().split('.').last,
      'requestedAt': requestedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'fare': fare,
      'paymentMethod': paymentMethod,
      'rating': rating,
      'notes': notes,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['id'],
      passengerId: map['passengerId'],
      driverId: map['driverId'],
      driverName: map['driverName'],
      vehicleInfo: map['vehicleInfo'],
      pickupLat: map['pickupLat']?.toDouble() ?? 0,
      pickupLng: map['pickupLng']?.toDouble() ?? 0,
      dropoffLat: map['dropoffLat']?.toDouble(),
      dropoffLng: map['dropoffLng']?.toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => RideStatus.requested,
      ),
      requestedAt: DateTime.parse(map['requestedAt']),
      acceptedAt: map['acceptedAt'] != null ? DateTime.parse(map['acceptedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      fare: map['fare']?.toDouble(),
      paymentMethod: map['paymentMethod'],
      rating: map['rating'],
      notes: map['notes'],
    );
  }

  // === COPIWITH (ADICIONADO) ===
  RideModel copyWith({
    String? id,
    String? passengerId,
    String? driverId,
    String? driverName,
    String? vehicleInfo,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    RideStatus? status,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    double? fare,
    String? paymentMethod,
    int? rating,
    String? notes,
  }) {
    return RideModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      fare: fare ?? this.fare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  // === HELPERS ===
  bool get isCompleted => status == RideStatus.completed;
  bool get isCancelled => status == RideStatus.cancelled;
  
  String get statusLabel {
    switch (status) {
      case RideStatus.requested: return 'Solicitada';
      case RideStatus.accepted: return 'Aceita';
      case RideStatus.in_progress: return 'Em andamento';
      case RideStatus.completed: return 'Concluída';
      case RideStatus.cancelled: return 'Cancelada';
    }
  }

  Color get statusColor {
    switch (status) {
      case RideStatus.requested: return Colors.orange;
      case RideStatus.accepted: return Colors.blue;
      case RideStatus.in_progress: return Colors.purple;
      case RideStatus.completed: return Colors.green;
      case RideStatus.cancelled: return Colors.red;
    }
  }
}