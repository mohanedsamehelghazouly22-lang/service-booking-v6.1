import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';

class ProviderRepository {
  ProviderRepository(this.client);
  final SupabaseClient client;

  Future<List<ProviderBookingRow>> bookings({String? status}) async {
    final rows = await client.rpc('provider_bookings', params: {'p_status': status});
    return (rows as List)
        .map<ProviderBookingRow>((e) => ProviderBookingRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> confirmBooking(String id) async {
    await client.rpc('provider_confirm_booking', params: {'p_booking_id': id});
  }

  Future<void> cancelBooking(String id, String reason) async {
    await client.rpc('provider_cancel_booking', params: {'p_booking_id': id, 'p_reason': reason});
  }

  Future<List<ProviderAssignedLocation>> assignedLocations() async {
    final rows = await client.rpc('provider_assigned_locations');
    return (rows as List)
        .map<ProviderAssignedLocation>((e) => ProviderAssignedLocation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
