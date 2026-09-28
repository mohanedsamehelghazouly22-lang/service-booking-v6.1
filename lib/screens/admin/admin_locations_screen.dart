import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../repositories/admin_repository.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  List<LocationItem> _items = <LocationItem>[];
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
      final items = await widget.repository.locations();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([LocationItem? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final govCtrl = TextEditingController(text: existing?.governorate ?? '');
    bool enabled = existing?.enabled ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'New location' : 'Edit location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 8),
                TextField(controller: govCtrl, decoration: const InputDecoration(labelText: 'Governorate')),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
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
    if (nameCtrl.text.trim().isEmpty) return;

    try {
      await widget.repository.upsertLocation(
        id: existing?.id,
        name: nameCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        governorate: govCtrl.text.trim(),
        enabled: enabled,
      );
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
        title: const Text('Locations', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: () => _edit(), icon: const Icon(Icons.add))],
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
                    const Text('No locations yet.', style: TextStyle(color: AppColors.ink)),
                  ..._items.map((location) => Card(
                        color: AppColors.ink,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(location.name),
                          subtitle: Text(
                            '${location.city}, ${location.governorate} • ${location.enabled ? 'Enabled' : 'Disabled'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _edit(location),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}
