import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'admin_detail_sheet.dart';

class CatalogosScreen extends StatefulWidget {
  const CatalogosScreen({super.key});

  @override
  State<CatalogosScreen> createState() => _CatalogosScreenState();
}

class _CatalogosScreenState extends State<CatalogosScreen> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _tiposImpuesto = [];
  List<Map<String, dynamic>> _metodosPago = [];

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
      final tiposData = await _supabase
          .from('tipos_impuesto')
          .select(
            'id, nombre, descripcion, monto_base, moneda, criterio_calculo, vigente',
          )
          .order('nombre');
      final metodosData = await _supabase
          .from('metodos_pago')
          .select('id, nombre, activo')
          .order('nombre');

      setState(() {
        _tiposImpuesto = (tiposData as List).cast<Map<String, dynamic>>();
        _metodosPago = (metodosData as List).cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los catalogos.';
        _cargando = false;
      });
    }
  }

  void _mostrarTipoImpuesto(Map<String, dynamic> tipo) {
    final vigente = tipo['vigente'] == true;
    showAdminDetailSheet(
      context: context,
      title: tipo['nombre'] as String? ?? 'Impuesto',
      icon: Icons.receipt_long,
      statusLabel: vigente ? 'Vigente' : 'Inactivo',
      statusColor: vigente ? AppColors.success : AppColors.warning,
      rows: [
        AdminDetailRow(
          label: 'Descripcion',
          value: tipo['descripcion'] as String?,
          icon: Icons.notes_outlined,
        ),
        AdminDetailRow(
          label: 'Monto base',
          value:
              'Bs. ${((tipo['monto_base'] as num?) ?? 0).toStringAsFixed(2)}',
          icon: Icons.payments_outlined,
        ),
        AdminDetailRow(
          label: 'Moneda',
          value: tipo['moneda'] as String?,
          icon: Icons.currency_exchange,
        ),
        AdminDetailRow(
          label: 'Criterio',
          value: tipo['criterio_calculo'] as String?,
          icon: Icons.rule_outlined,
        ),
      ],
    );
  }

  void _mostrarMetodoPago(Map<String, dynamic> metodo) {
    final activo = metodo['activo'] == true;
    showAdminDetailSheet(
      context: context,
      title: metodo['nombre'] as String? ?? 'Metodo de pago',
      icon: Icons.payments_outlined,
      statusLabel: activo ? 'Activo' : 'Inactivo',
      statusColor: activo ? AppColors.success : AppColors.warning,
      rows: [
        AdminDetailRow(
          label: 'Nombre',
          value: metodo['nombre'] as String?,
          icon: Icons.label_outline,
        ),
        AdminDetailRow(
          label: 'Estado',
          value: activo ? 'Activo' : 'Inactivo',
          icon: Icons.info_outline,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Tipos de impuesto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_tiposImpuesto.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay tipos de impuesto.'),
                      ),
                    )
                  else
                    for (final tipo in _tiposImpuesto)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            onTap: () => _mostrarTipoImpuesto(tipo),
                            leading: const Icon(
                              Icons.receipt_long,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              tipo['nombre'] as String? ?? 'Impuesto',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (tipo['descripcion'] != null)
                                  tipo['descripcion'] as String,
                                'Base: Bs. ${((tipo['monto_base'] as num?) ?? 0).toStringAsFixed(2)}',
                                if (tipo['criterio_calculo'] != null)
                                  'Criterio: ${tipo['criterio_calculo']}',
                              ].join(' - '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppStatusChip(
                                  label: tipo['vigente'] == true
                                      ? 'Vigente'
                                      : 'Inactivo',
                                  color: tipo['vigente'] == true
                                      ? AppColors.success
                                      : AppColors.warning,
                                  backgroundColor:
                                      (tipo['vigente'] == true
                                              ? AppColors.success
                                              : AppColors.warning)
                                          .withValues(alpha: 0.1),
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
                      ),
                  const SizedBox(height: 22),
                  Text(
                    'Metodos de pago',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_metodosPago.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay metodos de pago.'),
                      ),
                    )
                  else
                    for (final metodo in _metodosPago)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            onTap: () => _mostrarMetodoPago(metodo),
                            leading: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              metodo['nombre'] as String? ?? 'Metodo de pago',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppStatusChip(
                                  label: metodo['activo'] == true
                                      ? 'Activo'
                                      : 'Inactivo',
                                  color: metodo['activo'] == true
                                      ? AppColors.success
                                      : AppColors.warning,
                                  backgroundColor:
                                      (metodo['activo'] == true
                                              ? AppColors.success
                                              : AppColors.warning)
                                          .withValues(alpha: 0.1),
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
                      ),
                ],
              ),
            ),
    );
  }
}
