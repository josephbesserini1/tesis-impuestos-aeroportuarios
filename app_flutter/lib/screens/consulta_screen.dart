import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aeronave.dart';
import '../models/liquidacion_pendiente.dart';
import '../theme/app_theme.dart';
import 'pago_screen.dart';

class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({super.key});

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  final _supabase = Supabase.instance.client;
  final _matriculaController = TextEditingController();

  bool _buscando = false;
  String? _error;
  bool _seHaBuscado = false;
  Aeronave? _aeronave;
  List<LiquidacionPendiente> _liquidaciones = [];

  @override
  void dispose() {
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final matricula = _matriculaController.text.trim().toUpperCase();
    if (matricula.isEmpty) return;

    setState(() {
      _buscando = true;
      _error = null;
      _seHaBuscado = true;
      _aeronave = null;
      _liquidaciones = [];
    });

    try {
      final aeronaveData = await _supabase
          .from('aeronaves')
          .select('id, matricula, tipo_aeronave, modelo, hangar_asignado, propietarios(nombre)')
          .eq('matricula', matricula)
          .maybeSingle();

      if (aeronaveData == null) {
        setState(() => _buscando = false);
        return;
      }

      final aeronave = Aeronave.fromMap(aeronaveData);

      final liquidacionesData = await _supabase
          .from('liquidaciones')
          .select(
            'id, monto, fecha_liquidacion, tipos_impuesto(nombre, descripcion), '
            'operaciones!inner(aeronave_id)',
          )
          .eq('estado', 'pendiente')
          .eq('operaciones.aeronave_id', aeronave.id)
          .order('fecha_liquidacion');

      setState(() {
        _aeronave = aeronave;
        _liquidaciones = (liquidacionesData as List)
            .map((e) => LiquidacionPendiente.fromMap(e as Map<String, dynamic>))
            .toList();
        _buscando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error al consultar. Intenta nuevamente.';
        _buscando = false;
      });
    }
  }

  double get _totalPendiente =>
      _liquidaciones.fold(0, (total, l) => total + l.monto);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta de impuestos')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _matriculaController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Matrícula de la aeronave',
                hintText: 'Ej: YV-1234',
                prefixIcon: Icon(Icons.flight, color: AppColors.primary),
              ),
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _buscando ? null : _buscar,
              icon: _buscando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildResultado()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (!_seHaBuscado) {
      return const SizedBox.shrink();
    }

    if (_aeronave == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No se encontró ninguna aeronave con esa matrícula.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final aeronave = _aeronave!;
    final hayPendientes = _liquidaciones.isNotEmpty;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flight, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aeronave.matricula, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          if (aeronave.tipoAeronave != null)
                            Text(aeronave.tipoAeronave!, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    AppStatusChip(
                      label: hayPendientes ? 'Pendiente' : 'Al día',
                      color: hayPendientes ? AppColors.warning : AppColors.success,
                      backgroundColor: hayPendientes ? AppColors.warningBg : AppColors.successBg,
                    ),
                  ],
                ),
                const Divider(height: 28),
                if (aeronave.modelo != null) _buildInfoRow(Icons.directions_car_filled_outlined, 'Modelo', aeronave.modelo!),
                if (aeronave.propietarioNombre != null) _buildInfoRow(Icons.person_outline, 'Propietario', aeronave.propietarioNombre!),
                if (aeronave.hangarAsignado != null) _buildInfoRow(Icons.warehouse_outlined, 'Hangar', aeronave.hangarAsignado!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Liquidaciones pendientes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_liquidaciones.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Esta aeronave no tiene liquidaciones pendientes.')),
                ],
              ),
            ),
          )
        else ...[
          for (final liquidacion in _liquidaciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(liquidacion.tipoImpuestoNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (liquidacion.tipoImpuestoDescripcion != null)
                              Text(
                                liquidacion.tipoImpuestoDescripcion!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'Bs. ${liquidacion.monto.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(
                  'Bs. ${_totalPendiente.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PagoScreen(
                    aeronave: aeronave,
                    liquidaciones: _liquidaciones,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            label: Text('Pagar total (Bs. ${_totalPendiente.toStringAsFixed(2)})'),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
