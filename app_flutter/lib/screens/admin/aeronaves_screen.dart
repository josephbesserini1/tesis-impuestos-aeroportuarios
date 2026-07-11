import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/aeronave.dart';
import '../../models/propietario.dart';
import '../../theme/app_theme.dart';
import 'admin_detail_sheet.dart';

class AeronavesScreen extends StatefulWidget {
  const AeronavesScreen({super.key});

  @override
  State<AeronavesScreen> createState() => _AeronavesScreenState();
}

class _AeronavesScreenState extends State<AeronavesScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Aeronave> _aeronaves = [];

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
          .from('aeronaves')
          .select(
            'id, matricula, tipo_aeronave, modelo, fabricante, capacidad, estado, hangar_asignado, '
            'propietarios(nombre), aeropuertos(nombre, codigo)',
          )
          .order('created_at', ascending: false);

      setState(() {
        _aeronaves = (data as List)
            .map((e) => Aeronave.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las aeronaves.';
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
      builder: (_) => const _FormularioAeronave(),
    );
    if (creado == true) _cargar();
  }

  void _mostrarDetalle(Aeronave a) {
    showAdminDetailSheet(
      context: context,
      title: a.matricula,
      icon: Icons.flight,
      statusLabel: a.estado,
      statusColor: AppColors.success,
      rows: [
        AdminDetailRow(
          label: 'Tipo',
          value: a.tipoAeronave,
          icon: Icons.category_outlined,
        ),
        AdminDetailRow(
          label: 'Modelo',
          value: a.modelo,
          icon: Icons.airplanemode_active,
        ),
        AdminDetailRow(
          label: 'Fabricante',
          value: a.fabricante,
          icon: Icons.precision_manufacturing_outlined,
        ),
        AdminDetailRow(
          label: 'Capacidad',
          value: a.capacidad == null ? null : '${a.capacidad} puestos',
          icon: Icons.event_seat_outlined,
        ),
        AdminDetailRow(
          label: 'Aeropuerto',
          value: a.aeropuertoCodigo == null
              ? a.aeropuertoNombre
              : '${a.aeropuertoNombre ?? ''} (${a.aeropuertoCodigo})',
          icon: Icons.local_airport_outlined,
        ),
        AdminDetailRow(
          label: 'Hangar',
          value: a.hangarAsignado,
          icon: Icons.warehouse_outlined,
        ),
        AdminDetailRow(
          label: 'Propietario',
          value: a.propietarioNombre,
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aeronaves')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _aeronaves.isEmpty
          ? const Center(child: Text('No hay aeronaves registradas.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _aeronaves.length,
              itemBuilder: (context, index) {
                final a = _aeronaves[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _mostrarDetalle(a),
                      leading: const Icon(
                        Icons.flight,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        a.matricula,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if (a.tipoAeronave != null) a.tipoAeronave!,
                          if (a.aeropuertoCodigo != null)
                            'Aeropuerto: ${a.aeropuertoCodigo}',
                          if (a.hangarAsignado != null)
                            'Hangar: ${a.hangarAsignado}',
                          if (a.propietarioNombre != null)
                            'Dueno: ${a.propietarioNombre}',
                        ].join(' - '),
                      ),
                      trailing: a.capacidad == null
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppStatusChip(
                                  label: '${a.capacidad} puestos',
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FormularioAeronave extends StatefulWidget {
  const _FormularioAeronave();

  @override
  State<_FormularioAeronave> createState() => _FormularioAeronaveState();
}

class _FormularioAeronaveState extends State<_FormularioAeronave> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _matriculaController = TextEditingController();
  final _tipoController = TextEditingController();
  final _modeloController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _capacidadController = TextEditingController(text: '1');

  bool _cargandoOpciones = true;
  bool _guardando = false;
  String? _error;
  List<Propietario> _propietarios = [];
  List<Map<String, dynamic>> _aeropuertos = [];
  List<Map<String, dynamic>> _hangares = [];
  String? _propietarioSeleccionadoId;
  String? _aeropuertoSeleccionadoId;
  String? _hangarSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    try {
      final propietariosData = await _supabase
          .from('propietarios')
          .select('id, nombre, cedula_rif')
          .order('nombre');
      final aeropuertosData = await _supabase
          .from('aeropuertos')
          .select('id, nombre, codigo')
          .order('nombre');
      final hangaresData = await _supabase
          .from('hangares')
          .select('id, codigo_hangar, estado, aeropuertos(nombre, codigo)')
          .order('codigo_hangar');

      setState(() {
        _propietarios = (propietariosData as List)
            .map((e) => Propietario.fromMap(e as Map<String, dynamic>))
            .toList();
        _aeropuertos = (aeropuertosData as List).cast<Map<String, dynamic>>();
        _hangares = (hangaresData as List).cast<Map<String, dynamic>>();
        _cargandoOpciones = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las opciones.';
        _cargandoOpciones = false;
      });
    }
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _tipoController.dispose();
    _modeloController.dispose();
    _fabricanteController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _hangarSeleccionado() {
    for (final hangar in _hangares) {
      if (hangar['id'] == _hangarSeleccionadoId) return hangar;
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_propietarioSeleccionadoId == null) {
      setState(() => _error = 'Selecciona un propietario.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final hangar = _hangarSeleccionado();
      final insertado = await _supabase
          .from('aeronaves')
          .insert({
            'matricula': _matriculaController.text.trim().toUpperCase(),
            'tipo_aeronave': _tipoController.text.trim().isEmpty
                ? null
                : _tipoController.text.trim(),
            'modelo': _modeloController.text.trim().isEmpty
                ? null
                : _modeloController.text.trim(),
            'fabricante': _fabricanteController.text.trim().isEmpty
                ? null
                : _fabricanteController.text.trim(),
            'capacidad': int.tryParse(_capacidadController.text.trim()) ?? 1,
            'aeropuerto_id': _aeropuertoSeleccionadoId,
            'hangar_asignado': hangar == null ? null : hangar['codigo_hangar'],
            'propietario_id': _propietarioSeleccionadoId,
          })
          .select('id')
          .single();

      if (_hangarSeleccionadoId != null) {
        await _supabase.from('asignaciones_hangar').insert({
          'aeronave_id': insertado['id'],
          'hangar_id': _hangarSeleccionadoId,
          'estado_asignacion': 'Activa',
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error =
            'No se pudo registrar. Verifica que la matricula no este duplicada.';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registrar aeronave',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _matriculaController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Matricula',
                hintText: 'Ej: YV-1234',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tipoController,
              decoration: const InputDecoration(
                labelText: 'Tipo de aeronave (opcional)',
                hintText: 'Ej: Jet privado',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modeloController,
              decoration: const InputDecoration(labelText: 'Modelo (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fabricanteController,
              decoration: const InputDecoration(
                labelText: 'Fabricante (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidad'),
              validator: (v) =>
                  (int.tryParse(v ?? '') == null || int.parse(v!) <= 0)
                  ? 'Numero invalido'
                  : null,
            ),
            const SizedBox(height: 12),
            _cargandoOpciones
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _propietarioSeleccionadoId,
                        decoration: const InputDecoration(
                          labelText: 'Propietario',
                        ),
                        items: _propietarios
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _propietarioSeleccionadoId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _aeropuertoSeleccionadoId,
                        decoration: const InputDecoration(
                          labelText: 'Aeropuerto (opcional)',
                        ),
                        items: _aeropuertos
                            .map(
                              (a) => DropdownMenuItem(
                                value: a['id'] as String,
                                child: Text('${a['nombre']} (${a['codigo']})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _aeropuertoSeleccionadoId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _hangarSeleccionadoId,
                        decoration: const InputDecoration(
                          labelText: 'Hangar asignado (opcional)',
                        ),
                        items: _hangares.map((h) {
                          final aeropuerto =
                              h['aeropuertos'] as Map<String, dynamic>?;
                          return DropdownMenuItem(
                            value: h['id'] as String,
                            child: Text(
                              '${h['codigo_hangar']}'
                              '${aeropuerto == null ? '' : ' - ${aeropuerto['codigo']}'}'
                              ' (${h['estado']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _hangarSeleccionadoId = value),
                      ),
                    ],
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
