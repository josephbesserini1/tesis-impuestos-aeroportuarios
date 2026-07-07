-- ============================================================================
-- Política adicional de RLS: lectura pública para el kiosco
-- ============================================================================
-- El kiosco (app Flutter) se conecta con la anonKey de Supabase y NO tiene
-- login de usuario (es un terminal público). Las políticas originales de
-- schema_supabase.sql solo permiten acceso a auth.role() = 'authenticated',
-- así que sin esto la app recibiría 0 filas en cualquier consulta.
--
-- Aquí se agrega, solo para el rol "anon", permiso de LECTURA (select) en las
-- 4 tablas que necesita la pantalla de Consulta. No se toca insert/update/
-- delete: esas operaciones (registrar pagos, etc.) seguirán requeriendo un
-- usuario autenticado, cubiertas por las políticas "Acceso autenticado" ya
-- existentes.
--
-- Ejecutar en Supabase > SQL Editor > New query (una sola vez).
-- ============================================================================

create policy "Lectura pública (kiosco)" on aeronaves
    for select to anon using (true);

create policy "Lectura pública (kiosco)" on operaciones
    for select to anon using (true);

create policy "Lectura pública (kiosco)" on liquidaciones
    for select to anon using (true);

create policy "Lectura pública (kiosco)" on tipos_impuesto
    for select to anon using (true);

-- ============================================================================
-- FIN
-- ============================================================================
