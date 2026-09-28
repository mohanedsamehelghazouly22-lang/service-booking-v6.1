import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../repositories/provider_repository.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key, required this.repository});
  final ProviderRepository repository;

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  List<ProviderBookingRow> _bookings = <ProviderBookingRow>[];
  List<ProviderAssignedLocation> _assignments = <ProviderAssignedLocation>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await widget.repository.bookings();
      final assignments = await widget.repository.assignedLocations();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _assignments = assignments;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(ProviderBookingRow booking) async {
    try {
      await widget.repository.confirmBooking(booking.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _cancel(ProviderBookingRow booking) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason (required)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Cancel booking')),
        ],
      ),
    );

    if (confirmed != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'A cancellation reason is required.');
      return;
    }

    try {
      await widget.repository.cancelBooking(booking.id, reason);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _bookings.where((b) => b.status == 'pending').length;
    final todayCount = _bookings.where((b) {
      final starts = b.startsAt;
      if (starts == null) return false;
      final now = DateTime.now();
      final local = starts.toLocal();
      return local.year == now.year && local.month == now.month && local.day == now.day;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.peach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Provider dashboard',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: AppColors.ink),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  Row(
                    children: [
                      _metric('Today', '$todayCount'),
                      const SizedBox(width: 12),
                      _metric('Pending', '$pendingCount'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_assignments.isNotEmpty) ...[
                    const Text(
                      'Assigned locations',
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ..._assignments.map((a) => Card(
                          color: AppColors.ink,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.orange),
                            title: Text('${a.serviceName} @ ${a.locationName}'),
                            trailing: Chip(label: Text(a.bookingMode)),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Bookings',
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_bookings.isEmpty)
                    const Text('No bookings assigned to you yet.', style: TextStyle(color: AppColors.ink))
                  else
                    ..._bookings.map(_bookingCard),
                ],
              ),
      ),
    );
  }

  Widget _metric(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      );

  Widget _bookingCard(ProviderBookingRow booking) {
    return Card(
      color: AppColors.ink,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${booking.serviceName} @ ${booking.locationName}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${booking.customerName} • ${booking.startsAt?.toLocal() ?? ''}', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(booking.status)),
                const Spacer(),
                if (booking.status == 'pending')
                  TextButton(onPressed: () => _confirm(booking), child: const Text('Confirm')),
                if (booking.status == 'pending' || booking.status == 'confirmed')
                  TextButton(
                    onPressed: () => _cancel(booking),
                    child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
