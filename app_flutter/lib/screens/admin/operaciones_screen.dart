import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/aeronave.dart';
import '../../models/operacion.dart';
import '../../theme/app_theme.dart';

class OperacionesScreen extends StatefulWidget {
  const OperacionesScreen({super.key});

  @override
  State<OperacionesScreen> createState() => _OperacionesScreenState();
}

class _OperacionesScreenState extends State<OperacionesScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Operacion> _operaciones = [];

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
          .from('operaciones')
          .select('id, aeronave_id, tipo_operacion, fecha_operacion, piloto_responsable, aeronaves(matricula)')
          .order('fecha_operacion', ascending: false)
          .limit(50);

      setState(() {
        _operaciones = (data as List)
            .map((e) => Operacion.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las operaciones.';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFormulario() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FormularioOperacion(),
    );
    if (creado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _operaciones.isEmpty
                  ? const Center(child: Text('No hay operaciones registradas.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _operaciones.length,
                      itemBuilder: (context, index) {
                        final o = _operaciones[index];
                        final esLlegada = o.tipoOperacion == 'llegada';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: Icon(
                                esLlegada ? Icons.flight_land : Icons.flight_takeoff,
                                color: AppColors.primary,
                              ),
                              title: Text(o.matricula, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${esLlegada ? 'Llegada' : 'Salida'} · ${o.fechaOperacion.day.toString().padLeft(2, '0')}/${o.fechaOperacion.month.toString().padLeft(2, '0')}/${o.fechaOperacion.year}'
                                '${o.pilotoResponsable != null ? ' · ${o.pilotoResponsable}' : ''}',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _FormularioOperacion extends StatefulWidget {
  const _FormularioOperacion();

  @override
  State<_FormularioOperacion> createState() => _FormularioOperacionState();
}

class _FormularioOperacionState extends State<_FormularioOperacion> {
  final _supabase = Supabase.instance.client;
  final _pilotoController = TextEditingController();

  bool _cargandoAeronaves = true;
  bool _guardando = false;
  String? _error;
  List<Aeronave> _aeronaves = [];
  String? _aeronaveSeleccionadaId;
  String _tipoOperacion = 'llegada';

  @override
  void initState() {
    super.initState();
    _cargarAeronaves();
  }

  Future<void> _cargarAeronaves() async {
    try {
      final data = await _supabase.from('aeronaves').select('id, matricula').order('matricula');

      setState(() {
        _aeronaves = (data as List)
            .map((e) => Aeronave.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargandoAeronaves = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las aeronaves.';
        _cargandoAeronaves = false;
      });
    }
  }

  @override
  void dispose() {
    _pilotoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_aeronaveSeleccionadaId == null) {
      setState(() => _error = 'Selecciona una aeronave.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _supabase.from('operaciones').insert({
        'aeronave_id': _aeronaveSeleccionadaId,
        'tipo_operacion': _tipoOperacion,
        'piloto_responsable': _pilotoController.text.trim().isEmpty ? null : _pilotoController.text.trim(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'No se pudo registrar la operación.';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registrar operación', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _cargandoAeronaves
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  initialValue: _aeronaveSeleccionadaId,
                  decoration: const InputDecoration(labelText: 'Aeronave'),
                  items: _aeronaves
                      .map((a) => DropdownMenuItem(value: a.id, child: Text(a.matricula)))
                      .toList(),
                  onChanged: (value) => setState(() => _aeronaveSeleccionadaId = value),
                ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'llegada', label: Text('Llegada'), icon: Icon(Icons.flight_land)),
              ButtonSegment(value: 'salida', label: Text('Salida'), icon: Icon(Icons.flight_takeoff)),
            ],
            selected: {_tipoOperacion},
            onSelectionChanged: (seleccion) => setState(() => _tipoOperacion = seleccion.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pilotoController,
            decoration: const InputDecoration(labelText: 'Piloto responsable (opcional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
