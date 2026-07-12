import 'dart:async';

import 'package:app_flutter/main.dart';
import 'package:app_flutter/models/usuario_admin.dart';
import 'package:app_flutter/screens/admin/admin_home_screen.dart';
import 'package:app_flutter/screens/admin/forgot_password_screen.dart';
import 'package:app_flutter/screens/admin/login_admin_screen.dart';
import 'package:app_flutter/screens/admin/update_password_screen.dart';
import 'package:app_flutter/screens/help_screen.dart';
import 'package:app_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('la ayuda no aparece en la pantalla de inicio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomePage()),
    );

    expect(find.text('Consultar impuestos'), findsOneWidget);
    expect(find.text('Acceso administrativo'), findsOneWidget);
    expect(find.byTooltip('Ayuda y soporte'), findsNothing);
  });

  testWidgets('la pantalla de ayuda muestra preguntas y avisos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HelpScreen()),
    );

    expect(find.text('Ayuda y soporte'), findsOneWidget);
    expect(find.text('Preguntas frecuentes'), findsOneWidget);
    expect(find.text('¿Cómo consulto una aeronave?'), findsOneWidget);
    expect(find.text('No sé si mi pago fue procesado'), findsOneWidget);

    await tester.tap(find.text('No sé si mi pago fue procesado'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No realices otro pago de inmediato'),
      findsOneWidget,
    );
    expect(find.text('Protege tus datos'), findsOneWidget);
  });

  testWidgets('el panel administrativo abre la pantalla de ayuda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final usuarioAdmin = UsuarioAdmin(
      id: 'admin-1',
      nombre: 'Usuario de prueba',
      rol: 'operador',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminHomeScreen(usuarioAdmin: usuarioAdmin),
      ),
    );

    expect(find.text('Aeronaves'), findsOneWidget);
    expect(find.text('Ayuda y soporte'), findsOneWidget);

    await tester.tap(find.text('Ayuda y soporte'));
    await tester.pumpAndSettle();

    expect(find.text('Ayuda y soporte'), findsOneWidget);
    expect(find.text('¿En qué podemos ayudarte?'), findsOneWidget);
  });

  testWidgets('cerrar sesión vuelve al inicio aunque el panel sea la raíz', (
    tester,
  ) async {
    var cierreSolicitado = false;
    final usuarioAdmin = UsuarioAdmin(
      id: 'admin-1',
      nombre: 'Usuario de prueba',
      rol: 'operador',
    );

    await tester.pumpWidget(const MyApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AdminHomeScreen(
          usuarioAdmin: usuarioAdmin,
          signOut: () async {
            cierreSolicitado = true;
            throw Exception('Fallo remoto simulado');
          },
        ),
      ),
      (route) => false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Panel administrativo'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(cierreSolicitado, isTrue);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Panel administrativo'), findsNothing);
  });

  testWidgets('el acceso administrativo abre recuperar contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginAdminScreen()),
    );

    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(find.text('Enviar enlace de recuperación'), findsOneWidget);
  });

  testWidgets('recuperar contraseña solicita el correo a Supabase', (
    tester,
  ) async {
    String? emailSolicitado;
    String? redireccionSolicitada;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ForgotPasswordScreen(
          initialEmail: 'admin@aeropuerto.test',
          recoveryRedirectTo: 'http://localhost:49800/',
          sendResetEmail: (email, {redirectTo}) async {
            emailSolicitado = email;
            redireccionSolicitada = redirectTo;
          },
        ),
      ),
    );

    await tester.tap(find.text('Enviar enlace de recuperación'));
    await tester.pumpAndSettle();

    expect(emailSolicitado, 'admin@aeropuerto.test');
    expect(redireccionSolicitada, 'http://localhost:49800/');
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(
      find.textContaining('Si existe una cuenta con ese correo'),
      findsOneWidget,
    );
  });

  testWidgets('la nueva contraseña se actualiza y cierra la sesión', (
    tester,
  ) async {
    String? passwordGuardado;
    var sesionCerrada = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: UpdatePasswordScreen(
          updatePassword: (password) async {
            passwordGuardado = password;
          },
          signOut: () async {
            sesionCerrada = true;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('new-password-field')),
      'clave-segura-123',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password-field')),
      'clave-segura-123',
    );
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    expect(passwordGuardado, 'clave-segura-123');
    expect(sesionCerrada, isTrue);
    expect(find.textContaining('Contraseña actualizada'), findsOneWidget);
  });

  testWidgets('el evento de Supabase abre crear nueva contraseña', (
    tester,
  ) async {
    final authStates = StreamController<AuthState>.broadcast();
    addTearDown(authStates.close);

    await tester.pumpWidget(MyApp(authStateChanges: authStates.stream));
    authStates.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
    await tester.pumpAndSettle();

    expect(find.text('Crear nueva contraseña'), findsOneWidget);
    expect(find.text('Guardar nueva contraseña'), findsOneWidget);
  });

  test('detecta un enlace de recuperación en el fragmento web', () {
    final uri = Uri.parse(
      'http://localhost:49800/#access_token=token&type=recovery',
    );

    expect(isPasswordRecoveryUri(uri), isTrue);
  });

  testWidgets('el enlace inicial abre crear nueva contraseña', (tester) async {
    await tester.pumpWidget(const MyApp(initialPasswordRecovery: true));
    await tester.pumpAndSettle();

    expect(find.text('Crear nueva contraseña'), findsOneWidget);
    expect(find.text('Guardar nueva contraseña'), findsOneWidget);
  });
}
