import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';
import '../models/models.dart';

class AdminRepository {
  AdminRepository(this.client);
  final SupabaseClient client;

  Future<List<ServiceItem>> services() async {
    final rows = await client.rpc('admin_list_services');
    return (rows as List)
        .map<ServiceItem>((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ServiceItem> upsertService({
    String? id,
    required String name,
    required String description,
    required String imageUrl,
    required bool enabled,
  }) async {
    final row = await client.rpc('admin_upsert_service', params: {
      'p_id': id,
      'p_name': name,
      'p_description': description,
      'p_image_url': imageUrl,
      'p_enabled': enabled,
    });
    return ServiceItem.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<List<LocationItem>> locations() async {
    final rows = await client.rpc('admin_list_locations');
    return (rows as List)
        .map<LocationItem>((e) => LocationItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<LocationItem> upsertLocation({
    String? id,
    required String name,
    required String city,
    required String governorate,
    required bool enabled,
  }) async {
    final row = await client.rpc('admin_upsert_location', params: {
      'p_id': id,
      'p_name': name,
      'p_city': city,
      'p_governorate': governorate,
      'p_enabled': enabled,
    });
    return LocationItem.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<List<String>> serviceLocationIds(String serviceId) async {
    final rows = await client.rpc('admin_service_location_ids', params: {'p_service_id': serviceId});
    return (rows as List).map((e) => e.toString()).toList();
  }

  Future<void> linkServiceLocation(String serviceId, String locationId) async {
    await client.rpc('admin_link_service_location', params: {
      'p_service_id': serviceId,
      'p_location_id': locationId,
    });
  }

  Future<void> unlinkServiceLocation(String serviceId, String locationId) async {
    await client.rpc('admin_unlink_service_location', params: {
      'p_service_id': serviceId,
      'p_location_id': locationId,
    });
  }

  Future<List<SlotAdminItem>> slots({String? serviceId, String? locationId}) async {
    final rows = await client.rpc('admin_list_slots', params: {
      'p_service_id': serviceId,
      'p_location_id': locationId,
    });
    return (rows as List)
        .map<SlotAdminItem>((e) => SlotAdminItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> upsertSlot({
    String? id,
    required String serviceId,
    required String locationId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    required bool enabled,
  }) async {
    await client.rpc('admin_upsert_slot', params: {
      'p_id': id,
      'p_service_id': serviceId,
      'p_location_id': locationId,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
      'p_ends_at': endsAt.toUtc().toIso8601String(),
      'p_capacity': capacity,
      'p_enabled': enabled,
    });
  }

  Future<void> deleteSlot(String id) async {
    await client.rpc('admin_delete_slot', params: {'p_id': id});
  }

  Future<List<UserAccount>> users({String? role}) async {
    final rows = await client.rpc('admin_list_users', params: {'p_role': role});
    return (rows as List)
        .map<UserAccount>((e) => UserAccount.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> setUserRole(String userId, String role) async {
    await client.rpc('admin_set_user_role', params: {'p_user_id': userId, 'p_role': role});
  }

  Future<List<ProviderAssignment>> providerAssignments() async {
    final rows = await client.rpc('admin_list_provider_assignments');
    return (rows as List)
        .map<ProviderAssignment>((e) => ProviderAssignment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> upsertProviderAssignment({
    int? id,
    required String serviceId,
    required String locationId,
    required String providerId,
    required String bookingMode,
  }) async {
    await client.rpc('admin_upsert_provider_assignment', params: {
      'p_id': id,
      'p_service_id': serviceId,
      'p_location_id': locationId,
      'p_provider_id': providerId,
      'p_booking_mode': bookingMode,
    });
  }

  Future<void> deleteProviderAssignment(int id) async {
    await client.rpc('admin_delete_provider_assignment', params: {'p_id': id});
  }

  Future<List<AdminBookingRow>> bookings({String? status}) async {
    final rows = await client.rpc('admin_list_bookings', params: {'p_status': status});
    return (rows as List)
        .map<AdminBookingRow>((e) => AdminBookingRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
