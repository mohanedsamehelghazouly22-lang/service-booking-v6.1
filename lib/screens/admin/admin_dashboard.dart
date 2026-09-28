import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../repositories/admin_repository.dart';
import 'admin_bookings_screen.dart';
import 'admin_locations_screen.dart';
import 'admin_provider_assignments_screen.dart';
import 'admin_services_screen.dart';
import 'admin_slots_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Admin console',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: AppColors.ink),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _tile(
            context,
            'Services',
            Icons.home_repair_service,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminServicesScreen(repository: repository)),
            ),
          ),
          _tile(
            context,
            'Locations',
            Icons.location_city,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminLocationsScreen(repository: repository)),
            ),
          ),
          _tile(
            context,
            'Availability',
            Icons.schedule,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminSlotsScreen(repository: repository)),
            ),
          ),
          _tile(
            context,
            'Provider assignments',
            Icons.assignment_ind,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminProviderAssignmentsScreen(repository: repository)),
            ),
          ),
          _tile(
            context,
            'Users & roles',
            Icons.manage_accounts,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminUsersScreen(repository: repository)),
            ),
          ),
          _tile(
            context,
            'Bookings',
            Icons.receipt_long,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminBookingsScreen(repository: repository)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.orange, size: 32),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
