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

Si la base ya tiene datos mezclados de scripts anteriores, ejecuta despues:

```text
limpiar_datos_mezclados.sql
```

Ese script reinicia los datos de prueba y deja un solo conjunto canonico. Los
archivos `schema_supabase.sql`, `seed_test_data.sql`, `rls_lectura_publica.sql`,
`pago_rpc.sql`, `pago_referencia.sql` y `admin_setup.sql` quedan como historial
del desarrollo; no los ejecutes encima del esquema completo porque vuelven a
mezclar versiones.

Para permitir registro desde la pantalla de acceso administrativo, ejecuta una
vez:

```text
registro_admin_setup.sql
```

Ese script crea el perfil en `usuarios_admin` automaticamente cuando alguien se
registra con Supabase Auth desde la app.
