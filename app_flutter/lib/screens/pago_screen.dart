import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aeronave.dart';
import '../models/comprobante_pago.dart';
import '../models/liquidacion_pendiente.dart';
import '../models/metodo_pago.dart';
import '../theme/app_theme.dart';
import 'comprobante_screen.dart';

enum _TipoMetodo { pagoMovil, transferencia, tarjeta, otro }

class PagoScreen extends StatefulWidget {
  final Aeronave aeronave;
  final List<LiquidacionPendiente> liquidaciones;

  const PagoScreen({super.key, required this.aeronave, required this.liquidaciones});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _supabase = Supabase.instance.client;

  static const _pasosProcesamiento = [
    'Validando datos del pago...',
    'Registrando en Supabase...',
    'Generando comprobante digital...',
  ];

  bool _cargandoMetodos = true;
  bool _procesando = false;
  int _pasoActual = 0;
  String? _error;
  List<MetodoPago> _metodos = [];
  String? _metodoSeleccionadoId;

  final _telefonoController = TextEditingController();
  final _bancoController = TextEditingController();
  final _numeroReferenciaController = TextEditingController();
  final _numeroTarjetaController = TextEditingController();
  final _titularController = TextEditingController();
  final _vencimientoController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarMetodos();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _bancoController.dispose();
    _numeroReferenciaController.dispose();
    _numeroTarjetaController.dispose();
    _titularController.dispose();
    _vencimientoController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _cargarMetodos() async {
    try {
      final data = await _supabase
          .from('metodos_pago')
          .select('id, nombre')
          .eq('activo', true)
          .order('nombre');

      final metodosPorTipo = <_TipoMetodo, MetodoPago>{};
      for (final item in data as List) {
        final metodo = MetodoPago.fromMap(item as Map<String, dynamic>);
        metodosPorTipo.putIfAbsent(_tipoMetodo(metodo.nombre), () => metodo);
      }

      final metodos = [
        if (metodosPorTipo[_TipoMetodo.pagoMovil] != null) metodosPorTipo[_TipoMetodo.pagoMovil]!,
        if (metodosPorTipo[_TipoMetodo.transferencia] != null) metodosPorTipo[_TipoMetodo.transferencia]!,
        if (metodosPorTipo[_TipoMetodo.tarjeta] != null) metodosPorTipo[_TipoMetodo.tarjeta]!,
        ...metodosPorTipo.entries.where((entry) => entry.key == _TipoMetodo.otro).map((entry) => entry.value),
      ];

      setState(() {
        _metodos = metodos;
        _metodoSeleccionadoId = _metodos.isNotEmpty ? _metodos.first.id : null;
        _cargandoMetodos = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los metodos de pago.';
        _cargandoMetodos = false;
      });
    }
  }

  double get _total => widget.liquidaciones.fold(0, (total, l) => total + l.monto);

  _TipoMetodo _tipoMetodo(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('movil') || (n.contains('pago') && n.contains('vil'))) {
      return _TipoMetodo.pagoMovil;
    }
    if (n.contains('transferencia')) return _TipoMetodo.transferencia;
    if (n.contains('tarjeta')) return _TipoMetodo.tarjeta;
    return _TipoMetodo.otro;
  }

  IconData _iconoMetodo(_TipoMetodo tipo) {
    switch (tipo) {
      case _TipoMetodo.pagoMovil:
        return Icons.smartphone;
      case _TipoMetodo.transferencia:
        return Icons.account_balance;
      case _TipoMetodo.tarjeta:
        return Icons.credit_card;
      case _TipoMetodo.otro:
        return Icons.payments_outlined;
    }
  }

  _TipoMetodo? get _tipoSeleccionado {
    if (_metodoSeleccionadoId == null) return null;
    final metodo = _metodos.firstWhere((m) => m.id == _metodoSeleccionadoId);
    return _tipoMetodo(metodo.nombre);
  }

  String _nombreMetodo(MetodoPago metodo) {
    switch (_tipoMetodo(metodo.nombre)) {
      case _TipoMetodo.pagoMovil:
        return 'Pago movil';
      case _TipoMetodo.transferencia:
        return 'Transferencia';
      case _TipoMetodo.tarjeta:
        return 'Tarjeta';
      case _TipoMetodo.otro:
        return metodo.nombre;
    }
  }

  String _descripcionMetodo(_TipoMetodo tipo) {
    switch (tipo) {
      case _TipoMetodo.pagoMovil:
        return 'Telefono y banco';
      case _TipoMetodo.transferencia:
        return 'Banco y referencia';
      case _TipoMetodo.tarjeta:
        return 'Debito o credito';
      case _TipoMetodo.otro:
        return 'Metodo registrado';
    }
  }

  String? _validarCamposMetodo() {
    switch (_tipoSeleccionado) {
      case _TipoMetodo.pagoMovil:
        if (_telefonoController.text.trim().isEmpty || _bancoController.text.trim().isEmpty) {
          return 'Completa el telefono y el banco.';
        }
        return null;
      case _TipoMetodo.transferencia:
        if (_bancoController.text.trim().isEmpty || _numeroReferenciaController.text.trim().isEmpty) {
          return 'Completa el banco y el numero de referencia.';
        }
        return null;
      case _TipoMetodo.tarjeta:
        if (_numeroTarjetaController.text.trim().length < 12 ||
            _titularController.text.trim().isEmpty ||
            _vencimientoController.text.trim().isEmpty ||
            _cvvController.text.trim().length < 3) {
          return 'Completa todos los datos de la tarjeta.';
        }
        return null;
      case _TipoMetodo.otro:
      case null:
        return null;
    }
  }

  String _construirReferencia() {
    switch (_tipoSeleccionado) {
      case _TipoMetodo.pagoMovil:
        return 'Pago movil ${_telefonoController.text.trim()} - ${_bancoController.text.trim()}';
      case _TipoMetodo.transferencia:
        return 'Transferencia ${_bancoController.text.trim()} - Ref ${_numeroReferenciaController.text.trim()}';
      case _TipoMetodo.tarjeta:
        final numero = _numeroTarjetaController.text.trim();
        final ultimos4 = numero.length >= 4 ? numero.substring(numero.length - 4) : numero;
        return 'Tarjeta **** $ultimos4 - ${_titularController.text.trim()}';
      case _TipoMetodo.otro:
      case null:
        return '';
    }
  }

  Map<String, dynamic> _construirDetallePago() {
    switch (_tipoSeleccionado) {
      case _TipoMetodo.pagoMovil:
        return {
          'tipo': 'pago_movil',
          'telefono': _telefonoController.text.trim(),
          'banco': _bancoController.text.trim(),
        };
      case _TipoMetodo.transferencia:
        return {
          'tipo': 'transferencia',
          'banco': _bancoController.text.trim(),
          'referencia': _numeroReferenciaController.text.trim(),
        };
      case _TipoMetodo.tarjeta:
        final numero = _numeroTarjetaController.text.trim();
        final ultimos4 = numero.length >= 4 ? numero.substring(numero.length - 4) : numero;
        return {
          'tipo': 'tarjeta',
          'titular': _titularController.text.trim(),
          'ultimos4': ultimos4,
          'vencimiento': _vencimientoController.text.trim(),
        };
      case _TipoMetodo.otro:
      case null:
        return {'tipo': 'otro'};
    }
  }

  Future<void> _confirmarPago() async {
    if (_metodoSeleccionadoId == null) return;

    final errorCampos = _validarCamposMetodo();
    if (errorCampos != null) {
      setState(() => _error = errorCampos);
      return;
    }

    setState(() {
      _procesando = true;
      _pasoActual = 0;
      _error = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _pasoActual = 1);

      final data = await _supabase.rpc('procesar_pago', params: {
        'p_aeronave_id': widget.aeronave.id,
        'p_metodo_pago_id': _metodoSeleccionadoId,
        'p_referencia': _construirReferencia(),
        'p_detalle': _construirDetallePago(),
      });

      if (!mounted) return;
      setState(() => _pasoActual = 2);
      await Future.delayed(const Duration(milliseconds: 600));

      final comprobantes = (data as List)
          .map((e) => ComprobantePago.fromMap(e as Map<String, dynamic>))
          .toList();

      final metodoNombre = _metodos.firstWhere((m) => m.id == _metodoSeleccionadoId).nombre;

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

  Widget _buildCamposMetodo() {
    switch (_tipoSeleccionado) {
      case _TipoMetodo.pagoMovil:
        return _DatosPagoPanel(
          title: 'Datos del pago movil',
          icon: Icons.smartphone,
          children: [
            _buildTextField(
              controller: _telefonoController,
              label: 'Telefono',
              hint: 'Ej: 0412-1234567',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _bancoController,
              label: 'Banco emisor',
              hint: 'Ej: Banesco',
              icon: Icons.account_balance_outlined,
            ),
          ],
        );
      case _TipoMetodo.transferencia:
        return _DatosPagoPanel(
          title: 'Datos de la transferencia',
          icon: Icons.account_balance,
          children: [
            _buildTextField(
              controller: _bancoController,
              label: 'Banco origen',
              hint: 'Ej: Mercantil',
              icon: Icons.account_balance_outlined,
            ),
            _buildTextField(
              controller: _numeroReferenciaController,
              label: 'Numero de referencia',
              hint: 'Ej: 123456789',
              icon: Icons.numbers_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case _TipoMetodo.tarjeta:
        return _DatosPagoPanel(
          title: 'Datos de la tarjeta',
          icon: Icons.credit_card,
          children: [
            _buildTextField(
              controller: _numeroTarjetaController,
              label: 'Numero de tarjeta',
              hint: '1234 5678 9012 3456',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              controller: _titularController,
              label: 'Titular',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.characters,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _vencimientoController,
                    label: 'Vence',
                    hint: 'MM/AA',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
        );
      case _TipoMetodo.otro:
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_procesando,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildResumenPago() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flight, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.aeronave.matricula,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.liquidaciones.length} liquidacion${widget.liquidaciones.length == 1 ? '' : 'es'} pendiente${widget.liquidaciones.length == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 18),
          for (final l in widget.liquidaciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.tipoImpuestoNombre,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                  Text(
                    'Bs. ${l.monto.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          Divider(height: 24, color: Colors.white.withValues(alpha: 0.28)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a pagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              Text(
                'Bs. ${_total.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorMetodos() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final itemWidth = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metodo in _metodos)
              SizedBox(
                width: itemWidth,
                child: _MetodoPagoCard(
                  nombre: _nombreMetodo(metodo),
                  descripcion: _descripcionMetodo(_tipoMetodo(metodo.nombre)),
                  icono: _iconoMetodo(_tipoMetodo(metodo.nombre)),
                  seleccionado: metodo.id == _metodoSeleccionadoId,
                  onTap: _procesando
                      ? null
                      : () => setState(() {
                            _metodoSeleccionadoId = metodo.id;
                            _error = null;
                          }),
                ),
              ),
          ],
        );
      },
    );
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
                        _buildResumenPago(),
                        const SizedBox(height: 24),
                        Text(
                          'Metodo de pago',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildSelectorMetodos(),
                        const SizedBox(height: 18),
                        _buildCamposMetodo(),
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
                    label: Text(_procesando ? _pasosProcesamiento[_pasoActual] : 'Confirmar pago seguro'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MetodoPagoCard extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback? onTap;

  const _MetodoPagoCard({
    required this.nombre,
    required this.descripcion,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionado ? AppColors.primary : Colors.grey.shade300,
              width: seleccionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: seleccionado ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: seleccionado ? Colors.white : Colors.grey.shade700),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: seleccionado ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
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

class _DatosPagoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DatosPagoPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La referencia se guardara junto al comprobante en Supabase.',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
