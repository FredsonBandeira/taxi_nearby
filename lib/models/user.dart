// lib/models/user.dart
enum UserRole { passenger, driver, admin }

enum PaymentMethod { cash, card, mobile_money, bank_transfer }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  
  // Perfil
  final String? photoUrl;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  
  // Verificação
  final bool isVerified;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  
  // Preferências
  final String? preferredLanguage;
  final String? preferredCurrency;
  final bool notificationsEnabled;
  final bool locationSharingEnabled;
  
  // Pagamento
  final List<PaymentMethod> availablePaymentMethods;
  final PaymentMethod? defaultPaymentMethod;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  
  // Status
  final bool isActive;
  final String? fcmToken; // Para notificações push

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.address,
    this.city,
    this.country = 'Cabo Verde',
    this.postalCode,
    this.isVerified = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.preferredLanguage = 'pt',
    this.preferredCurrency = 'CVE',
    this.notificationsEnabled = true,
    this.locationSharingEnabled = true,
    this.availablePaymentMethods = const [PaymentMethod.cash],
    this.defaultPaymentMethod,
    DateTime? createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
    this.fcmToken,
  }) : createdAt = createdAt ?? DateTime.now();

  // === SERIALIZAÇÃO ===
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'photoUrl': photoUrl,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'notificationsEnabled': notificationsEnabled,
      'locationSharingEnabled': locationSharingEnabled,
      'availablePaymentMethods': availablePaymentMethods
          .map((m) => m.toString().split('.').last)
          .toList(),
      'defaultPaymentMethod': defaultPaymentMethod?.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] == 'driver' ? UserRole.driver : UserRole.passenger,
      photoUrl: map['photoUrl'],
      address: map['address'],
      city: map['city'],
      country: map['country'] ?? 'Cabo Verde',
      postalCode: map['postalCode'],
      isVerified: map['isVerified'] ?? false,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      preferredLanguage: map['preferredLanguage'] ?? 'pt',
      preferredCurrency: map['preferredCurrency'] ?? 'CVE',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      locationSharingEnabled: map['locationSharingEnabled'] ?? true,
      availablePaymentMethods: (map['availablePaymentMethods'] as List?)
              ?.map((m) => PaymentMethod.values.firstWhere(
                    (e) => e.toString().split('.').last == m,
                    orElse: () => PaymentMethod.cash,
                  ))
              .toList() ??
          [PaymentMethod.cash],
      defaultPaymentMethod: map['defaultPaymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == map['defaultPaymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.parse(map['lastLoginAt']) 
          : null,
      isActive: map['isActive'] ?? true,
      fcmToken: map['fcmToken'],
    );
  }

  // === COPYWITH (Imutabilidade) ===
  
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? photoUrl,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    bool? isVerified,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? preferredLanguage,
    String? preferredCurrency,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
    List<PaymentMethod>? availablePaymentMethods,
    PaymentMethod? defaultPaymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      availablePaymentMethods: availablePaymentMethods ?? this.availablePaymentMethods,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // === HELPERS ===
  
  String get displayName => name.isEmpty ? email.split('@').first : name;
  
  String get initials {
    final names = name.trim().split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names.last[0]}'.toUpperCase();
  }

  String get roleLabel {
    switch (role) {
      case UserRole.passenger: return 'Passageiro';
      case UserRole.driver: return 'Motorista';
      case UserRole.admin: return 'Administrador';

    }
  }

  String get paymentMethodLabel {
    switch (defaultPaymentMethod) {
      case PaymentMethod.cash: return 'Dinheiro';
      case PaymentMethod.card: return 'Cartão';
      case PaymentMethod.mobile_money: return 'Mobile Money';
      case PaymentMethod.bank_transfer: return 'Transferência';
      case null: return 'Não definido';
    }
  }

  bool get isComplete {
    return name.isNotEmpty && 
           phone.isNotEmpty && 
           (address?.isNotEmpty ?? false) &&
           isPhoneVerified;
  }

  int get completionPercentage {
    int score = 0;
    if (name.isNotEmpty) score += 20;
    if (email.isNotEmpty) score += 10;
    if (phone.isNotEmpty) score += 20;
    if (address?.isNotEmpty ?? false) score += 15;
    if (city?.isNotEmpty ?? false) score += 10;
    if (photoUrl != null) score += 10;
    if (isVerified) score += 15;
    return score;
  }

  // === VALIDAÇÃO ===
  
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email é obrigatório';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'Telefone é obrigatório';
    if (phone.length < 8) return 'Telefone muito curto';
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Nome é obrigatório';
    if (name.trim().length < 2) return 'Nome muito curto';
    return null;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $roleLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}