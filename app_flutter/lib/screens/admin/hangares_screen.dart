import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'admin_detail_sheet.dart';

class HangaresScreen extends StatefulWidget {
  const HangaresScreen({super.key});

  @override
  State<HangaresScreen> createState() => _HangaresScreenState();
}

class _HangaresScreenState extends State<HangaresScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _hangares = [];

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
          .from('hangares')
          .select(
            'id, codigo_hangar, estado, capacidad, aeropuertos(nombre, codigo)',
          )
          .order('codigo_hangar');
      setState(() {
        _hangares = (data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los hangares.';
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
      builder: (_) => const _FormularioHangar(),
    );
    if (creado == true) _cargar();
  }

  Color _estadoColor(String estado) {
    if (estado == 'Disponible') return AppColors.success;
    if (estado == 'Mantenimiento') return AppColors.warning;
    return AppColors.primary;
  }

  void _mostrarDetalle(Map<String, dynamic> h) {
    final aeropuerto = h['aeropuertos'] as Map<String, dynamic>?;
    final estado = h['estado'] as String? ?? 'Disponible';
    showAdminDetailSheet(
      context: context,
      title: h['codigo_hangar'] as String? ?? 'Hangar',
      icon: Icons.warehouse_outlined,
      statusLabel: estado,
      statusColor: _estadoColor(estado),
      rows: [
        AdminDetailRow(
          label: 'Aeropuerto',
          value: aeropuerto == null
              ? null
              : '${aeropuerto['nombre']} (${aeropuerto['codigo']})',
          icon: Icons.local_airport_outlined,
        ),
        AdminDetailRow(
          label: 'Capacidad',
          value: '${h['capacidad']}',
          icon: Icons.event_seat_outlined,
        ),
        AdminDetailRow(
          label: 'Estado',
          value: estado,
          icon: Icons.info_outline,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hangares')),
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
          : _hangares.isEmpty
          ? const Center(child: Text('No hay hangares registrados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _hangares.length,
              itemBuilder: (context, index) {
                final h = _hangares[index];
                final aeropuerto = h['aeropuertos'] as Map<String, dynamic>?;
                final estado = h['estado'] as String? ?? 'Disponible';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _mostrarDetalle(h),
                      leading: const Icon(
                        Icons.warehouse_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        h['codigo_hangar'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if (aeropuerto != null)
                            '${aeropuerto['nombre']} (${aeropuerto['codigo']})',
                          'Capacidad: ${h['capacidad']}',
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
    );
  }
}

class _FormularioHangar extends StatefulWidget {
  const _FormularioHangar();

  @override
  State<_FormularioHangar> createState() => _FormularioHangarState();
}

class _FormularioHangarState extends State<_FormularioHangar> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _capacidadController = TextEditingController(text: '1');
  bool _cargandoAeropuertos = true;
  bool _guardando = false;
  String? _error;
  String? _aeropuertoId;
  String _estado = 'Disponible';
  List<Map<String, dynamic>> _aeropuertos = [];

  @override
  void initState() {
    super.initState();
    _cargarAeropuertos();
  }

  Future<void> _cargarAeropuertos() async {
    try {
      final data = await _supabase
          .from('aeropuertos')
          .select('id, nombre, codigo')
          .order('nombre');
      setState(() {
        _aeropuertos = (data as List).cast<Map<String, dynamic>>();
        _cargandoAeropuertos = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los aeropuertos.';
        _cargandoAeropuertos = false;
      });
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_aeropuertoId == null) {
      setState(() => _error = 'Selecciona un aeropuerto.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _supabase.from('hangares').insert({
        'aeropuerto_id': _aeropuertoId,
        'codigo_hangar': _codigoController.text.trim().toUpperCase(),
        'estado': _estado,
        'capacidad': int.tryParse(_capacidadController.text.trim()) ?? 1,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error =
            'No se pudo registrar. Verifica que el codigo no este duplicado.';
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
              'Registrar hangar',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codigo de hangar',
                hintText: 'Ej: H1',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
            DropdownButtonFormField<String>(
              initialValue: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(
                  value: 'Disponible',
                  child: Text('Disponible'),
                ),
                DropdownMenuItem(value: 'Ocupado', child: Text('Ocupado')),
                DropdownMenuItem(
                  value: 'Mantenimiento',
                  child: Text('Mantenimiento'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _estado = value ?? 'Disponible'),
            ),
            const SizedBox(height: 12),
            _cargandoAeropuertos
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _aeropuertoId,
                    decoration: const InputDecoration(labelText: 'Aeropuerto'),
                    items: _aeropuertos
                        .map(
                          (a) => DropdownMenuItem(
                            value: a['id'] as String,
                            child: Text('${a['nombre']} (${a['codigo']})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _aeropuertoId = value),
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
