-- ============================================================================
-- Registro administrativo desde la app
-- ============================================================================
-- Uso:
-- 1) Supabase > SQL Editor > New query
-- 2) Ejecutar este archivo una vez
--
-- Que hace:
-- - Cuando alguien se registra con Supabase Auth desde la app, crea
--   automaticamente su fila en public.usuarios_admin.
-- - Guarda el nombre enviado por la app en user_metadata.nombre.
-- - Asigna el rol "operador" por defecto.
-- ============================================================================

create or replace function public.crear_perfil_admin_desde_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.usuarios_admin (id, nombre, rol)
    values (
        new.id,
        coalesce(nullif(new.raw_user_meta_data ->> 'nombre', ''), new.email, 'Usuario administrativo'),
        coalesce(nullif(new.raw_user_meta_data ->> 'rol', ''), 'operador')
    )
    on conflict (id) do update set
        nombre = excluded.nombre,
        rol = excluded.rol;

    return new;
end;
$$;

drop trigger if exists trg_crear_perfil_admin_desde_auth on auth.users;
create trigger trg_crear_perfil_admin_desde_auth
after insert on auth.users
for each row execute function public.crear_perfil_admin_desde_auth();

-- Permite que un usuario autenticado lea su propio perfil administrativo.
drop policy if exists "Ver mi perfil" on usuarios_admin;
create policy "Ver mi perfil" on usuarios_admin
    for select
    using (id = auth.uid());

-- Respaldo para proyectos con confirmacion automatica: si el trigger ya creo
-- la fila, no pasa nada; si no, la app puede insertar su propio perfil.
drop policy if exists "Registrar mi perfil admin" on usuarios_admin;
create policy "Registrar mi perfil admin" on usuarios_admin
    for insert to authenticated
    with check (id = auth.uid());

