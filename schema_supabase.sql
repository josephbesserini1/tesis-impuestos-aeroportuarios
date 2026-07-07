-- ============================================================================
-- Esquema de base de datos
-- Prototipo de interfaz digital para gestión del pago de impuestos aeroportuarios
-- Universidad Metropolitana - Ingeniería de Sistemas
-- ============================================================================
-- Instrucciones: pega este script completo en Supabase > SQL Editor > New query
-- y ejecútalo (Run). Crea todas las tablas, relaciones, índices y políticas
-- básicas de seguridad (RLS) necesarias para el prototipo.
-- ============================================================================

-- Extensión necesaria para generar UUIDs
create extension if not exists "pgcrypto";

-- ============================================================================
-- 1. PROPIETARIOS
-- Dueños o responsables administrativos de las aeronaves
-- ============================================================================
create table propietarios (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    cedula_rif text not null unique,
    telefono text,
    email text,
    created_at timestamptz not null default now()
);

-- ============================================================================
-- 2. AERONAVES
-- ============================================================================
create table aeronaves (
    id uuid primary key default gen_random_uuid(),
    propietario_id uuid not null references propietarios(id) on delete restrict,
    matricula text not null unique,          -- ej: YV-1234
    tipo_aeronave text,                       -- ej: avioneta, jet privado, helicóptero
    modelo text,
    hangar_asignado text,
    created_at timestamptz not null default now()
);

create index idx_aeronaves_propietario on aeronaves(propietario_id);

-- ============================================================================
-- 3. TIPOS DE IMPUESTO / TARIFAS
-- Catálogo de conceptos que se cobran (aterrizaje, estacionamiento, etc.)
-- ============================================================================
create table tipos_impuesto (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,                     -- ej: Derecho de aterrizaje
    descripcion text,
    monto_base numeric(12,2) not null check (monto_base >= 0),
    moneda text not null default 'VES',
    vigente boolean not null default true,
    created_at timestamptz not null default now()
);

-- ============================================================================
-- 4. OPERACIONES AEROPORTUARIAS
-- Llegadas / salidas de aeronaves que generan la obligación de pago
-- ============================================================================
create table operaciones (
    id uuid primary key default gen_random_uuid(),
    aeronave_id uuid not null references aeronaves(id) on delete restrict,
    tipo_operacion text not null check (tipo_operacion in ('llegada', 'salida')),
    fecha_operacion timestamptz not null default now(),
    piloto_responsable text,
    created_at timestamptz not null default now()
);

create index idx_operaciones_aeronave on operaciones(aeronave_id);
create index idx_operaciones_fecha on operaciones(fecha_operacion);

-- ============================================================================
-- 5. LIQUIDACIONES
-- Monto calculado a pagar por una operación, según el tipo de impuesto
-- ============================================================================
create table liquidaciones (
    id uuid primary key default gen_random_uuid(),
    operacion_id uuid not null references operaciones(id) on delete restrict,
    tipo_impuesto_id uuid not null references tipos_impuesto(id) on delete restrict,
    monto numeric(12,2) not null check (monto >= 0),
    estado text not null default 'pendiente' check (estado in ('pendiente', 'pagado', 'anulado')),
    fecha_liquidacion timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create index idx_liquidaciones_operacion on liquidaciones(operacion_id);
create index idx_liquidaciones_estado on liquidaciones(estado);

-- ============================================================================
-- 6. MÉTODOS DE PAGO
-- Catálogo de métodos simulados (pago móvil, transferencia, tarjeta)
-- ============================================================================
create table metodos_pago (
    id uuid primary key default gen_random_uuid(),
    nombre text not null unique,              -- ej: Pago móvil, Transferencia bancaria, Tarjeta
    activo boolean not null default true
);

-- ============================================================================
-- 7. PAGOS (simulados)
-- ============================================================================
create table pagos (
    id uuid primary key default gen_random_uuid(),
    liquidacion_id uuid not null references liquidaciones(id) on delete restrict,
    metodo_pago_id uuid not null references metodos_pago(id) on delete restrict,
    monto_pagado numeric(12,2) not null check (monto_pagado >= 0),
    referencia_simulada text,                 -- número de referencia generado por la simulación
    estado text not null default 'aprobado' check (estado in ('aprobado', 'rechazado', 'pendiente')),
    fecha_pago timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create index idx_pagos_liquidacion on pagos(liquidacion_id);

-- ============================================================================
-- 8. COMPROBANTES DIGITALES
-- ============================================================================
create table comprobantes (
    id uuid primary key default gen_random_uuid(),
    pago_id uuid not null unique references pagos(id) on delete restrict,
    numero_comprobante text not null unique,
    fecha_emision timestamptz not null default now(),
    created_at timestamptz not null default now()
);

-- ============================================================================
-- 9. USUARIOS ADMINISTRATIVOS (opcional)
-- Vincula cuentas de auth.users de Supabase con roles dentro del sistema
-- Solo se usa si el kiosco requiere un panel administrativo con login
-- ============================================================================
create table usuarios_admin (
    id uuid primary key references auth.users(id) on delete cascade,
    nombre text not null,
    rol text not null default 'operador' check (rol in ('administrador', 'operador')),
    created_at timestamptz not null default now()
);

-- ============================================================================
-- DATOS INICIALES DE CATÁLOGO (opcional, para pruebas)
-- ============================================================================
insert into metodos_pago (nombre) values
    ('Pago móvil'),
    ('Transferencia bancaria'),
    ('Tarjeta de débito/crédito');

insert into tipos_impuesto (nombre, descripcion, monto_base) values
    ('Derecho de aterrizaje', 'Cobro por operación de aterrizaje', 50.00),
    ('Derecho de estacionamiento', 'Cobro por permanencia en plataforma/hangar', 30.00),
    ('Derecho de despegue', 'Cobro por operación de salida', 50.00);

-- ============================================================================
-- SEGURIDAD (RLS - Row Level Security)
-- Para el prototipo/simulación, se habilita RLS y se permite acceso completo
-- a usuarios autenticados. Ajustar políticas antes de un entorno productivo real.
-- ============================================================================
alter table propietarios enable row level security;
alter table aeronaves enable row level security;
alter table tipos_impuesto enable row level security;
alter table operaciones enable row level security;
alter table liquidaciones enable row level security;
alter table metodos_pago enable row level security;
alter table pagos enable row level security;
alter table comprobantes enable row level security;
alter table usuarios_admin enable row level security;

-- Política genérica: cualquier usuario autenticado puede leer y escribir
-- (suficiente para un prototipo académico; en producción se restringiría por rol)
create policy "Acceso autenticado" on propietarios for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on aeronaves for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on tipos_impuesto for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on operaciones for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on liquidaciones for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on metodos_pago for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on pagos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on comprobantes for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Acceso autenticado" on usuarios_admin for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
