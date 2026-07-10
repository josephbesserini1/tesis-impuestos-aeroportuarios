-- ============================================================================
-- Permitir que el pago simulado guarde la referencia que el usuario ingresó
-- en el formulario (teléfono/banco, número de transferencia, o los últimos
-- dígitos de la tarjeta) en vez de un valor aleatorio.
-- ============================================================================
-- Se agrega un parámetro opcional p_referencia al final de procesar_pago().
-- Postgres permite extender una función con create or replace agregando
-- parámetros nuevos siempre que tengan un valor por defecto (no cambia la
-- identidad de la función, así que no hace falta volver a hacer drop).
--
-- Ejecutar en Supabase > SQL Editor > New query, después de pago_rpc.sql.
-- ============================================================================

create or replace function procesar_pago(
    p_aeronave_id uuid,
    p_metodo_pago_id uuid,
    p_referencia text default null
)
returns table (
    comprobante_id uuid,
    numero_comprobante text,
    liquidacion_id uuid,
    monto numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
    r record;
    v_pago_id uuid;
    v_numero text;
    v_referencia text;
    v_encontro boolean := false;
begin
    if not exists (select 1 from metodos_pago where id = p_metodo_pago_id and activo) then
        raise exception 'Método de pago inválido o inactivo';
    end if;

    v_referencia := coalesce(nullif(trim(p_referencia), ''), 'SIM-' || upper(substr(md5(random()::text), 1, 10)));

    for r in
        select l.id, l.monto
        from liquidaciones l
        join operaciones o on o.id = l.operacion_id
        where o.aeronave_id = p_aeronave_id
          and l.estado = 'pendiente'
        for update of l
    loop
        v_encontro := true;

        insert into pagos (liquidacion_id, metodo_pago_id, monto_pagado, referencia_simulada, estado)
        values (r.id, p_metodo_pago_id, r.monto, v_referencia, 'aprobado')
        returning id into v_pago_id;

        v_numero := 'CBTE-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(v_pago_id::text), 1, 6));

        insert into comprobantes (pago_id, numero_comprobante)
        values (v_pago_id, v_numero);

        update liquidaciones set estado = 'pagado' where id = r.id;

        comprobante_id := (select c.id from comprobantes c where c.pago_id = v_pago_id);
        numero_comprobante := v_numero;
        liquidacion_id := r.id;
        monto := r.monto;
        return next;
    end loop;

    if not v_encontro then
        raise exception 'Esta aeronave no tiene liquidaciones pendientes';
    end if;
end;
$$;

revoke execute on function procesar_pago(uuid, uuid, text) from public;
grant execute on function procesar_pago(uuid, uuid, text) to anon, authenticated;

-- ============================================================================
-- FIN
-- ============================================================================
