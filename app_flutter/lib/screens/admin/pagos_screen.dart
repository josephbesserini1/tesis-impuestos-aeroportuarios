import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _pagos = [];

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
          .from('pagos')
          .select(
            'id, monto_pagado, referencia_simulada, estado, fecha_pago, '
            'metodos_pago(nombre), comprobantes(numero_comprobante), '
            'detalle_pagos(banco, telefono, titular, ultimos4, referencia_cliente), '
            'cancelaciones_pago(monto_aplicado), '
            'liquidaciones(tipos_impuesto(nombre), operaciones(aeronaves(matricula)))',
          )
          .order('fecha_pago', ascending: false)
          .limit(100);

      setState(() {
        _pagos = (data as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los pagos.';
        _cargando = false;
      });
    }
  }

  Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos y comprobantes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _pagos.isEmpty
                  ? const Center(child: Text('No hay pagos registrados.'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _pagos.length,
                        itemBuilder: (context, index) {
                          final pago = _pagos[index];
                          final metodo = _nestedMap(pago['metodos_pago']);
                          final comprobante = _nestedMap(pago['comprobantes']);
                          final detalle = _nestedMap(pago['detalle_pagos']);
                          final cancelacion = _nestedMap(pago['cancelaciones_pago']);
                          final liquidacion = _nestedMap(pago['liquidaciones']);
                          final tipo = _nestedMap(liquidacion?['tipos_impuesto']);
                          final operacion = _nestedMap(liquidacion?['operaciones']);
                          final aeronave = _nestedMap(operacion?['aeronaves']);
                          final estado = pago['estado'] as String? ?? 'pendiente';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                leading: Icon(
                                  estado == 'aprobado' ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                                  color: estado == 'aprobado' ? AppColors.success : AppColors.warning,
                                ),
                                title: Text(
                                  comprobante?['numero_comprobante'] as String? ?? 'Pago sin comprobante',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text([
                                  if (aeronave?['matricula'] != null) 'Aeronave: ${aeronave!['matricula']}',
                                  if (tipo?['nombre'] != null) tipo!['nombre'] as String,
                                  if (metodo?['nombre'] != null) metodo!['nombre'] as String,
                                  if (detalle?['banco'] != null) 'Banco: ${detalle!['banco']}',
                                  if (detalle?['telefono'] != null) 'Tel: ${detalle!['telefono']}',
                                  if (detalle?['ultimos4'] != null) 'Tarjeta: **** ${detalle!['ultimos4']}',
                                  if (cancelacion?['monto_aplicado'] != null) 'Aplicado: Bs. ${cancelacion!['monto_aplicado']}',
                                  if (pago['referencia_simulada'] != null) 'Ref: ${pago['referencia_simulada']}',
                                ].join(' - ')),
                                trailing: Text(
                                  'Bs. ${((pago['monto_pagado'] as num?) ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
