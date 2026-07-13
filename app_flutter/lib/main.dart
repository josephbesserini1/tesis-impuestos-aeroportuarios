import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin/login_admin_screen.dart';
import 'screens/admin/update_password_screen.dart';
import 'screens/consulta_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialPasswordRecovery = isPasswordRecoveryUri(Uri.base);

  await Supabase.initialize(
    url: 'https://ikcvhwtydiganghvftvi.supabase.co',
    publishableKey: 'sb_publishable_kyoVdqx22v4pmB1YNw1XTQ_og3alADa',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(
    MyApp(
      authStateChanges: supabase.auth.onAuthStateChange,
      initialPasswordRecovery: initialPasswordRecovery,
    ),
  );
}

final supabase = Supabase.instance.client;

bool isPasswordRecoveryUri(Uri uri) {
  if (uri.queryParameters['type'] == 'recovery') return true;
  if (uri.fragment.isEmpty) return false;

  try {
    return Uri.splitQueryString(uri.fragment)['type'] == 'recovery';
  } on FormatException {
    return false;
  }
}

class MyApp extends StatefulWidget {
  final Stream<AuthState> authStateChanges;
  final bool initialPasswordRecovery;

  const MyApp({
    super.key,
    this.authStateChanges = const Stream<AuthState>.empty(),
    this.initialPasswordRecovery = false,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveryScreenVisible = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = widget.authStateChanges.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Supabase Auth: $error\n$stackTrace');
      },
    );

    if (widget.initialPasswordRecovery) {
      _showPasswordRecovery();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleAuthStateChange(AuthState state) {
    if (state.event != AuthChangeEvent.passwordRecovery) return;
    _showPasswordRecovery();
  }

  void _showPasswordRecovery() {
    if (_recoveryScreenVisible) return;

    _recoveryScreenVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _recoveryScreenVisible = false;
        return;
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => UpdatePasswordScreen(
            onCompleted: () => _recoveryScreenVisible = false,
          ),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Kiosco Impuestos Aeroportuarios',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Kiosco de impuestos\naeroportuarios',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consulta y paga los impuestos pendientes de tu aeronave de forma rápida y segura.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prueba de actualización para iPhone',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              const SizedBox(height: 40),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConsultaScreen()),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Consultar impuestos'),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginAdminScreen()),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Acceso administrativo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
