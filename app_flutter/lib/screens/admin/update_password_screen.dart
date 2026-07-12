import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'login_admin_screen.dart';

typedef PasswordUpdater = Future<void> Function(String password);
typedef RecoverySignOut = Future<void> Function();

class UpdatePasswordScreen extends StatefulWidget {
  final PasswordUpdater? updatePassword;
  final RecoverySignOut? signOut;
  final VoidCallback? onCompleted;

  const UpdatePasswordScreen({
    super.key,
    this.updatePassword,
    this.signOut,
    this.onCompleted,
  });

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _guardando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _actualizarPassword() async {
    final password = _passwordController.text;
    final confirmacion = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(
        () => _error = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    if (password != confirmacion) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    if (widget.updatePassword == null &&
        Supabase.instance.client.auth.currentSession == null) {
      setState(() {
        _error =
            'El enlace venció o no es válido. Solicita uno nuevo desde el acceso administrativo.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final updater = widget.updatePassword;
      if (updater != null) {
        await updater(password);
      } else {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: password),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      final mensaje = error.message.toLowerCase();
      setState(() {
        _guardando = false;
        _error = mensaje.contains('password') && mensaje.contains('weak')
            ? 'La contraseña no cumple los requisitos de seguridad de Supabase.'
            : 'No se pudo actualizar la contraseña. Solicita un enlace nuevo.';
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo actualizar la contraseña. Intenta nuevamente.';
      });
      return;
    }

    try {
      await _cerrarSesionRecuperacion();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error =
            'La contraseña se guardó, pero no se pudo cerrar la sesión de recuperación. Intenta nuevamente.';
      });
      return;
    }

    if (!mounted) return;
    _volverAlAcceso(
      'Contraseña actualizada. Ya puedes iniciar sesión con tu nueva contraseña.',
    );
  }

  Future<void> _cancelar() async {
    if (_guardando) return;

    try {
      await _cerrarSesionRecuperacion();
    } catch (_) {
      // La navegación al acceso debe continuar aunque la sesión ya haya vencido.
    }

    if (!mounted) return;
    _volverAlAcceso();
  }

  Future<void> _cerrarSesionRecuperacion() async {
    final signOut = widget.signOut;
    if (signOut != null) {
      await signOut();
    } else {
      await Supabase.instance.client.auth.signOut();
    }
  }

  void _volverAlAcceso([String? mensaje]) {
    widget.onCompleted?.call();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginAdminScreen(initialMessage: mensaje),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva contraseña'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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
                      Icons.password_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Crear nueva contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escribe y confirma la contraseña que usarás para ingresar al panel administrativo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const Key('new-password-field'),
                    controller: _passwordController,
                    enabled: !_guardando,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _ocultarPassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: () => setState(
                          () => _ocultarPassword = !_ocultarPassword,
                        ),
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('confirm-password-field'),
                    controller: _confirmPasswordController,
                    enabled: !_guardando,
                    obscureText: _ocultarPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_guardando) _actualizarPassword();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _guardando ? null : _actualizarPassword,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _guardando
                          ? 'Guardando en Supabase...'
                          : 'Guardar nueva contraseña',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _guardando ? null : _cancelar,
                    child: const Text('Cancelar y volver al acceso'),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'La contraseña será administrada de forma segura por Supabase Auth.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
