import 'package:app_flutter/main.dart';
import 'package:app_flutter/models/usuario_admin.dart';
import 'package:app_flutter/screens/admin/admin_home_screen.dart';
import 'package:app_flutter/screens/help_screen.dart';
import 'package:app_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
