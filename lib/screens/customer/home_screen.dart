import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/glass_container.dart';
import 'booking_flow.dart';
import 'my_bookings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.repository,
  });

  final ApiClient api;
  final AppRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<ServiceItem> _services = <ServiceItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final services = await widget.repository.services();
      if (!mounted) return;
      setState(() => _services = services);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_tab == 0) {
      body = _homeBody();
    } else if (_tab == 1) {
      body = MyBookingsScreen(repository: widget.repository);
    } else {
      body = _profile();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(child: SafeArea(child: body)),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: NavigationBar(
            backgroundColor: AppColors.ink.withValues(alpha: 0.72),
            indicatorColor: AppColors.orange,
            selectedIndex: _tab,
            onDestinationSelected: (value) {
              setState(() => _tab = value);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeBody() {
    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Service Booking',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassContainer(
            padding: const EdgeInsets.all(22),
            tint: AppColors.ink,
            opacity: 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'What do you need today?',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a service, location and time.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      hintText: 'Search services',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: false,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Popular services',
            style: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _messageCard(_error!)
          else if (_services.isEmpty)
            _messageCard('No services available yet.')
          else
            ..._services.map(_serviceCard),
          const SizedBox(height: 12),
          const Text(
            'Available slots update in real time.',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(ServiceItem service) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingFlow(
              repository: widget.repository,
              service: service,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(18),
          tint: AppColors.ink,
          opacity: 0.55,
          child: SizedBox(
            height: 90,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (service.description.isNotEmpty)
                    Text(
                      service.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profile() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        _profileTile(Icons.person_outline, 'Personal details'),
        _profileTile(Icons.location_on_outlined, 'Governorate & city'),
        _profileTile(Icons.notifications_none, 'Notifications'),
        _profileTile(
          Icons.logout,
          'Sign out',
          onTap: () => widget.api.signOut(),
        ),
      ],
    );
  }

  Widget _profileTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 20,
        padding: EdgeInsets.zero,
        tint: AppColors.ink,
        opacity: 0.55,
        child: ListTile(
          leading: Icon(icon, color: AppColors.orange),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _messageCard(String message) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      child: Text(message, style: const TextStyle(color: AppColors.ink)),
    );
  }
}
