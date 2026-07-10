import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class AsignacionesHangarScreen extends StatefulWidget {
  const AsignacionesHangarScreen({super.key});

  @override
  State<AsignacionesHangarScreen> createState() => _AsignacionesHangarScreenState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignaciones de hangar')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _asignaciones.isEmpty
                  ? const Center(child: Text('No hay asignaciones registradas.'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _asignaciones.length,
                        itemBuilder: (context, index) {
                          final asignacion = _asignaciones[index];
                          final aeronave = asignacion['aeronaves'] as Map<String, dynamic>?;
                          final hangar = asignacion['hangares'] as Map<String, dynamic>?;
                          final aeropuerto = hangar?['aeropuertos'] as Map<String, dynamic>?;
                          final estado = asignacion['estado_asignacion'] as String? ?? 'Activa';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                leading: const Icon(Icons.warehouse_outlined, color: AppColors.primary),
                                title: Text(
                                  '${aeronave?['matricula'] ?? 'Aeronave'} - ${hangar?['codigo_hangar'] ?? 'Hangar'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text([
                                  if (aeropuerto != null) '${aeropuerto['nombre']} (${aeropuerto['codigo']})',
                                  if (asignacion['fecha_inicio'] != null) 'Desde: ${asignacion['fecha_inicio']}',
                                ].join(' - ')),
                                trailing: AppStatusChip(
                                  label: estado,
                                  color: _estadoColor(estado),
                                  backgroundColor: _estadoColor(estado).withValues(alpha: 0.1),
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
