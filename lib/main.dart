import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'repositories/admin_repository.dart';
import 'repositories/app_repository.dart';
import 'repositories/provider_repository.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/provider/provider_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (url.isEmpty || publishableKey.isEmpty) {
    runApp(const _ConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
  );

  runApp(const ServiceBookingApp());
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        backgroundColor: AppColors.peach,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: AppColors.ink,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: const Text(
                  'Supabase configuration is missing.\n\nBuild with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceBookingApp extends StatelessWidget {
  const ServiceBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final api = ApiClient();
    final repository = AppRepository(client);
    final adminRepository = AdminRepository(client);
    final providerRepository = ProviderRepository(client);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Service Booking',
      theme: buildTheme(),
      home: _SessionGate(
        api: api,
        repository: repository,
        adminRepository: adminRepository,
        providerRepository: providerRepository,
      ),
      // '/home' stays a named route only for the explicit "Browse as guest"
      // path, which never creates a session. Signed-in users (customer,
      // provider or admin) are routed reactively by _SessionGate below,
      // based on their actual role in public.users — not by a fixed route.
      routes: {
        '/home': (_) => HomeScreen(api: api, repository: repository),
      },
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate({
    required this.api,
    required this.repository,
    required this.adminRepository,
    required this.providerRepository,
  });

  final ApiClient api;
  final AppRepository repository;
  final AdminRepository adminRepository;
  final ProviderRepository providerRepository;

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Stream<AuthState> _authStream;
  String? _lastUserId;
  Future<String?>? _roleFuture;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _lastUserId = session.user.id;
      _roleFuture = _loadRole();
    }
  }

  Future<String?> _loadRole() async {
    try {
      final profile = await widget.repository.profile();
      return profile['role']?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          _lastUserId = null;
          _roleFuture = null;
          return LoginScreen(api: widget.api, repository: widget.repository);
        }

        if (_lastUserId != session.user.id || _roleFuture == null) {
          _lastUserId = session.user.id;
          _roleFuture = _loadRole();
        }

        return FutureBuilder<String?>(
          future: _roleFuture,
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                backgroundColor: AppColors.peach,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            switch (roleSnapshot.data) {
              case 'admin':
                return AdminDashboard(repository: widget.adminRepository);
              case 'provider':
                return ProviderDashboard(repository: widget.providerRepository);
              default:
                return HomeScreen(api: widget.api, repository: widget.repository);
            }
          },
        );
      },
    );
  }
}
