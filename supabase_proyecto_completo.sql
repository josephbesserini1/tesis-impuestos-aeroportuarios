-- ============================================================================
-- Supabase: esquema completo para el kiosco de impuestos aeroportuarios
-- Basado en anteproyecto_bd_final.sql y adaptado a la app Flutter existente.
-- ============================================================================
-- Uso recomendado:
-- 1) Supabase > SQL Editor > New query
-- 2) Pegar este archivo completo
-- 3) Run
--
-- Este script conserva los nombres que consume Flutter:
-- propietarios, aeronaves, tipos_impuesto, operaciones, liquidaciones,
-- metodos_pago, pagos, comprobantes y usuarios_admin.
-- Tambien incorpora las entidades del modelo final:
-- aeropuertos, hangares, asignaciones_hangar, cancelaciones_pago,
-- detalle_pagos y auditoria_eventos.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ============================================================================
-- Catalogos y personas
-- ============================================================================

create table if not exists propietarios (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    apellido text,
    cedula_rif text not null unique,
    telefono text,
    email text,
    calle text,
    ciudad text,
    estado text,
    pais text default 'Venezuela',
    created_at timestamptz not null default now()
);

alter table propietarios add column if not exists apellido text;
alter table propietarios add column if not exists calle text;
alter table propietarios add column if not exists ciudad text;
alter table propietarios add column if not exists estado text;
alter table propietarios add column if not exists pais text default 'Venezuela';

create table if not exists aeropuertos (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    codigo text not null unique,
    calle text,
    ciudad text,
    estado text,
    pais text default 'Venezuela',
    created_at timestamptz not null default now()
);

create table if not exists hangares (
    id uuid primary key default gen_random_uuid(),
    aeropuerto_id uuid not null references aeropuertos(id) on update cascade on delete restrict,
    codigo_hangar text not null unique,
    estado text not null default 'Disponible'
        check (estado in ('Disponible', 'Ocupado', 'Mantenimiento')),
    capacidad integer not null default 1 check (capacidad > 0),
    created_at timestamptz not null default now()
);

create table if not exists tipos_impuesto (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    descripcion text,
    monto_base numeric(12,2) not null check (monto_base >= 0),
    moneda text not null default 'VES',
    criterio_calculo text not null default 'monto_base'
        check (criterio_calculo in ('monto_base', 'capacidad')),
    vigente boolean not null default true,
    created_at timestamptz not null default now()
);

alter table tipos_impuesto add column if not exists moneda text not null default 'VES';
alter table tipos_impuesto add column if not exists criterio_calculo text not null default 'monto_base';
alter table tipos_impuesto add column if not exists vigente boolean not null default true;

create table if not exists metodos_pago (
    id uuid primary key default gen_random_uuid(),
    nombre text not null unique,
    activo boolean not null default true,
    created_at timestamptz not null default now()
);

alter table metodos_pago add column if not exists created_at timestamptz not null default now();

-- ============================================================================
-- Aeronaves, operaciones y liquidaciones
-- ============================================================================

create table if not exists aeronaves (
    id uuid primary key default gen_random_uuid(),
    propietario_id uuid not null references propietarios(id) on update cascade on delete restrict,
    aeropuerto_id uuid references aeropuertos(id) on update cascade on delete restrict,
    matricula text not null unique,
    tipo_aeronave text,
    modelo text,
    fabricante text,
    capacidad integer not null default 1 check (capacidad > 0),
    estado text not null default 'Activa',
    hangar_asignado text,
    created_at timestamptz not null default now()
);

alter table aeronaves add column if not exists aeropuerto_id uuid references aeropuertos(id) on update cascade on delete restrict;
alter table aeronaves add column if not exists fabricante text;
alter table aeronaves add column if not exists capacidad integer not null default 1;
alter table aeronaves add column if not exists estado text not null default 'Activa';

create index if not exists idx_aeronaves_propietario on aeronaves(propietario_id);
create index if not exists idx_aeronaves_aeropuerto on aeronaves(aeropuerto_id);
create index if not exists idx_aeronaves_matricula on aeronaves(matricula);

create table if not exists asignaciones_hangar (
    id uuid primary key default gen_random_uuid(),
    aeronave_id uuid not null references aeronaves(id) on update cascade on delete cascade,
    hangar_id uuid not null references hangares(id) on update cascade on delete restrict,
    fecha_inicio date not null default current_date,
    fecha_fin date,
    estado_asignacion text not null default 'Activa'
        check (estado_asignacion in ('Activa', 'Finalizada', 'Pendiente')),
    created_at timestamptz not null default now(),
    check (fecha_fin is null or fecha_fin >= fecha_inicio)
);

create index if not exists idx_asignaciones_aeronave on asignaciones_hangar(aeronave_id);
create index if not exists idx_asignaciones_hangar on asignaciones_hangar(hangar_id);

create table if not exists operaciones (
    id uuid primary key default gen_random_uuid(),
    aeronave_id uuid not null references aeronaves(id) on update cascade on delete restrict,
    tipo_operacion text not null check (tipo_operacion in ('llegada', 'salida')),
    estado_operacion text not null default 'programada'
        check (estado_operacion in ('programada', 'ejecutada', 'cancelada')),
    fecha_operacion timestamptz not null default now(),
    piloto_responsable text,
    observacion text,
    created_at timestamptz not null default now()
);

alter table operaciones add column if not exists estado_operacion text not null default 'programada';
alter table operaciones add column if not exists observacion text;

create index if not exists idx_operaciones_aeronave on operaciones(aeronave_id);
create index if not exists idx_operaciones_fecha on operaciones(fecha_operacion);

create table if not exists liquidaciones (
    id uuid primary key default gen_random_uuid(),
    operacion_id uuid not null references operaciones(id) on update cascade on delete restrict,
    tipo_impuesto_id uuid not null references tipos_impuesto(id) on update cascade on delete restrict,
    monto numeric(12,2) not null check (monto >= 0),
    estado text not null default 'pendiente' check (estado in ('pendiente', 'pagado', 'anulado')),
    fecha_liquidacion timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create index if not exists idx_liquidaciones_operacion on liquidaciones(operacion_id);
create index if not exists idx_liquidaciones_estado on liquidaciones(estado);

-- Calcula el monto desde el catalogo si se envia null o 0.
create or replace function calcular_monto_liquidacion()
returns trigger
language plpgsql
set search_path = public
as $$
declare
    v_monto_base numeric(12,2);
    v_criterio text;
    v_capacidad integer;
begin
    if new.monto is not null and new.monto > 0 then
        return new;
    end if;

    select ti.monto_base, ti.criterio_calculo
      into v_monto_base, v_criterio
      from tipos_impuesto ti
     where ti.id = new.tipo_impuesto_id;

    select a.capacidad
      into v_capacidad
      from operaciones o
      join aeronaves a on a.id = o.aeronave_id
     where o.id = new.operacion_id;

    if v_criterio = 'capacidad' then
        new.monto := coalesce(v_monto_base, 0) * greatest(coalesce(v_capacidad, 1), 1);
    else
        new.monto := coalesce(v_monto_base, 0);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_calcular_monto_liquidacion on liquidaciones;
create trigger trg_calcular_monto_liquidacion
before insert or update of tipo_impuesto_id, operacion_id, monto on liquidaciones
for each row execute function calcular_monto_liquidacion();

-- ============================================================================
-- Pagos, comprobantes y auditoria
-- ============================================================================

create table if not exists pagos (
    id uuid primary key default gen_random_uuid(),
    liquidacion_id uuid references liquidaciones(id) on update cascade on delete restrict,
    metodo_pago_id uuid not null references metodos_pago(id) on update cascade on delete restrict,
    monto_pagado numeric(12,2) not null check (monto_pagado >= 0),
    referencia_simulada text,
    estado text not null default 'aprobado'
        check (estado in ('aprobado', 'rechazado', 'pendiente')),
    fecha_pago timestamptz not null default now(),
    created_at timestamptz not null default now()
);

alter table pagos add column if not exists referencia_simulada text;

create index if not exists idx_pagos_liquidacion on pagos(liquidacion_id);
create index if not exists idx_pagos_metodo on pagos(metodo_pago_id);
create index if not exists idx_pagos_fecha on pagos(fecha_pago);

create table if not exists detalle_pagos (
    id uuid primary key default gen_random_uuid(),
    pago_id uuid not null references pagos(id) on update cascade on delete cascade,
    banco text,
    telefono text,
    titular text,
    ultimos4 text,
    referencia_cliente text,
    datos jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create table if not exists comprobantes (
    id uuid primary key default gen_random_uuid(),
    pago_id uuid not null unique references pagos(id) on update cascade on delete restrict,
    numero_comprobante text not null unique,
    fecha_emision timestamptz not null default now(),
    observacion text,
    created_at timestamptz not null default now()
);

create table if not exists cancelaciones_pago (
    id uuid primary key default gen_random_uuid(),
    pago_id uuid not null references pagos(id) on update cascade on delete cascade,
    liquidacion_id uuid not null references liquidaciones(id) on update cascade on delete cascade,
    fecha_aplicacion_pago timestamptz not null default now(),
    monto_aplicado numeric(12,2) not null check (monto_aplicado > 0),
    created_at timestamptz not null default now(),
    unique (pago_id, liquidacion_id)
);

create table if not exists auditoria_eventos (
    id uuid primary key default gen_random_uuid(),
    entidad text not null,
    entidad_id uuid,
    accion text not null,
    descripcion text,
    datos jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create table if not exists usuarios_admin (
    id uuid primary key references auth.users(id) on update cascade on delete cascade,
    nombre text not null,
    rol text not null default 'operador' check (rol in ('administrador', 'operador', 'supervisor')),
    created_at timestamptz not null default now()
);

-- ============================================================================
-- RPC atomico para el kiosco
-- ============================================================================

create or replace function procesar_pago(
    p_aeronave_id uuid,
    p_metodo_pago_id uuid,
    p_referencia text default null,
    p_detalle jsonb default '{}'::jsonb
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
    v_comprobante_id uuid;
    v_numero text;
    v_referencia text;
    v_encontro boolean := false;
begin
    if not exists (
        select 1
          from metodos_pago
         where id = p_metodo_pago_id
           and activo
    ) then
        raise exception 'Metodo de pago invalido o inactivo';
    end if;

    v_referencia := coalesce(nullif(trim(p_referencia), ''), 'SIM-' || upper(substr(md5(random()::text), 1, 10)));

    for r in
        select l.id, l.monto
          from liquidaciones l
          join operaciones o on o.id = l.operacion_id
         where o.aeronave_id = p_aeronave_id
           and l.estado = 'pendiente'
         order by l.fecha_liquidacion
         for update of l
    loop
        v_encontro := true;

        insert into pagos (
            liquidacion_id,
            metodo_pago_id,
            monto_pagado,
            referencia_simulada,
            estado
        )
        values (
            r.id,
            p_metodo_pago_id,
            r.monto,
            v_referencia,
            'aprobado'
        )
        returning id into v_pago_id;

        insert into detalle_pagos (
            pago_id,
            banco,
            telefono,
            titular,
            ultimos4,
            referencia_cliente,
            datos
        )
        values (
            v_pago_id,
            nullif(p_detalle ->> 'banco', ''),
            nullif(p_detalle ->> 'telefono', ''),
            nullif(p_detalle ->> 'titular', ''),
            nullif(p_detalle ->> 'ultimos4', ''),
            v_referencia,
            coalesce(p_detalle, '{}'::jsonb)
        );

        insert into cancelaciones_pago (pago_id, liquidacion_id, monto_aplicado)
        values (v_pago_id, r.id, r.monto);

        v_numero := 'CBTE-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(v_pago_id::text), 1, 6));

        insert into comprobantes (pago_id, numero_comprobante, observacion)
        values (v_pago_id, v_numero, 'Pago registrado desde kiosco')
        returning id into v_comprobante_id;

        update liquidaciones
           set estado = 'pagado'
         where id = r.id;

        insert into auditoria_eventos (entidad, entidad_id, accion, descripcion, datos)
        values (
            'pagos',
            v_pago_id,
            'procesar_pago',
            'Pago aprobado y comprobante generado',
            jsonb_build_object(
                'liquidacion_id', r.id,
                'monto', r.monto,
                'metodo_pago_id', p_metodo_pago_id,
                'referencia', v_referencia
            )
        );

        comprobante_id := v_comprobante_id;
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

revoke execute on function procesar_pago(uuid, uuid, text, jsonb) from public;
grant execute on function procesar_pago(uuid, uuid, text, jsonb) to anon, authenticated;

-- ============================================================================
-- Datos iniciales del anteproyecto, adaptados a UUID
-- ============================================================================

insert into aeropuertos (nombre, codigo, calle, ciudad, estado, pais)
values
    ('Maiquetia', 'CCS', 'Zona 1', 'La Guaira', 'La Guaira', 'Venezuela'),
    ('Valencia', 'VLN', 'Zona 2', 'Valencia', 'Carabobo', 'Venezuela'),
    ('Maracaibo', 'MAR', 'Zona 3', 'Maracaibo', 'Zulia', 'Venezuela'),
    ('Barquisimeto', 'BRM', 'Zona 4', 'Barquisimeto', 'Lara', 'Venezuela'),
    ('Barcelona', 'BLA', 'Zona 5', 'Barcelona', 'Anzoategui', 'Venezuela')
on conflict (codigo) do update set
    nombre = excluded.nombre,
    calle = excluded.calle,
    ciudad = excluded.ciudad,
    estado = excluded.estado,
    pais = excluded.pais;

insert into hangares (aeropuerto_id, codigo_hangar, estado, capacidad)
select a.id, h.codigo_hangar, h.estado, h.capacidad
from (
    values
        ('CCS', 'H1', 'Disponible', 3),
        ('VLN', 'H2', 'Ocupado', 5),
        ('MAR', 'H3', 'Mantenimiento', 2),
        ('BRM', 'H4', 'Disponible', 4),
        ('BLA', 'H5', 'Ocupado', 6)
) as h(codigo_aeropuerto, codigo_hangar, estado, capacidad)
join aeropuertos a on a.codigo = h.codigo_aeropuerto
on conflict (codigo_hangar) do update set
    aeropuerto_id = excluded.aeropuerto_id,
    estado = excluded.estado,
    capacidad = excluded.capacidad;

insert into metodos_pago (nombre)
values
    ('Pago movil'),
    ('Transferencia bancaria'),
    ('Tarjeta de debito/credito')
on conflict (nombre) do nothing;

insert into tipos_impuesto (nombre, descripcion, monto_base, criterio_calculo)
values
    ('Aterrizaje', 'Cobro por aterrizaje', 100.00, 'capacidad'),
    ('Pernocta', 'Estadia en aeropuerto o hangar', 80.00, 'monto_base'),
    ('Despegue', 'Cobro por operacion de salida', 120.00, 'capacidad'),
    ('Mantenimiento', 'Uso de hangar o servicios tecnicos', 90.00, 'monto_base'),
    ('Servicio', 'Servicio aeroportuario general', 50.00, 'monto_base')
on conflict do nothing;

insert into propietarios (nombre, apellido, cedula_rif, email, telefono, calle, ciudad, estado, pais)
values
    ('Carlos', 'Mendoza', 'V11111111', 'carlos@email.com', '04140000001', 'Av A', 'Caracas', 'DC', 'Venezuela'),
    ('Ana', 'Torres', 'V22222222', 'ana@email.com', '04140000002', 'Av B', 'Valencia', 'Carabobo', 'Venezuela'),
    ('Jose', 'Perez', 'V55555555', 'jose@email.com', '04140000005', 'Av C', 'Maracay', 'Aragua', 'Venezuela'),
    ('Laura', 'Gomez', 'V66666666', 'laura@email.com', '04140000006', 'Av D', 'Barquisimeto', 'Lara', 'Venezuela'),
    ('Pedro', 'Suarez', 'V77777777', 'pedro@email.com', '04140000007', 'Av E', 'Maracaibo', 'Zulia', 'Venezuela')
on conflict (cedula_rif) do update set
    nombre = excluded.nombre,
    apellido = excluded.apellido,
    email = excluded.email,
    telefono = excluded.telefono,
    calle = excluded.calle,
    ciudad = excluded.ciudad,
    estado = excluded.estado,
    pais = excluded.pais;

insert into aeronaves (
    propietario_id,
    aeropuerto_id,
    matricula,
    tipo_aeronave,
    modelo,
    fabricante,
    capacidad,
    estado,
    hangar_asignado
)
select p.id, ap.id, x.matricula, x.tipo, x.modelo, x.fabricante, x.capacidad, 'Activa', x.hangar
from (
    values
        ('V11111111', 'CCS', 'YV1001', 'Avion', 'Cessna', 'Cessna', 4, 'H1'),
        ('V22222222', 'VLN', 'YV1002', 'Avion', 'Boeing 737', 'Boeing', 150, 'H2'),
        ('V55555555', 'MAR', 'YV1003', 'Avion', 'Airbus A320', 'Airbus', 180, 'H3'),
        ('V66666666', 'BRM', 'YV1004', 'Helicoptero', 'Bell 206', 'Bell', 5, 'H4'),
        ('V77777777', 'BLA', 'YV1005', 'Jet', 'Jet X', 'Embraer', 10, 'H5')
) as x(cedula_rif, codigo_aeropuerto, matricula, tipo, modelo, fabricante, capacidad, hangar)
join propietarios p on p.cedula_rif = x.cedula_rif
join aeropuertos ap on ap.codigo = x.codigo_aeropuerto
on conflict (matricula) do update set
    propietario_id = excluded.propietario_id,
    aeropuerto_id = excluded.aeropuerto_id,
    tipo_aeronave = excluded.tipo_aeronave,
    modelo = excluded.modelo,
    fabricante = excluded.fabricante,
    capacidad = excluded.capacidad,
    estado = excluded.estado,
    hangar_asignado = excluded.hangar_asignado;

insert into asignaciones_hangar (aeronave_id, hangar_id, estado_asignacion)
select a.id, h.id, 'Activa'
from aeronaves a
join hangares h on h.codigo_hangar = a.hangar_asignado
on conflict do nothing;

insert into operaciones (aeronave_id, tipo_operacion, estado_operacion, fecha_operacion, piloto_responsable, observacion)
select a.id, x.tipo_operacion, 'ejecutada', x.fecha_operacion::timestamptz, x.piloto, 'Datos iniciales'
from (
    values
        ('YV1001', 'llegada', '2026-06-01 08:00:00', 'Piloto 1'),
        ('YV1002', 'salida', '2026-06-02 09:00:00', 'Piloto 2'),
        ('YV1003', 'llegada', '2026-06-03 10:00:00', 'Piloto 3'),
        ('YV1004', 'salida', '2026-06-04 11:00:00', 'Piloto 4'),
        ('YV1005', 'llegada', '2026-06-05 12:00:00', 'Piloto 5')
) as x(matricula, tipo_operacion, fecha_operacion, piloto)
join aeronaves a on a.matricula = x.matricula
where not exists (
    select 1
    from operaciones o
    where o.aeronave_id = a.id
      and o.tipo_operacion = x.tipo_operacion
      and o.fecha_operacion = x.fecha_operacion::timestamptz
);

insert into liquidaciones (operacion_id, tipo_impuesto_id, monto, estado, fecha_liquidacion)
select o.id, ti.id, 0, 'pendiente', o.fecha_operacion
from operaciones o
join tipos_impuesto ti on (
    (o.tipo_operacion = 'llegada' and ti.nombre = 'Aterrizaje')
    or (o.tipo_operacion = 'salida' and ti.nombre = 'Despegue')
)
where not exists (
    select 1
    from liquidaciones l
    where l.operacion_id = o.id
      and l.tipo_impuesto_id = ti.id
);

-- ============================================================================
-- Seguridad RLS
-- ============================================================================

alter table propietarios enable row level security;
alter table aeropuertos enable row level security;
alter table hangares enable row level security;
alter table aeronaves enable row level security;
alter table asignaciones_hangar enable row level security;
alter table tipos_impuesto enable row level security;
alter table operaciones enable row level security;
alter table liquidaciones enable row level security;
alter table metodos_pago enable row level security;
alter table pagos enable row level security;
alter table detalle_pagos enable row level security;
alter table comprobantes enable row level security;
alter table cancelaciones_pago enable row level security;
alter table auditoria_eventos enable row level security;
alter table usuarios_admin enable row level security;

drop policy if exists "Lectura publica kiosco" on propietarios;
drop policy if exists "Lectura publica kiosco" on aeropuertos;
drop policy if exists "Lectura publica kiosco" on hangares;
drop policy if exists "Lectura publica kiosco" on aeronaves;
drop policy if exists "Lectura publica kiosco" on asignaciones_hangar;
drop policy if exists "Lectura publica kiosco" on tipos_impuesto;
drop policy if exists "Lectura publica kiosco" on operaciones;
drop policy if exists "Lectura publica kiosco" on liquidaciones;
drop policy if exists "Lectura publica kiosco" on metodos_pago;

create policy "Lectura publica kiosco" on propietarios for select to anon using (true);
create policy "Lectura publica kiosco" on aeropuertos for select to anon using (true);
create policy "Lectura publica kiosco" on hangares for select to anon using (true);
create policy "Lectura publica kiosco" on aeronaves for select to anon using (true);
create policy "Lectura publica kiosco" on asignaciones_hangar for select to anon using (true);
create policy "Lectura publica kiosco" on tipos_impuesto for select to anon using (true);
create policy "Lectura publica kiosco" on operaciones for select to anon using (true);
create policy "Lectura publica kiosco" on liquidaciones for select to anon using (true);
create policy "Lectura publica kiosco" on metodos_pago for select to anon using (true);

drop policy if exists "Acceso autenticado" on propietarios;
drop policy if exists "Acceso autenticado" on aeropuertos;
drop policy if exists "Acceso autenticado" on hangares;
drop policy if exists "Acceso autenticado" on aeronaves;
drop policy if exists "Acceso autenticado" on asignaciones_hangar;
drop policy if exists "Acceso autenticado" on tipos_impuesto;
drop policy if exists "Acceso autenticado" on operaciones;
drop policy if exists "Acceso autenticado" on liquidaciones;
drop policy if exists "Acceso autenticado" on metodos_pago;
drop policy if exists "Acceso autenticado" on pagos;
drop policy if exists "Acceso autenticado" on detalle_pagos;
drop policy if exists "Acceso autenticado" on comprobantes;
drop policy if exists "Acceso autenticado" on cancelaciones_pago;
drop policy if exists "Acceso autenticado" on auditoria_eventos;
drop policy if exists "Acceso autenticado" on usuarios_admin;

create policy "Acceso autenticado" on propietarios for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on aeropuertos for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on hangares for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on aeronaves for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on asignaciones_hangar for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on tipos_impuesto for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on operaciones for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on liquidaciones for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on metodos_pago for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on pagos for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on detalle_pagos for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on comprobantes for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on cancelaciones_pago for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on auditoria_eventos for all to authenticated using (true) with check (true);
create policy "Acceso autenticado" on usuarios_admin for all to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- ============================================================================
-- FIN
-- ============================================================================
