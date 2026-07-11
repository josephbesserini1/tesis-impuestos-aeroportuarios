# tesis-impuestos-aeroportuarios

Proyecto Flutter + Supabase para consultar, liquidar y registrar pagos de
impuestos aeroportuarios.

## Ejecutar la app

```powershell
cd C:\Users\Joseph\Desktop\tesis-impuestos-aeroportuarios\app_flutter
flutter pub get
flutter run -d chrome
```

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
