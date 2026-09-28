class UserAccount {
  const UserAccount({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role;

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
    );
  }
}

class SlotAdminItem {
  const SlotAdminItem({
    required this.id,
    required this.serviceId,
    required this.locationId,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.enabled,
  });

  final String id;
  final String serviceId;
  final String locationId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final bool enabled;

  factory SlotAdminItem.fromJson(Map<String, dynamic> json) {
    return SlotAdminItem(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      locationId: json['location_id']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ?? DateTime.now(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      enabled: json['enabled'] == true,
    );
  }
}

class ProviderAssignment {
  const ProviderAssignment({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.locationId,
    required this.locationName,
    required this.providerId,
    required this.providerName,
    required this.bookingMode,
  });

  final int id;
  final String serviceId;
  final String serviceName;
  final String locationId;
  final String locationName;
  final String providerId;
  final String providerName;
  final String bookingMode;

  factory ProviderAssignment.fromJson(Map<String, dynamic> json) {
    return ProviderAssignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      locationId: json['location_id']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      providerId: json['provider_id']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? '',
      bookingMode: json['booking_mode']?.toString() ?? 'pending',
    );
  }
}

class AdminBookingRow {
  const AdminBookingRow({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.locationName,
    required this.startsAt,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final String serviceName;
  final String locationName;
  final DateTime? startsAt;
  final String status;
  final DateTime? createdAt;

  factory AdminBookingRow.fromJson(Map<String, dynamic> json) {
    return AdminBookingRow(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ProviderBookingRow {
  const ProviderBookingRow({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.locationName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.bookingMode,
  });

  final String id;
  final String customerName;
  final String serviceName;
  final String locationName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String status;
  final String bookingMode;

  factory ProviderBookingRow.fromJson(Map<String, dynamic> json) {
    return ProviderBookingRow(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'pending',
      bookingMode: json['booking_mode']?.toString() ?? 'pending',
    );
  }
}

class ProviderAssignedLocation {
  const ProviderAssignedLocation({
    required this.serviceId,
    required this.serviceName,
    required this.locationId,
    required this.locationName,
    required this.bookingMode,
  });

  final String serviceId;
  final String serviceName;
  final String locationId;
  final String locationName;
  final String bookingMode;

  factory ProviderAssignedLocation.fromJson(Map<String, dynamic> json) {
    return ProviderAssignedLocation(
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      locationId: json['location_id']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      bookingMode: json['booking_mode']?.toString() ?? 'pending',
    );
  }
}
