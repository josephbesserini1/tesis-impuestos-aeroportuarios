class TipoImpuesto {
  final String id;
  final String nombre;
  final double montoBase;

  TipoImpuesto({required this.id, required this.nombre, required this.montoBase});

  factory TipoImpuesto.fromMap(Map<String, dynamic> map) {
    return TipoImpuesto(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      montoBase: (map['monto_base'] as num).toDouble(),
    );
  }
}
