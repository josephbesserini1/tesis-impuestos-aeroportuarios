class ComprobantePago {
  final String comprobanteId;
  final String numeroComprobante;
  final String liquidacionId;
  final double monto;

  ComprobantePago({
    required this.comprobanteId,
    required this.numeroComprobante,
    required this.liquidacionId,
    required this.monto,
  });

  factory ComprobantePago.fromMap(Map<String, dynamic> map) {
    return ComprobantePago(
      comprobanteId: map['comprobante_id'] as String,
      numeroComprobante: map['numero_comprobante'] as String,
      liquidacionId: map['liquidacion_id'] as String,
      monto: (map['monto'] as num).toDouble(),
    );
  }
}
