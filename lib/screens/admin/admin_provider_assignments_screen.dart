import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../repositories/admin_repository.dart';

class AdminProviderAssignmentsScreen extends StatefulWidget {
  const AdminProviderAssignmentsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<AdminProviderAssignmentsScreen> createState() => _AdminProviderAssignmentsScreenState();
}

class _AdminProviderAssignmentsScreenState extends State<AdminProviderAssignmentsScreen> {
  List<ProviderAssignment> _items = <ProviderAssignment>[];
  List<ServiceItem> _services = <ServiceItem>[];
  List<LocationItem> _locations = <LocationItem>[];
  List<UserAccount> _providers = <UserAccount>[];
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
      final assignments = await widget.repository.providerAssignments();
      final services = await widget.repository.services();
      final locations = await widget.repository.locations();
      final providers = await widget.repository.users(role: 'provider');
      if (!mounted) return;
      setState(() {
        _items = assignments;
        _services = services;
        _locations = locations;
        _providers = providers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_services.isEmpty || _locations.isEmpty || _providers.isEmpty) {
      setState(() => _error = 'Add a service, a location, and a provider account first.');
      return;
    }

    String serviceId = _services.first.id;
    String locationId = _locations.first.id;
    String providerId = _providers.first.id;
    String bookingMode = 'pending';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: serviceId,
                  decoration: const InputDecoration(labelText: 'Service'),
                  items: _services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (value) => setDialogState(() => serviceId = value ?? serviceId),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: locationId,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                  onChanged: (value) => setDialogState(() => locationId = value ?? locationId),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: providerId,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: _providers
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.fullName.isEmpty ? p.phone : p.fullName),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => providerId = value ?? providerId),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: bookingMode,
                  decoration: const InputDecoration(labelText: 'Booking mode'),
                  items: const [
                    DropdownMenuItem(value: 'instant', child: Text('Instant confirm')),
                    DropdownMenuItem(value: 'pending', child: Text('Needs provider confirmation')),
                  ],
                  onChanged: (value) => setDialogState(() => bookingMode = value ?? bookingMode),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await widget.repository.upsertProviderAssignment(
        serviceId: serviceId,
        locationId: locationId,
        providerId: providerId,
        bookingMode: bookingMode,
      );
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _delete(ProviderAssignment assignment) async {
    try {
      await widget.repository.deleteProviderAssignment(assignment.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Provider assignments',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        actions: [IconButton(onPressed: _add, icon: const Icon(Icons.add))],
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
                  if (_items.isEmpty)
                    const Text('No assignments yet.', style: TextStyle(color: AppColors.ink)),
                  ..._items.map((assignment) => Card(
                        color: AppColors.ink,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text('${assignment.serviceName} @ ${assignment.locationName}'),
                          subtitle: Text('${assignment.providerName} • ${assignment.bookingMode}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _delete(assignment),
                          ),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}
