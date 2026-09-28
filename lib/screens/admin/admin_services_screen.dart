import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../repositories/admin_repository.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<ServiceItem> _items = <ServiceItem>[];
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
      final items = await widget.repository.services();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editLocations(ServiceItem service) async {
    List<LocationItem> allLocations;
    Set<String> linkedIds;
    try {
      allLocations = await widget.repository.locations();
      linkedIds = (await widget.repository.serviceLocationIds(service.id)).toSet();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Locations offering ${service.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: allLocations.isEmpty
                ? const Text('Add a location first.')
                : ListView(
                    shrinkWrap: true,
                    children: allLocations
                        .map((location) => CheckboxListTile(
                              title: Text(location.name),
                              value: linkedIds.contains(location.id),
                              onChanged: (checked) async {
                                try {
                                  if (checked == true) {
                                    await widget.repository.linkServiceLocation(service.id, location.id);
                                    linkedIds.add(location.id);
                                  } else {
                                    await widget.repository.unlinkServiceLocation(service.id, location.id);
                                    linkedIds.remove(location.id);
                                  }
                                  setDialogState(() {});
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _error = e.toString());
                                }
                              },
                            ))
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  Future<void> _edit([ServiceItem? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    bool enabled = existing?.enabled ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'New service' : 'Edit service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
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
      await widget.repository.upsertService(
        id: existing?.id,
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        imageUrl: imageCtrl.text.trim(),
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
        title: const Text('Services', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
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
                    const Text('No services yet.', style: TextStyle(color: AppColors.ink)),
                  ..._items.map((service) => Card(
                        color: AppColors.ink,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(service.enabled ? 'Enabled' : 'Disabled'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.location_on_outlined),
                                onPressed: () => _editLocations(service),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(service),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}
