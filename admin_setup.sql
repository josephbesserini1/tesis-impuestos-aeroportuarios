-- ============================================================================
-- Panel administrativo: lectura pública de propietarios (corrige el embed
-- que faltaba) + control de acceso administrativo real (solo usuarios
-- registrados en usuarios_admin pueden escribir en las tablas operativas).
-- ============================================================================
-- Hasta ahora, "Acceso autenticado" (definida en schema_supabase.sql) permitía
-- que CUALQUIER usuario autenticado de Supabase leyera/escribiera en todas las
-- tablas. Esto se reemplaza por una policy que exige que el usuario tenga una
-- fila en usuarios_admin, que es el "control de acceso" y "autenticación
-- administrativa" que exige el anteproyecto (Fase 2).
--
-- Ejecutar en Supabase > SQL Editor > New query, después de
-- rls_lectura_publica.sql, seed_test_data.sql y pago_rpc.sql.
-- ============================================================================

-- 1. Lectura pública de propietarios (el kiosco la necesita para mostrar el
--    nombre del dueño en la Consulta; sin esto, el embed aeronaves->propietarios
--    devuelve null para el rol anon).
create policy "Lectura pública (kiosco)" on propietarios
    for select to anon using (true);

-- 2. Endurecer escritura y lectura administrativa: solo usuarios con fila en
--    usuarios_admin pueden operar sobre estas tablas.
drop policy "Acceso autenticado" on propietarios;
create policy "Solo administradores" on propietarios
    for all
    using (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()))
    with check (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()));

drop policy "Acceso autenticado" on aeronaves;
create policy "Solo administradores" on aeronaves
    for all
    using (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()))
    with check (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()));

drop policy "Acceso autenticado" on tipos_impuesto;
create policy "Solo administradores" on tipos_impuesto
    for all
    using (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()))
    with check (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()));

drop policy "Acceso autenticado" on operaciones;
create policy "Solo administradores" on operaciones
    for all
    using (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()))
    with check (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()));

drop policy "Acceso autenticado" on liquidaciones;
create policy "Solo administradores" on liquidaciones
    for all
    using (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()))
    with check (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()));

drop policy "Acceso autenticado" on metodos_pago;
create policy "Solo administradores" on metodos_pago
    for all
    using (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()))
    with check (exists (select 1 from usuarios_admin ua where ua.id = auth.uid()));

-- 3. usuarios_admin: cada usuario solo puede ver su propia fila (para saber su
--    nombre/rol tras iniciar sesión). No hay insert/update/delete vía app: las
--    cuentas administrativas se aprovisionan manualmente (ver instrucciones
--    abajo).
drop policy "Acceso autenticado" on usuarios_admin;
create policy "Ver mi perfil" on usuarios_admin
    for select
    using (id = auth.uid());

-- ============================================================================
-- CÓMO CREAR LA PRIMERA CUENTA DE ADMINISTRADOR
-- ============================================================================
-- 1. Supabase Dashboard > Authentication > Users > "Add user" (email +
--    contraseña). No marques "Auto confirm" en off; déjalo confirmado.
-- 2. Copia el UID que se generó para ese usuario.
-- 3. Ejecuta (reemplazando el UID y el nombre):
--
--    insert into usuarios_admin (id, nombre, rol)
--    values ('<uid-copiado>', 'Christian Goncalves', 'administrador');
--
-- ============================================================================
-- FIN
-- ============================================================================
