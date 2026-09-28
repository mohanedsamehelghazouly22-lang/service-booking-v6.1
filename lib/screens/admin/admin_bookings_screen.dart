import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  static const _statuses = <String>['All', 'pending', 'confirmed', 'cancelled'];
  String _filter = 'All';
  List<AdminBookingRow> _items = <AdminBookingRow>[];
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
      final items = await widget.repository.bookings(status: _filter == 'All' ? null : _filter);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: const Text('Bookings', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: _statuses
                  .map((status) => ChoiceChip(
                        label: Text(status),
                        selected: _filter == status,
                        onSelected: (_) {
                          setState(() => _filter = status);
                          _load();
                        },
                      ))
                  .toList(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _items.isEmpty
                          ? const [Text('No bookings found.', style: TextStyle(color: AppColors.ink))]
                          : _items
                              .map((booking) => Card(
                                    color: AppColors.ink,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      title: Text('${booking.serviceName} @ ${booking.locationName}'),
                                      subtitle: Text('${booking.customerName}\n${booking.startsAt?.toLocal() ?? ''}'),
                                      isThreeLine: true,
                                      trailing: Chip(label: Text(booking.status)),
                                    ),
                                  ))
                              .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
