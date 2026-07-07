-- ============================================================================
-- Datos de prueba: propietarios, aeronaves, operaciones y liquidaciones
-- ============================================================================
-- Crea 3 aeronaves con sus propietarios y liquidaciones para probar la
-- pantalla de Consulta:
--   YV-1234  -> 2 liquidaciones pendientes (aterrizaje + estacionamiento)
--   YV-2001  -> 1 liquidación pendiente (aterrizaje) + 1 ya pagada (despegue)
--   YV-3050  -> 1 liquidación pendiente (aterrizaje)
--
-- Requiere que ya se hayan ejecutado schema_supabase.sql (incluye los
-- tipos_impuesto de catálogo: "Derecho de aterrizaje", "Derecho de
-- estacionamiento", "Derecho de despegue") y, si vas a probar la app,
-- también rls_lectura_publica.sql.
--
-- Ejecutar en Supabase > SQL Editor > New query.
-- ============================================================================

with nuevos_propietarios as (
    insert into propietarios (nombre, cedula_rif, telefono, email)
    values
        ('Aerolíneas Caribe C.A.',          'J-12345678-9', '0212-555-1234', 'contacto@aerocaribe.com'),
        ('Juan Pérez',                       'V-9876543',    '0414-555-9876', 'juan.perez@example.com'),
        ('Transporte Ejecutivo Andes S.A.',  'J-30112233-4', '0212-555-6000', 'admin@ejecutivoandes.com')
    returning id, nombre
),
nuevas_aeronaves as (
    insert into aeronaves (propietario_id, matricula, tipo_aeronave, modelo, hangar_asignado)
    select np.id, v.matricula, v.tipo_aeronave, v.modelo, v.hangar
    from nuevos_propietarios np
    join (values
        ('Aerolíneas Caribe C.A.',          'YV-1234', 'Jet privado', 'Cessna Citation CJ3', 'Hangar A-1'),
        ('Juan Pérez',                       'YV-2001', 'Avioneta',    'Cessna 172',          'Hangar B-3'),
        ('Transporte Ejecutivo Andes S.A.',  'YV-3050', 'Helicóptero', 'Bell 407',            'Hangar C-2')
    ) as v(propietario_nombre, matricula, tipo_aeronave, modelo, hangar)
        on v.propietario_nombre = np.nombre
    returning id, matricula
),
nuevas_operaciones as (
    insert into operaciones (aeronave_id, tipo_operacion, piloto_responsable)
    select id, 'llegada', 'Piloto de prueba'
    from nuevas_aeronaves
    returning id, aeronave_id
),
liquidaciones_aterrizaje as (
    insert into liquidaciones (operacion_id, tipo_impuesto_id, monto, estado)
    select o.id, ti.id, ti.monto_base, 'pendiente'
    from nuevas_operaciones o
    cross join (select id, monto_base from tipos_impuesto where nombre = 'Derecho de aterrizaje' limit 1) ti
    returning id, operacion_id
),
liquidacion_extra_estacionamiento as (
    insert into liquidaciones (operacion_id, tipo_impuesto_id, monto, estado)
    select o.id, ti.id, ti.monto_base, 'pendiente'
    from nuevas_operaciones o
    join nuevas_aeronaves a on a.id = o.aeronave_id
    cross join (select id, monto_base from tipos_impuesto where nombre = 'Derecho de estacionamiento' limit 1) ti
    where a.matricula = 'YV-1234'
    returning id, operacion_id
)
insert into liquidaciones (operacion_id, tipo_impuesto_id, monto, estado)
select o.id, ti.id, ti.monto_base, 'pagado'
from nuevas_operaciones o
join nuevas_aeronaves a on a.id = o.aeronave_id
cross join (select id, monto_base from tipos_impuesto where nombre = 'Derecho de despegue' limit 1) ti
where a.matricula = 'YV-2001';

-- ============================================================================
-- FIN
-- ============================================================================
