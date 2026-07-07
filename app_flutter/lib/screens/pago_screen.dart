import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aeronave.dart';
import '../models/comprobante_pago.dart';
import '../models/liquidacion_pendiente.dart';
import '../models/metodo_pago.dart';
import '../theme/app_theme.dart';
import 'comprobante_screen.dart';

class PagoScreen extends StatefulWidget {
  final Aeronave aeronave;
  final List<LiquidacionPendiente> liquidaciones;

  const PagoScreen({super.key, required this.aeronave, required this.liquidaciones});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _supabase = Supabase.instance.client;

  bool _cargandoMetodos = true;
  bool _procesando = false;
  String? _error;
  List<MetodoPago> _metodos = [];
  String? _metodoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _cargarMetodos();
  }

  Future<void> _cargarMetodos() async {
    try {
      final data = await _supabase
          .from('metodos_pago')
          .select('id, nombre')
          .eq('activo', true)
          .order('nombre');

      setState(() {
        _metodos = (data as List)
            .map((e) => MetodoPago.fromMap(e as Map<String, dynamic>))
            .toList();
        _metodoSeleccionadoId = _metodos.isNotEmpty ? _metodos.first.id : null;
        _cargandoMetodos = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los métodos de pago.';
        _cargandoMetodos = false;
      });
    }
  }

  double get _total => widget.liquidaciones.fold(0, (total, l) => total + l.monto);

  IconData _iconoMetodo(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('móvil') || n.contains('movil')) return Icons.smartphone;
    if (n.contains('transferencia')) return Icons.account_balance;
    if (n.contains('tarjeta')) return Icons.credit_card;
    return Icons.payments_outlined;
  }

  Future<void> _confirmarPago() async {
    if (_metodoSeleccionadoId == null) return;

    setState(() {
      _procesando = true;
      _error = null;
    });

    try {
      final data = await _supabase.rpc('procesar_pago', params: {
        'p_aeronave_id': widget.aeronave.id,
        'p_metodo_pago_id': _metodoSeleccionadoId,
      });

      final comprobantes = (data as List)
          .map((e) => ComprobantePago.fromMap(e as Map<String, dynamic>))
          .toList();

      final metodoNombre = _metodos
          .firstWhere((m) => m.id == _metodoSeleccionadoId)
          .nombre;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ComprobanteScreen(
            matricula: widget.aeronave.matricula,
            metodoPagoNombre: metodoNombre,
            comprobantes: comprobantes,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'No se pudo procesar el pago. Intenta nuevamente.';
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pago')),
      body: _cargandoMetodos
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
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
                                    Text(
                                      widget.aeronave.matricula,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Divider(height: 28),
                                for (final l in widget.liquidaciones)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(l.tipoImpuestoNombre)),
                                        Text('Bs. ${l.monto.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                'Bs. ${_total.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Método de pago', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        for (final metodo in _metodos)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MetodoPagoCard(
                              nombre: metodo.nombre,
                              icono: _iconoMetodo(metodo.nombre),
                              seleccionado: metodo.id == _metodoSeleccionadoId,
                              onTap: _procesando
                                  ? null
                                  : () => setState(() => _metodoSeleccionadoId = metodo.id),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (_procesando || _metodoSeleccionadoId == null) ? null : _confirmarPago,
                    icon: _procesando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar pago'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MetodoPagoCard extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback? onTap;

  const _MetodoPagoCard({
    required this.nombre,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionado ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionado ? AppColors.primary : Colors.grey.shade300,
              width: seleccionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icono, color: seleccionado ? AppColors.primary : Colors.grey.shade600),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                    color: seleccionado ? AppColors.primary : Colors.black87,
                  ),
                ),
              ),
              Icon(
                seleccionado ? Icons.check_circle : Icons.circle_outlined,
                color: seleccionado ? AppColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
