import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/operacion.dart';
import '../../models/tipo_impuesto.dart';
import '../../theme/app_theme.dart';

class _LiquidacionAdmin {
  final String id;
  final String matricula;
  final String tipoOperacion;
  final String tipoImpuestoNombre;
  final double monto;
  final String estado;

  _LiquidacionAdmin({
    required this.id,
    required this.matricula,
    required this.tipoOperacion,
    required this.tipoImpuestoNombre,
    required this.monto,
    required this.estado,
  });

  factory _LiquidacionAdmin.fromMap(Map<String, dynamic> map) {
    final operacion = map['operaciones'] as Map<String, dynamic>?;
    final aeronave = operacion?['aeronaves'] as Map<String, dynamic>?;
    final tipoImpuesto = map['tipos_impuesto'] as Map<String, dynamic>?;
    return _LiquidacionAdmin(
      id: map['id'] as String,
      matricula: aeronave?['matricula'] as String? ?? '—',
      tipoOperacion: operacion?['tipo_operacion'] as String? ?? '',
      tipoImpuestoNombre: tipoImpuesto?['nombre'] as String? ?? '',
      monto: (map['monto'] as num).toDouble(),
      estado: map['estado'] as String,
    );
  }
}

class LiquidacionesScreen extends StatefulWidget {
  const LiquidacionesScreen({super.key});

  @override
  State<LiquidacionesScreen> createState() => _LiquidacionesScreenState();
}

class _LiquidacionesScreenState extends State<LiquidacionesScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<_LiquidacionAdmin> _liquidaciones = [];

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
          .from('liquidaciones')
          .select(
            'id, monto, estado, fecha_liquidacion, '
            'tipos_impuesto(nombre), operaciones(tipo_operacion, aeronaves(matricula))',
          )
          .order('fecha_liquidacion', ascending: false)
          .limit(50);

      setState(() {
        _liquidaciones = (data as List)
            .map((e) => _LiquidacionAdmin.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las liquidaciones.';
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
      builder: (_) => const _FormularioLiquidacion(),
    );
    if (creado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liquidaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Generar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _liquidaciones.isEmpty
                  ? const Center(child: Text('No hay liquidaciones registradas.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _liquidaciones.length,
                      itemBuilder: (context, index) {
                        final l = _liquidaciones[index];
                        final pendiente = l.estado == 'pendiente';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                              title: Text('${l.matricula} · ${l.tipoImpuestoNombre}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Bs. ${l.monto.toStringAsFixed(2)}'),
                              trailing: AppStatusChip(
                                label: pendiente ? 'Pendiente' : (l.estado == 'pagado' ? 'Pagado' : 'Anulado'),
                                color: pendiente ? AppColors.warning : AppColors.success,
                                backgroundColor: pendiente ? AppColors.warningBg : AppColors.successBg,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _FormularioLiquidacion extends StatefulWidget {
  const _FormularioLiquidacion();

  @override
  State<_FormularioLiquidacion> createState() => _FormularioLiquidacionState();
}

class _FormularioLiquidacionState extends State<_FormularioLiquidacion> {
  final _supabase = Supabase.instance.client;

  bool _cargandoOpciones = true;
  bool _guardando = false;
  String? _error;
  List<Operacion> _operaciones = [];
  List<TipoImpuesto> _tiposImpuesto = [];
  String? _operacionSeleccionadaId;
  String? _tipoImpuestoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    try {
      final operacionesData = await _supabase
          .from('operaciones')
          .select('id, aeronave_id, tipo_operacion, fecha_operacion, piloto_responsable, aeronaves(matricula)')
          .order('fecha_operacion', ascending: false)
          .limit(50);

      final tiposData = await _supabase
          .from('tipos_impuesto')
          .select('id, nombre, monto_base')
          .eq('vigente', true)
          .order('nombre');

      setState(() {
        _operaciones = (operacionesData as List)
            .map((e) => Operacion.fromMap(e as Map<String, dynamic>))
            .toList();
        _tiposImpuesto = (tiposData as List)
            .map((e) => TipoImpuesto.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargandoOpciones = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las opciones.';
        _cargandoOpciones = false;
      });
    }
  }

  double? get _montoSeleccionado {
    if (_tipoImpuestoSeleccionadoId == null) return null;
    return _tiposImpuesto
        .firstWhere((t) => t.id == _tipoImpuestoSeleccionadoId)
        .montoBase;
  }

  Future<void> _guardar() async {
    if (_operacionSeleccionadaId == null || _tipoImpuestoSeleccionadoId == null) {
      setState(() => _error = 'Selecciona la operación y el tipo de impuesto.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _supabase.from('liquidaciones').insert({
        'operacion_id': _operacionSeleccionadaId,
        'tipo_impuesto_id': _tipoImpuestoSeleccionadoId,
        'monto': _montoSeleccionado,
        'estado': 'pendiente',
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'No se pudo generar la liquidación.';
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
          Text('Generar liquidación', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _cargandoOpciones
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _operacionSeleccionadaId,
                      decoration: const InputDecoration(labelText: 'Operación'),
                      isExpanded: true,
                      items: _operaciones
                          .map((o) => DropdownMenuItem(
                                value: o.id,
                                child: Text(
                                  '${o.matricula} · ${o.tipoOperacion} · '
                                  '${o.fechaOperacion.day.toString().padLeft(2, '0')}/${o.fechaOperacion.month.toString().padLeft(2, '0')}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _operacionSeleccionadaId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoImpuestoSeleccionadoId,
                      decoration: const InputDecoration(labelText: 'Tipo de impuesto'),
                      items: _tiposImpuesto
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.nombre} (Bs. ${t.montoBase.toStringAsFixed(2)})'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _tipoImpuestoSeleccionadoId = value),
                    ),
                    if (_montoSeleccionado != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monto a liquidar'),
                            Text(
                              'Bs. ${_montoSeleccionado!.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
