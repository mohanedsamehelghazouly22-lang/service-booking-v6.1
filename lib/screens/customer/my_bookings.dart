import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<BookingItem> _items = <BookingItem>[];
  bool _loading = true;
  String? _error;
  String? _cancellingId;

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
      final items = await widget.repository.myBookings();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancel(BookingItem booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking'),
        content: Text('Cancel your booking for ${booking.serviceName}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancellingId = booking.id);
    try {
      await widget.repository.cancelBooking(booking.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _cancellingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'My Bookings',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _messageCard(_error!)
          else if (_items.isEmpty)
            _messageCard('Your bookings will appear here.')
          else
            ..._items.map(_bookingCard),
        ],
      ),
    );
  }

  Widget _bookingCard(BookingItem booking) {
    final cancellable = booking.status == 'pending' || booking.status == 'confirmed';
    final isCancelling = _cancellingId == booking.id;

    return Card(
      color: AppColors.ink,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          booking.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${booking.locationName}\n${booking.date} • ${booking.time}',
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                booking.status,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (cancellable)
                isCancelling
                    ? const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () => _cancel(booking),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageCard(String message) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(message),
    );
  }
}
