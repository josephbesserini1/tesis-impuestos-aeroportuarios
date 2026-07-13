# tesis-impuestos-aeroportuarios

Proyecto Flutter + Supabase para consultar, liquidar y registrar pagos de
impuestos aeroportuarios.

## Ejecutar la app

```powershell
cd C:\Users\Joseph\Desktop\tesis-impuestos-aeroportuarios\app_flutter
flutter pub get
flutter run -d chrome --web-port 49800
```

Se usa un puerto fijo porque Supabase Auth necesita una URL estable para los
enlaces de recuperacion de contrasena.

## Recuperacion de contrasena en Supabase

En el panel del proyecto de Supabase abre:

```text
Authentication > URL Configuration
```

Agrega esta URL en `Redirect URLs` para desarrollo:

```text
http://localhost:49800/
```

En `Authentication > Email Templates > Reset password`, conserva el enlace de
confirmacion de Supabase. Si personalizas la plantilla, el boton debe usar:

```html
<a href="{{ .ConfirmationURL }}">Restablecer contrasena</a>
```

Cuando la app se publique, agrega tambien su direccion HTTPS exacta. El correo
se solicita desde `¿Olvidaste tu contrasena?` en el acceso administrativo. El
flujo web usa la respuesta implicita de Supabase y detecta `type=recovery` antes
de que el SDK limpie los datos temporales de la URL.

La nueva contrasena se guarda mediante Supabase Auth; no se almacena en
`usuarios_admin` ni en ninguna tabla publica. Para produccion configura un SMTP
propio en Supabase, ya que el servicio de correo incluido es solo para pruebas y
tiene limites de envio.

## Usar en iPhone

El proyecto ya incluye la configuración nativa de iOS. Para que la recuperación
de contraseña también regrese a la aplicación en iPhone, agrega esta URL exacta
en `Authentication > URL Configuration > Redirect URLs` de Supabase:

```text
impuestosaeroportuarios://login-callback
```

La compilación y firma de iOS se hacen en una Mac con Xcode y una cuenta Apple
Developer. Consulta las instrucciones completas en `app_flutter/README.md`.

## Probar desde iPhone sin Mac

Al enviar cambios a `main` o `develop`, GitHub Actions genera la aplicación web
y la publica en GitHub Pages. La dirección prevista es:

```text
https://josephbesserini1.github.io/tesis-impuestos-aeroportuarios/
```

La primera vez, en GitHub abre `Settings > Pages` y selecciona **GitHub
Actions** como fuente de publicación. Desde Safari en el iPhone abre esa URL,
toca **Compartir** y elige **Añadir a pantalla de inicio**. Para que la
recuperación de contraseña funcione en esta versión, agrega esa misma URL en
las `Redirect URLs` de Supabase.

## Preparar Supabase

Para montar la base completa usa:

```text
supabase_proyecto_completo.sql
```

Ese script adapta la base `anteproyecto_bd_final` al esquema que consume la app
Flutter y agrega registro correcto de pagos, comprobantes, cancelaciones,
hangares, aeropuertos y auditoria.

Ejecutalo en:

```text
Supabase > SQL Editor > New query > Run
```
