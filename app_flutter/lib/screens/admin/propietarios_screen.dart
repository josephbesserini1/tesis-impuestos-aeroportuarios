import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/propietario.dart';
import '../../theme/app_theme.dart';

class PropietariosScreen extends StatefulWidget {
  const PropietariosScreen({super.key});

  @override
  State<PropietariosScreen> createState() => _PropietariosScreenState();
}

class _PropietariosScreenState extends State<PropietariosScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Propietario> _propietarios = [];

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
          .from('propietarios')
          .select('id, nombre, cedula_rif, telefono, email')
          .order('created_at', ascending: false);

      setState(() {
        _propietarios = (data as List)
            .map((e) => Propietario.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los propietarios.';
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
      builder: (_) => const _FormularioPropietario(),
    );
    if (creado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propietarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _propietarios.isEmpty
                  ? const Center(child: Text('No hay propietarios registrados.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _propietarios.length,
                      itemBuilder: (context, index) {
                        final p = _propietarios[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: const Icon(Icons.person_outline, color: AppColors.primary),
                              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${p.cedulaRif}${p.telefono != null ? ' · ${p.telefono}' : ''}'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _FormularioPropietario extends StatefulWidget {
  const _FormularioPropietario();

  @override
  State<_FormularioPropietario> createState() => _FormularioPropietarioState();
}

class _FormularioPropietarioState extends State<_FormularioPropietario> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _supabase.from('propietarios').insert({
        'nombre': _nombreController.text.trim(),
        'cedula_rif': _cedulaController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'No se pudo registrar. Verifica que la cédula/RIF no esté duplicada.';
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
            Text('Registrar propietario', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre completo o razón social'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cedulaController,
              decoration: const InputDecoration(labelText: 'Cédula o RIF', hintText: 'Ej: V-12345678'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
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
