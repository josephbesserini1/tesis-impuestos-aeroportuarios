import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/usuario_admin.dart';
import '../../theme/app_theme.dart';
import 'admin_home_screen.dart';
import 'forgot_password_screen.dart';

class LoginAdminScreen extends StatefulWidget {
  final String? initialMessage;

  const LoginAdminScreen({super.key, this.initialMessage});

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  SupabaseClient get _supabase => Supabase.instance.client;

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _modoRegistro = false;
  String? _error;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _mensaje = widget.initialMessage;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  bool _validarCampos() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_modoRegistro && _nombreController.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa tu nombre completo.');
      return false;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Ingresa un correo electronico valido.');
      return false;
    }

    if (password.length < 6) {
      setState(
        () => _error = 'La contrasena debe tener al menos 6 caracteres.',
      );
      return false;
    }

    if (_modoRegistro && _confirmarPasswordController.text != password) {
      setState(() => _error = 'Las contrasenas no coinciden.');
      return false;
    }

    return true;
  }

  Future<void> _iniciarSesion() async {
    if (!_validarCampos()) return;

    setState(() {
      _cargando = true;
      _error = null;
      _mensaje = null;
    });

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('No se pudo iniciar sesion');
      }

      final usuarioAdmin = await _cargarUsuarioAdmin(userId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminHomeScreen(usuarioAdmin: usuarioAdmin),
        ),
      );
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('Invalid login credentials')) {
          _error = 'Correo o contrasena incorrectos.';
        } else if (e.message.contains('Email not confirmed')) {
          _error =
              'El correo no esta confirmado. Confirmalo en Supabase o en tu correo.';
        } else {
          _error = 'Error de Supabase: ${e.message}';
        }
        _cargando = false;
      });
    } catch (e) {
      await _supabase.auth.signOut();
      setState(() {
        _error = 'Este usuario no tiene perfil administrativo.';
        _cargando = false;
      });
    }
  }

  Future<void> _registrarUsuario() async {
    if (!_validarCampos()) return;

    setState(() {
      _cargando = true;
      _error = null;
      _mensaje = null;
    });

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'nombre': _nombreController.text.trim(), 'rol': 'operador'},
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('No se pudo crear la cuenta');
      }

      if (response.session != null) {
        await _asegurarPerfilAdmin(userId);
        final usuarioAdmin = await _cargarUsuarioAdmin(userId);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AdminHomeScreen(usuarioAdmin: usuarioAdmin),
          ),
        );
        return;
      }

      setState(() {
        _mensaje = 'Cuenta creada. Confirma el correo y luego inicia sesion.';
        _modoRegistro = false;
        _cargando = false;
        _passwordController.clear();
        _confirmarPasswordController.clear();
      });
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('already registered') ||
            e.message.contains('User already registered')) {
          _error = 'Ese correo ya esta registrado. Inicia sesion.';
          _modoRegistro = false;
        } else {
          _error = 'Error de Supabase: ${e.message}';
        }
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'No se pudo crear la cuenta. Ejecuta registro_admin_setup.sql en Supabase.';
        _cargando = false;
      });
    }
  }

  Future<UsuarioAdmin> _cargarUsuarioAdmin(String userId) async {
    final adminData = await _supabase
        .from('usuarios_admin')
        .select('id, nombre, rol')
        .eq('id', userId)
        .maybeSingle();

    if (adminData == null) {
      throw Exception('No existe perfil administrativo');
    }

    return UsuarioAdmin.fromMap(adminData);
  }

  Future<void> _asegurarPerfilAdmin(String userId) async {
    try {
      await _supabase.from('usuarios_admin').upsert({
        'id': userId,
        'nombre': _nombreController.text.trim(),
        'rol': 'operador',
      });
    } catch (_) {
      // El trigger de Supabase puede haber creado el perfil. Si esta escritura
      // queda bloqueada por RLS, la lectura posterior confirmara si existe.
    }
  }

  void _cambiarModo(bool registro) {
    setState(() {
      _modoRegistro = registro;
      _error = null;
      _mensaje = null;
      _passwordController.clear();
      _confirmarPasswordController.clear();
    });
  }

  void _abrirRecuperacionPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso administrativo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Personal autorizado',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _modoRegistro
                      ? 'Crea tu cuenta para acceder al panel administrativo.'
                      : 'Inicia sesion para registrar aeronaves, operaciones y liquidaciones.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.login),
                      label: Text('Iniciar sesion'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.person_add_alt_1),
                      label: Text('Registrarme'),
                    ),
                  ],
                  selected: {_modoRegistro},
                  onSelectionChanged: _cargando
                      ? null
                      : (value) => _cambiarModo(value.first),
                ),
                const SizedBox(height: 28),
                if (_modoRegistro) ...[
                  TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  onSubmitted: (_) =>
                      _modoRegistro ? _registrarUsuario() : _iniciarSesion(),
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                ),
                if (!_modoRegistro)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          _cargando ? null : _abrirRecuperacionPassword,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                if (_modoRegistro) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmarPasswordController,
                    obscureText: _ocultarPassword,
                    onSubmitted: (_) => _registrarUsuario(),
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contrasena',
                      prefixIcon: Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_mensaje != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _mensaje!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _cargando
                      ? null
                      : (_modoRegistro ? _registrarUsuario : _iniciarSesion),
                  icon: _cargando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _modoRegistro ? Icons.person_add_alt_1 : Icons.login,
                        ),
                  label: Text(
                    _modoRegistro ? 'Crear cuenta' : 'Iniciar sesion',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
