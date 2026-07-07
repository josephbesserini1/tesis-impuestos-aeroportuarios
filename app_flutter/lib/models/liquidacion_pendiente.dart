class LiquidacionPendiente {
  final String id;
  final double monto;
  final DateTime fechaLiquidacion;
  final String tipoImpuestoNombre;
  final String? tipoImpuestoDescripcion;

  LiquidacionPendiente({
    required this.id,
    required this.monto,
    required this.fechaLiquidacion,
    required this.tipoImpuestoNombre,
    this.tipoImpuestoDescripcion,
  });

  factory LiquidacionPendiente.fromMap(Map<String, dynamic> map) {
    final tipoImpuesto = map['tipos_impuesto'] as Map<String, dynamic>?;
    return LiquidacionPendiente(
      id: map['id'] as String,
      monto: (map['monto'] as num).toDouble(),
      fechaLiquidacion: DateTime.parse(map['fecha_liquidacion'] as String),
      tipoImpuestoNombre: tipoImpuesto?['nombre'] as String? ?? 'Impuesto',
      tipoImpuestoDescripcion: tipoImpuesto?['descripcion'] as String?,
    );
  }
}
