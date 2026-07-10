import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class AeropuertosScreen extends StatefulWidget {
  const AeropuertosScreen({super.key});

  @override
  State<AeropuertosScreen> createState() => _AeropuertosScreenState();
}

class _AeropuertosScreenState extends State<AeropuertosScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _aeropuertos = [];

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
      final data = await _supabase.from('aeropuertos').select('id, nombre, codigo, ciudad, estado, pais').order('nombre');
      setState(() {
        _aeropuertos = (data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los aeropuertos.';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFormulario() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FormularioAeropuerto(),
    );
    if (creado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aeropuertos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _aeropuertos.isEmpty
                  ? const Center(child: Text('No hay aeropuertos registrados.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _aeropuertos.length,
                      itemBuilder: (context, index) {
                        final a = _aeropuertos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: const Icon(Icons.local_airport_outlined, color: AppColors.primary),
                              title: Text('${a['nombre']} (${a['codigo']})', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([a['ciudad'], a['estado'], a['pais']].whereType<String>().join(' - ')),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _FormularioAeropuerto extends StatefulWidget {
  const _FormularioAeropuerto();

  @override
  State<_FormularioAeropuerto> createState() => _FormularioAeropuertoState();
}

class _FormularioAeropuertoState extends State<_FormularioAeropuerto> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _calleController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController();
  final _paisController = TextEditingController(text: 'Venezuela');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _calleController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _paisController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _supabase.from('aeropuertos').insert({
        'nombre': _nombreController.text.trim(),
        'codigo': _codigoController.text.trim().toUpperCase(),
        'calle': _calleController.text.trim().isEmpty ? null : _calleController.text.trim(),
        'ciudad': _ciudadController.text.trim().isEmpty ? null : _ciudadController.text.trim(),
        'estado': _estadoController.text.trim().isEmpty ? null : _estadoController.text.trim(),
        'pais': _paisController.text.trim().isEmpty ? 'Venezuela' : _paisController.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'No se pudo registrar. Verifica que el codigo no este duplicado.';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registrar aeropuerto', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Codigo', hintText: 'Ej: CCS'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _calleController, decoration: const InputDecoration(labelText: 'Calle o zona (opcional)')),
            const SizedBox(height: 12),
            TextFormField(controller: _ciudadController, decoration: const InputDecoration(labelText: 'Ciudad (opcional)')),
            const SizedBox(height: 12),
            TextFormField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado (opcional)')),
            const SizedBox(height: 12),
            TextFormField(controller: _paisController, decoration: const InputDecoration(labelText: 'Pais')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
