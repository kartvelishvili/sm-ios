class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? personalId;
  final String? profileImage;
  final Complex? complex;
  final List<Apartment> apartments;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.personalId,
    this.profileImage,
    this.complex,
    this.apartments = const [],
  });

  String get fullName => '$firstName $lastName';

  String get profileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) return '';
    if (profileImage!.startsWith('http')) return profileImage!;
    return 'https://pay.smartluxy.ge$profileImage';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      personalId: json['personal_id'] as String?,
      profileImage: json['profile_image'] as String?,
      complex: json['complex'] != null
          ? Complex.fromJson(json['complex'] as Map<String, dynamic>)
          : null,
      apartments: json['apartments'] != null
          ? (json['apartments'] as List)
              .map((a) => Apartment.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'personal_id': personalId,
        'profile_image': profileImage,
        'complex': complex?.toJson(),
        'apartments': apartments.map((a) => a.toJson()).toList(),
      };
}

class Complex {
  final int id;
  final String name;
  final double monthlyFee;
  final double parkingFee;
  final int paymentDeadlineDay;
  final String? coverImage;

  Complex({
    required this.id,
    required this.name,
    required this.monthlyFee,
    required this.parkingFee,
    this.paymentDeadlineDay = 20,
    this.coverImage,
  });

  factory Complex.fromJson(Map<String, dynamic> json) {
    return Complex(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      monthlyFee: (json['monthly_fee'] as num?)?.toDouble() ?? 0,
      parkingFee: (json['parking_fee'] as num?)?.toDouble() ?? 0,
      paymentDeadlineDay: json['payment_deadline_day'] as int? ?? 20,
      coverImage: json['cover_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthly_fee': monthlyFee,
        'parking_fee': parkingFee,
        'payment_deadline_day': paymentDeadlineDay,
        'cover_image': coverImage,
      };
}

class Apartment {
  final int id;
  final String apartmentNumber;
  final String? building;
  final String? floor;
  final String? role;
  final bool isPrimary;
  final int? complexId;
  final String? complexName;

  Apartment({
    required this.id,
    required this.apartmentNumber,
    this.building,
    this.floor,
    this.role,
    this.isPrimary = false,
    this.complexId,
    this.complexName,
  });

  String get displayName {
    final parts = <String>[];
    if (building != null) parts.add('$building კორპუსი');
    parts.add('ბინა $apartmentNumber');
    if (floor != null) parts.add('სართ. $floor');
    return parts.join(', ');
  }

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'] as int,
      apartmentNumber: json['apartment_number']?.toString() ?? '',
      building: json['building']?.toString(),
      floor: json['floor']?.toString(),
      role: json['role'] as String?,
      isPrimary: json['is_primary'] == true,
      complexId: json['complex_id'] as int?,
      complexName: json['complex_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'apartment_number': apartmentNumber,
        'building': building,
        'floor': floor,
        'role': role,
        'is_primary': isPrimary,
        'complex_id': complexId,
        'complex_name': complexName,
      };
}
