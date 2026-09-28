import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../repositories/admin_repository.dart';

class AdminSlotsScreen extends StatefulWidget {
  const AdminSlotsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<AdminSlotsScreen> createState() => _AdminSlotsScreenState();
}

class _AdminSlotsScreenState extends State<AdminSlotsScreen> {
  List<ServiceItem> _services = <ServiceItem>[];
  List<LocationItem> _locations = <LocationItem>[];
  List<SlotAdminItem> _slots = <SlotAdminItem>[];
  String? _serviceId;
  String? _locationId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final services = await widget.repository.services();
      final locations = await widget.repository.locations();
      if (!mounted) return;
      setState(() {
        _services = services;
        _locations = locations;
        _serviceId = services.isNotEmpty ? services.first.id : null;
        _locationId = locations.isNotEmpty ? locations.first.id : null;
      });
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_serviceId == null || _locationId == null) {
      setState(() => _slots = <SlotAdminItem>[]);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slots = await widget.repository.slots(serviceId: _serviceId, locationId: _locationId);
      if (!mounted) return;
      setState(() => _slots = slots);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSlot() async {
    if (_serviceId == null || _locationId == null) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final startTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (startTime == null || !mounted) return;

    final startsAt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
    final endsAt = startsAt.add(const Duration(hours: 1));

    final capacityCtrl = TextEditingController(text: '1');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New slot'),
        content: TextField(
          controller: capacityCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Capacity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;
    final capacity = int.tryParse(capacityCtrl.text.trim()) ?? 1;

    try {
      await widget.repository.upsertSlot(
        serviceId: _serviceId!,
        locationId: _locationId!,
        startsAt: startsAt,
        endsAt: endsAt,
        capacity: capacity,
        enabled: true,
      );
      if (!mounted) return;
      _loadSlots();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _delete(SlotAdminItem slot) async {
    try {
      await widget.repository.deleteSlot(slot.id);
      if (!mounted) return;
      _loadSlots();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        title: const Text('Availability', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _addSlot, icon: const Icon(Icons.add))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _serviceId,
            decoration: const InputDecoration(labelText: 'Service'),
            items: _services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (value) {
              setState(() => _serviceId = value);
              _loadSlots();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _locationId,
            decoration: const InputDecoration(labelText: 'Location'),
            items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
            onChanged: (value) {
              setState(() => _locationId = value);
              _loadSlots();
            },
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_slots.isEmpty)
            const Text('No slots for this service/location yet.', style: TextStyle(color: AppColors.ink))
          else
            ..._slots.map((slot) => Card(
                  color: AppColors.ink,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(_formatDateTime(slot.startsAt)),
                    subtitle: Text('Capacity ${slot.capacity} • ${slot.enabled ? 'Enabled' : 'Disabled'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _delete(slot),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
