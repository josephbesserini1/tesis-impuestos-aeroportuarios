-- ============================================================================
-- Flujo de pago simulado: lectura pública de métodos de pago + función
-- atómica que registra el pago, genera el comprobante y cancela la
-- liquidación.
-- ============================================================================
-- El kiosco (rol anon) necesita listar los métodos de pago activos para que
-- el usuario elija uno. La escritura (pagos, comprobantes, liquidaciones) NO
-- se abre por policies de RLS para anon: en su lugar, procesar_pago() es
-- SECURITY DEFINER y es el único punto de entrada para escribir, evitando
-- exponer inserts/updates directos a un rol sin autenticación.
--
-- Ejecutar en Supabase > SQL Editor > New query, después de
-- rls_lectura_publica.sql y seed_test_data.sql.
-- ============================================================================

create policy "Lectura pública (kiosco)" on metodos_pago
    for select to anon using (true);

create or replace function procesar_pago(
    p_aeronave_id uuid,
    p_metodo_pago_id uuid
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
    v_encontro boolean := false;
begin
    if not exists (select 1 from metodos_pago where id = p_metodo_pago_id and activo) then
        raise exception 'Método de pago inválido o inactivo';
    end if;

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
        values (r.id, p_metodo_pago_id, r.monto, 'SIM-' || upper(substr(md5(random()::text), 1, 10)), 'aprobado')
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

revoke execute on function procesar_pago(uuid, uuid) from public;
grant execute on function procesar_pago(uuid, uuid) to anon, authenticated;

-- ============================================================================
-- FIN
-- ============================================================================
