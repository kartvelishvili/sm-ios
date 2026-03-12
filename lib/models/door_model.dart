class ElevatorPin {
  final String pin;
  final String updatedAt;
  final String? nextRotation;
  final String? info;

  ElevatorPin({
    required this.pin,
    required this.updatedAt,
    this.nextRotation,
    this.info,
  });

  factory ElevatorPin.fromJson(Map<String, dynamic> json) {
    return ElevatorPin(
      pin: json['pin'] as String? ?? '----',
      updatedAt: json['updated_at'] as String? ?? '',
      nextRotation: json['next_rotation'] as String?,
      info: json['info'] as String?,
    );
  }
}

class DoorItem {
  final int id;
  final String name;
  final String type; // 'door' or 'elevator'
  final String? building;
  final String? floor;
  final bool hasAccess;
  final String accessReason;
  final int? graceDaysLeft;
  final bool isAdminLocked;

  DoorItem({
    required this.id,
    required this.name,
    required this.type,
    this.building,
    this.floor,
    required this.hasAccess,
    required this.accessReason,
    this.graceDaysLeft,
    this.isAdminLocked = false,
  });

  bool get isDoor => type == 'door';
  bool get isElevator => type == 'elevator';

  String get typeLabel => isElevator ? 'ლიფტი' : 'კარი';

  String get accessReasonLabel {
    switch (accessReason) {
      case 'paid':
        return 'გადახდილი';
      case 'grace_period':
        return 'Grace Period';
      case 'blocked':
        return 'დაბლოკილი';
      case 'never_paid':
        return 'გადაუხდელი';
      case 'admin_locked':
        return 'ადმინის მიერ დაბლოკილი';
      default:
        return accessReason;
    }
  }

  factory DoorItem.fromJson(Map<String, dynamic> json) {
    return DoorItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['door_type'] as String? ?? json['type'] as String? ?? 'door',
      building: json['location'] as String? ?? json['building'] as String?,
      floor: json['floor']?.toString(),
      hasAccess: json['can_open'] == true || json['has_access'] == true,
      accessReason: json['reason'] as String? ?? json['access_reason'] as String? ?? '',
      graceDaysLeft: json['grace_days_left'] as int?,
      isAdminLocked: json['admin_mode'] == 'alwaysClose' || json['is_admin_locked'] == true,
    );
  }
}
