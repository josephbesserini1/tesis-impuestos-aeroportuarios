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
