import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'admin_detail_sheet.dart';

class AsignacionesHangarScreen extends StatefulWidget {
  const AsignacionesHangarScreen({super.key});

  @override
  State<AsignacionesHangarScreen> createState() =>
      _AsignacionesHangarScreenState();
}

class _AsignacionesHangarScreenState extends State<AsignacionesHangarScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _asignaciones = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _supabase
          .from('asignaciones_hangar')
          .select(
            'id, fecha_inicio, fecha_fin, estado_asignacion, '
            'aeronaves(matricula, modelo), hangares(codigo_hangar, aeropuertos(nombre, codigo))',
          )
          .order('created_at', ascending: false);
      setState(() {
        _asignaciones = (data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las asignaciones.';
        _cargando = false;
      });
    }
  }

  Color _estadoColor(String estado) {
    if (estado == 'Activa') return AppColors.success;
    if (estado == 'Pendiente') return AppColors.warning;
    return AppColors.primary;
  }

  void _mostrarDetalle(Map<String, dynamic> asignacion) {
    final aeronave = asignacion['aeronaves'] as Map<String, dynamic>?;
    final hangar = asignacion['hangares'] as Map<String, dynamic>?;
    final aeropuerto = hangar?['aeropuertos'] as Map<String, dynamic>?;
    final estado = asignacion['estado_asignacion'] as String? ?? 'Activa';
    showAdminDetailSheet(
      context: context,
      title:
          '${aeronave?['matricula'] ?? 'Aeronave'} - ${hangar?['codigo_hangar'] ?? 'Hangar'}',
      icon: Icons.warehouse_outlined,
      statusLabel: estado,
      statusColor: _estadoColor(estado),
      rows: [
        AdminDetailRow(
          label: 'Aeronave',
          value: aeronave?['matricula'] as String?,
          icon: Icons.flight,
        ),
        AdminDetailRow(
          label: 'Modelo',
          value: aeronave?['modelo'] as String?,
          icon: Icons.airplanemode_active,
        ),
        AdminDetailRow(
          label: 'Hangar',
          value: hangar?['codigo_hangar'] as String?,
          icon: Icons.warehouse_outlined,
        ),
        AdminDetailRow(
          label: 'Aeropuerto',
          value: aeropuerto == null
              ? null
              : '${aeropuerto['nombre']} (${aeropuerto['codigo']})',
          icon: Icons.local_airport_outlined,
        ),
        AdminDetailRow(
          label: 'Fecha inicio',
          value: asignacion['fecha_inicio'] as String?,
          icon: Icons.event_available_outlined,
        ),
        AdminDetailRow(
          label: 'Fecha fin',
          value: asignacion['fecha_fin'] as String?,
          icon: Icons.event_busy_outlined,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignaciones de hangar')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _asignaciones.isEmpty
          ? const Center(child: Text('No hay asignaciones registradas.'))
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _asignaciones.length,
                itemBuilder: (context, index) {
                  final asignacion = _asignaciones[index];
                  final aeronave =
                      asignacion['aeronaves'] as Map<String, dynamic>?;
                  final hangar =
                      asignacion['hangares'] as Map<String, dynamic>?;
                  final aeropuerto =
                      hangar?['aeropuertos'] as Map<String, dynamic>?;
                  final estado =
                      asignacion['estado_asignacion'] as String? ?? 'Activa';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: () => _mostrarDetalle(asignacion),
                        leading: const Icon(
                          Icons.warehouse_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          '${aeronave?['matricula'] ?? 'Aeronave'} - ${hangar?['codigo_hangar'] ?? 'Hangar'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (aeropuerto != null)
                              '${aeropuerto['nombre']} (${aeropuerto['codigo']})',
                            if (asignacion['fecha_inicio'] != null)
                              'Desde: ${asignacion['fecha_inicio']}',
                          ].join(' - '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppStatusChip(
                              label: estado,
                              color: _estadoColor(estado),
                              backgroundColor: _estadoColor(
                                estado,
                              ).withValues(alpha: 0.1),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
