import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'admin_detail_sheet.dart';

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
    if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  Color _estadoColor(String estado) {
    if (estado == 'aprobado') return AppColors.success;
    if (estado == 'pendiente') return AppColors.warning;
    return Colors.grey;
  }

  void _mostrarDetalle(Map<String, dynamic> pago) {
    final metodo = _nestedMap(pago['metodos_pago']);
    final comprobante = _nestedMap(pago['comprobantes']);
    final detalle = _nestedMap(pago['detalle_pagos']);
    final cancelacion = _nestedMap(pago['cancelaciones_pago']);
    final liquidacion = _nestedMap(pago['liquidaciones']);
    final tipo = _nestedMap(liquidacion?['tipos_impuesto']);
    final operacion = _nestedMap(liquidacion?['operaciones']);
    final aeronave = _nestedMap(operacion?['aeronaves']);
    final estado = pago['estado'] as String? ?? 'pendiente';

    showAdminDetailSheet(
      context: context,
      title:
          comprobante?['numero_comprobante'] as String? ??
          'Pago sin comprobante',
      icon: estado == 'aprobado'
          ? Icons.check_circle_outline
          : Icons.pending_actions_outlined,
      statusLabel: estado,
      statusColor: _estadoColor(estado),
      rows: [
        AdminDetailRow(
          label: 'Aeronave',
          value: aeronave?['matricula'] as String?,
          icon: Icons.flight,
        ),
        AdminDetailRow(
          label: 'Impuesto',
          value: tipo?['nombre'] as String?,
          icon: Icons.receipt_long,
        ),
        AdminDetailRow(
          label: 'Metodo',
          value: metodo?['nombre'] as String?,
          icon: Icons.payments_outlined,
        ),
        AdminDetailRow(
          label: 'Monto pagado',
          value:
              'Bs. ${((pago['monto_pagado'] as num?) ?? 0).toStringAsFixed(2)}',
          icon: Icons.attach_money,
        ),
        AdminDetailRow(
          label: 'Monto aplicado',
          value: cancelacion?['monto_aplicado'] == null
              ? null
              : 'Bs. ${cancelacion!['monto_aplicado']}',
          icon: Icons.done_all,
        ),
        AdminDetailRow(
          label: 'Referencia',
          value: pago['referencia_simulada'] as String?,
          icon: Icons.confirmation_number_outlined,
        ),
        AdminDetailRow(
          label: 'Banco',
          value: detalle?['banco'] as String?,
          icon: Icons.account_balance_outlined,
        ),
        AdminDetailRow(
          label: 'Telefono',
          value: detalle?['telefono'] as String?,
          icon: Icons.phone_outlined,
        ),
        AdminDetailRow(
          label: 'Titular',
          value: detalle?['titular'] as String?,
          icon: Icons.person_outline,
        ),
        AdminDetailRow(
          label: 'Tarjeta',
          value: detalle?['ultimos4'] == null
              ? null
              : '**** ${detalle!['ultimos4']}',
          icon: Icons.credit_card,
        ),
        AdminDetailRow(
          label: 'Fecha de pago',
          value: pago['fecha_pago'] as String?,
          icon: Icons.event_outlined,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos y comprobantes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
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
                        onTap: () => _mostrarDetalle(pago),
                        leading: Icon(
                          estado == 'aprobado'
                              ? Icons.check_circle_outline
                              : Icons.pending_actions_outlined,
                          color: estado == 'aprobado'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        title: Text(
                          comprobante?['numero_comprobante'] as String? ??
                              'Pago sin comprobante',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (aeronave?['matricula'] != null)
                              'Aeronave: ${aeronave!['matricula']}',
                            if (tipo?['nombre'] != null)
                              tipo!['nombre'] as String,
                            if (metodo?['nombre'] != null)
                              metodo!['nombre'] as String,
                            if (detalle?['banco'] != null)
                              'Banco: ${detalle!['banco']}',
                            if (detalle?['telefono'] != null)
                              'Tel: ${detalle!['telefono']}',
                            if (detalle?['ultimos4'] != null)
                              'Tarjeta: **** ${detalle!['ultimos4']}',
                            if (cancelacion?['monto_aplicado'] != null)
                              'Aplicado: Bs. ${cancelacion!['monto_aplicado']}',
                            if (pago['referencia_simulada'] != null)
                              'Ref: ${pago['referencia_simulada']}',
                          ].join(' - '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bs. ${((pago['monto_pagado'] as num?) ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
            ),
    );
  }
}
