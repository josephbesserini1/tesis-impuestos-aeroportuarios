import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _eventos = [];

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
          .from('auditoria_eventos')
          .select('id, entidad, accion, descripcion, datos, created_at')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _eventos = (data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar la auditoria.';
        _cargando = false;
      });
    }
  }

  String _fechaCorta(String? value) {
    if (value == null) return '';
    final fecha = DateTime.tryParse(value);
    if (fecha == null) return value;
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auditoria')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _eventos.isEmpty
                  ? const Center(child: Text('No hay eventos de auditoria registrados.'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _eventos.length,
                        itemBuilder: (context, index) {
                          final evento = _eventos[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                leading: const Icon(Icons.manage_search_outlined, color: AppColors.primary),
                                title: Text(
                                  '${evento['entidad']} - ${evento['accion']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text([
                                  if (evento['descripcion'] != null) evento['descripcion'] as String,
                                  _fechaCorta(evento['created_at'] as String?),
                                ].where((text) => text.isNotEmpty).join(' - ')),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
