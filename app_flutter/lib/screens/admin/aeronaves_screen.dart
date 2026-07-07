import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/aeronave.dart';
import '../../models/propietario.dart';
import '../../theme/app_theme.dart';

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
          .select('id, matricula, tipo_aeronave, modelo, hangar_asignado, propietarios(nombre)')
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
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
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
                              leading: const Icon(Icons.flight, color: AppColors.primary),
                              title: Text(a.matricula, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if (a.tipoAeronave != null) a.tipoAeronave!,
                                if (a.propietarioNombre != null) 'Dueño: ${a.propietarioNombre}',
                              ].join(' · ')),
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
  final _hangarController = TextEditingController();

  bool _cargandoPropietarios = true;
  bool _guardando = false;
  String? _error;
  List<Propietario> _propietarios = [];
  String? _propietarioSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _cargarPropietarios();
  }

  Future<void> _cargarPropietarios() async {
    try {
      final data = await _supabase
          .from('propietarios')
          .select('id, nombre, cedula_rif')
          .order('nombre');

      setState(() {
        _propietarios = (data as List)
            .map((e) => Propietario.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargandoPropietarios = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los propietarios.';
        _cargandoPropietarios = false;
      });
    }
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _tipoController.dispose();
    _modeloController.dispose();
    _hangarController.dispose();
    super.dispose();
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
      await _supabase.from('aeronaves').insert({
        'matricula': _matriculaController.text.trim().toUpperCase(),
        'tipo_aeronave': _tipoController.text.trim().isEmpty ? null : _tipoController.text.trim(),
        'modelo': _modeloController.text.trim().isEmpty ? null : _modeloController.text.trim(),
        'hangar_asignado': _hangarController.text.trim().isEmpty ? null : _hangarController.text.trim(),
        'propietario_id': _propietarioSeleccionadoId,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'No se pudo registrar. Verifica que la matrícula no esté duplicada.';
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registrar aeronave', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _matriculaController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Matrícula', hintText: 'Ej: YV-1234'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tipoController,
              decoration: const InputDecoration(labelText: 'Tipo de aeronave (opcional)', hintText: 'Ej: Jet privado'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modeloController,
              decoration: const InputDecoration(labelText: 'Modelo (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hangarController,
              decoration: const InputDecoration(labelText: 'Hangar asignado (opcional)'),
            ),
            const SizedBox(height: 12),
            _cargandoPropietarios
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _propietarioSeleccionadoId,
                    decoration: const InputDecoration(labelText: 'Propietario'),
                    items: _propietarios
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (value) => setState(() => _propietarioSeleccionadoId = value),
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
      ),
    );
  }
}
