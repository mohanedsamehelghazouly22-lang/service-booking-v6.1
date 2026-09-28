import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _roles = <String>['All', 'customer', 'provider', 'admin'];
  String _filter = 'All';
  List<UserAccount> _items = <UserAccount>[];
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
      final items = await widget.repository.users(role: _filter == 'All' ? null : _filter);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(UserAccount user) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Role for ${user.fullName.isEmpty ? user.phone : user.fullName}'),
        children: ['customer', 'provider', 'admin']
            .map((role) => SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(role),
                  child: Text(role),
                ))
            .toList(),
      ),
    );

    if (selected == null || selected == user.role) return;

    try {
      await widget.repository.setUserRole(user.id, selected);
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
        title: const Text('Users & roles', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: _roles
                  .map((role) => ChoiceChip(
                        label: Text(role),
                        selected: _filter == role,
                        onSelected: (_) {
                          setState(() => _filter = role);
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
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _items.isEmpty
                        ? const [Text('No users found.', style: TextStyle(color: AppColors.ink))]
                        : _items
                            .map((user) => Card(
                                  color: AppColors.ink,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text(user.fullName.isEmpty ? 'Unnamed' : user.fullName),
                                    subtitle: Text(user.phone.isEmpty ? user.email : user.phone),
                                    trailing: Chip(label: Text(user.role)),
                                    onTap: () => _changeRole(user),
                                  ),
                                ))
                            .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
