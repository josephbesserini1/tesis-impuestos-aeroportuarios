-- ============================================================================
-- Limpieza de datos mezclados para el kiosco de impuestos aeroportuarios
-- ============================================================================
-- Uso:
-- 1) Supabase > SQL Editor > New query
-- 2) Pegar/ejecutar este archivo completo
--
-- Que hace:
-- - Elimina datos operativos y catalogos de prueba mezclados.
-- - Conserva usuarios_admin y cuentas de auth.users.
-- - Vuelve a cargar un unico conjunto canonico de datos.
-- - Evita que vuelvan a entrar duplicados por acentos en catalogos.
--
-- IMPORTANTE:
-- Este script borra aeronaves, propietarios, operaciones, liquidaciones, pagos,
-- comprobantes, aeropuertos, hangares y catalogos existentes. Usalo cuando la
-- base sea de desarrollo/demo o cuando ya decidiste reiniciar esos datos.
-- ============================================================================

begin;

-- Borra datos del dominio, pero no toca usuarios_admin ni auth.users.
truncate table
    comprobantes,
    detalle_pagos,
    cancelaciones_pago,
    pagos,
    liquidaciones,
    operaciones,
    asignaciones_hangar,
    aeronaves,
    hangares,
    aeropuertos,
    tipos_impuesto,
    metodos_pago,
    propietarios,
    auditoria_eventos
restart identity cascade;

-- Catalogos canonicos
insert into metodos_pago (nombre, activo)
values
    ('Pago movil', true),
    ('Transferencia bancaria', true),
    ('Tarjeta de debito/credito', true);

insert into tipos_impuesto (nombre, descripcion, monto_base, moneda, criterio_calculo, vigente)
values
    ('Aterrizaje', 'Cobro por aterrizaje', 100.00, 'VES', 'capacidad', true),
    ('Despegue', 'Cobro por operacion de salida', 120.00, 'VES', 'capacidad', true),
    ('Pernocta', 'Estadia en aeropuerto o hangar', 80.00, 'VES', 'monto_base', true),
    ('Mantenimiento', 'Uso de hangar o servicios tecnicos', 90.00, 'VES', 'monto_base', true),
    ('Servicio', 'Servicio aeroportuario general', 50.00, 'VES', 'monto_base', true);

insert into aeropuertos (nombre, codigo, calle, ciudad, estado, pais)
values
    ('Maiquetia', 'CCS', 'Zona 1', 'La Guaira', 'La Guaira', 'Venezuela'),
    ('Valencia', 'VLN', 'Zona 2', 'Valencia', 'Carabobo', 'Venezuela'),
    ('Maracaibo', 'MAR', 'Zona 3', 'Maracaibo', 'Zulia', 'Venezuela'),
    ('Barquisimeto', 'BRM', 'Zona 4', 'Barquisimeto', 'Lara', 'Venezuela'),
    ('Barcelona', 'BLA', 'Zona 5', 'Barcelona', 'Anzoategui', 'Venezuela');

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
join aeropuertos a on a.codigo = h.codigo_aeropuerto;

insert into propietarios (nombre, apellido, cedula_rif, email, telefono, calle, ciudad, estado, pais)
values
    ('Carlos', 'Mendoza', 'V11111111', 'carlos@email.com', '04140000001', 'Av A', 'Caracas', 'DC', 'Venezuela'),
    ('Ana', 'Torres', 'V22222222', 'ana@email.com', '04140000002', 'Av B', 'Valencia', 'Carabobo', 'Venezuela'),
    ('Jose', 'Perez', 'V55555555', 'jose@email.com', '04140000005', 'Av C', 'Maracay', 'Aragua', 'Venezuela'),
    ('Laura', 'Gomez', 'V66666666', 'laura@email.com', '04140000006', 'Av D', 'Barquisimeto', 'Lara', 'Venezuela'),
    ('Pedro', 'Suarez', 'V77777777', 'pedro@email.com', '04140000007', 'Av E', 'Maracaibo', 'Zulia', 'Venezuela');

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
        ('V11111111', 'CCS', 'YV1001', 'Avion', 'Cessna Citation CJ3', 'Cessna', 4, 'H1'),
        ('V22222222', 'VLN', 'YV1002', 'Avion', 'Boeing 737', 'Boeing', 150, 'H2'),
        ('V55555555', 'MAR', 'YV1003', 'Avion', 'Airbus A320', 'Airbus', 180, 'H3'),
        ('V66666666', 'BRM', 'YV1004', 'Helicoptero', 'Bell 206', 'Bell', 5, 'H4'),
        ('V77777777', 'BLA', 'YV1005', 'Jet', 'Embraer Phenom 300', 'Embraer', 10, 'H5')
) as x(cedula_rif, codigo_aeropuerto, matricula, tipo, modelo, fabricante, capacidad, hangar)
join propietarios p on p.cedula_rif = x.cedula_rif
join aeropuertos ap on ap.codigo = x.codigo_aeropuerto;

insert into asignaciones_hangar (aeronave_id, hangar_id, estado_asignacion)
select a.id, h.id, 'Activa'
from aeronaves a
join hangares h on h.codigo_hangar = a.hangar_asignado;

insert into operaciones (aeronave_id, tipo_operacion, estado_operacion, fecha_operacion, piloto_responsable, observacion)
select a.id, x.tipo_operacion, 'ejecutada', x.fecha_operacion::timestamptz, x.piloto, 'Datos canonicos de demostracion'
from (
    values
        ('YV1001', 'llegada', '2026-06-01 08:00:00+00', 'Piloto 1'),
        ('YV1002', 'salida', '2026-06-02 09:00:00+00', 'Piloto 2'),
        ('YV1003', 'llegada', '2026-06-03 10:00:00+00', 'Piloto 3'),
        ('YV1004', 'salida', '2026-06-04 11:00:00+00', 'Piloto 4'),
        ('YV1005', 'llegada', '2026-06-05 12:00:00+00', 'Piloto 5')
) as x(matricula, tipo_operacion, fecha_operacion, piloto)
join aeronaves a on a.matricula = x.matricula;

insert into liquidaciones (operacion_id, tipo_impuesto_id, monto, estado, fecha_liquidacion)
select o.id, ti.id, 0, 'pendiente', o.fecha_operacion
from operaciones o
join tipos_impuesto ti on (
    (o.tipo_operacion = 'llegada' and ti.nombre = 'Aterrizaje')
    or (o.tipo_operacion = 'salida' and ti.nombre = 'Despegue')
);

-- Blindaje contra duplicados futuros por acentos en catalogos.
create unique index if not exists idx_metodos_pago_nombre_normalizado
on metodos_pago (
    lower(translate(
        nombre,
        chr(225) || chr(233) || chr(237) || chr(243) || chr(250) ||
        chr(193) || chr(201) || chr(205) || chr(211) || chr(218) ||
        chr(252) || chr(220),
        'aeiouAEIOUuU'
    ))
);

create unique index if not exists idx_tipos_impuesto_nombre_normalizado
on tipos_impuesto (
    lower(translate(
        nombre,
        chr(225) || chr(233) || chr(237) || chr(243) || chr(250) ||
        chr(193) || chr(201) || chr(205) || chr(211) || chr(218) ||
        chr(252) || chr(220),
        'aeiouAEIOUuU'
    ))
);

commit;

-- Verificacion rapida esperada:
-- propietarios=5, aeronaves=5, aeropuertos=5, hangares=5,
-- asignaciones_hangar=5, operaciones=5, liquidaciones=5,
-- tipos_impuesto=5, metodos_pago=3.
select 'propietarios' as tabla, count(*) from propietarios
union all select 'aeronaves', count(*) from aeronaves
union all select 'aeropuertos', count(*) from aeropuertos
union all select 'hangares', count(*) from hangares
union all select 'asignaciones_hangar', count(*) from asignaciones_hangar
union all select 'operaciones', count(*) from operaciones
union all select 'liquidaciones', count(*) from liquidaciones
union all select 'tipos_impuesto', count(*) from tipos_impuesto
union all select 'metodos_pago', count(*) from metodos_pago
order by tabla;
