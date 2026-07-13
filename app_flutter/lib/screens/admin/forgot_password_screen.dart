import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_config.dart';
import '../../theme/app_theme.dart';

typedef PasswordResetEmailSender =
    Future<void> Function(String email, {String? redirectTo});

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final PasswordResetEmailSender? sendResetEmail;
  final String? recoveryRedirectTo;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.sendResetEmail,
    this.recoveryRedirectTo,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;

  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? get _redirectTo {
    if (widget.recoveryRedirectTo != null) {
      return widget.recoveryRedirectTo;
    }
    if (!kIsWeb) return mobileAuthCallbackUrl;

    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path.isEmpty ? '/' : base.path,
    ).toString();
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _enviarEnlace() async {
    final email = _emailController.text.trim();
    if (!_emailValido(email)) {
      setState(() => _error = 'Ingresa un correo electrónico válido.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final sender = widget.sendResetEmail;
      if (sender != null) {
        await sender(email, redirectTo: _redirectTo);
      } else {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          email,
          redirectTo: _redirectTo,
        );
      }

      if (!mounted) return;
      setState(() {
        _enviando = false;
        _enviado = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      final limiteAlcanzado =
          error.message.toLowerCase().contains('rate limit') ||
          error.message.toLowerCase().contains('security purposes');
      setState(() {
        _enviando = false;
        _error = limiteAlcanzado
            ? 'Espera unos minutos antes de solicitar otro enlace.'
            : 'No se pudo enviar el enlace. Intenta nuevamente.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = 'No se pudo enviar el enlace. Revisa tu conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _enviado ? _buildConfirmacion() : _buildFormulario(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
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
            Icons.mark_email_read_outlined,
            color: AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '¿Olvidaste tu contraseña?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Escribe el correo de tu cuenta administrativa y Supabase te enviará un enlace seguro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 28),
        TextField(
          key: const Key('recovery-email-field'),
          controller: _emailController,
          enabled: !_enviando,
          autofocus: widget.initialEmail.isEmpty,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_enviando) _enviarEnlace();
          },
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
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
          onPressed: _enviando ? null : _enviarEnlace,
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: Text(
            _enviando ? 'Enviando enlace...' : 'Enviar enlace de recuperación',
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'El enlace es personal, de un solo uso y puede vencer. No lo compartas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildConfirmacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.outgoing_mail,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Revisa tu correo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Si existe una cuenta con ese correo, recibirás un enlace para crear una nueva contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al acceso'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _enviado = false;
                _error = null;
              }),
              child: const Text('Enviar a otro correo'),
            ),
          ],
        ),
      ),
    );
  }
}
