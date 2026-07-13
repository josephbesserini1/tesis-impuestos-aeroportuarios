# Kiosco de Impuestos Aeroportuarios

Aplicación Flutter preparada para Android, web y iPhone/iPad (iOS 13 o superior).

## Preparar y probar en iPhone

La compilación para iOS debe hacerse desde una Mac con Xcode instalado y una cuenta de Apple Developer para instalarla en un dispositivo o publicarla.

1. Abra `ios/Runner.xcworkspace` en Xcode (no el archivo `.xcodeproj`).
2. En **Runner > Signing & Capabilities**, seleccione su equipo de desarrollo. Si el identificador `com.impuestosaeroportuarios.app` ya estuviera registrado, sustitúyalo por uno único de su organización.
3. En Supabase, vaya a **Authentication > URL Configuration** y agregue esta Redirect URL exacta: `impuestosaeroportuarios://login-callback`.
4. Conecte el iPhone por cable o selecciónelo en Xcode y ejecute la app. También puede ejecutar `flutter build ipa --release` para generar el archivo de distribución.

La app ya registra el esquema `impuestosaeroportuarios://` en iOS. Por ello, el enlace de recuperación de contraseña de Supabase vuelve a la app y abre la pantalla para crear la nueva contraseña.

## Validación local

Desde la carpeta `app_flutter` ejecute:

```bash
flutter pub get
flutter test
flutter build ios --no-codesign
```

El último comando valida la compilación de iOS en macOS; la firma y el archivo `.ipa` requieren Xcode y credenciales de Apple.
