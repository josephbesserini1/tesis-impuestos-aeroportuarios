class MetodoPago {
  final String id;
  final String nombre;

  MetodoPago({required this.id, required this.nombre});

  factory MetodoPago.fromMap(Map<String, dynamic> map) {
    return MetodoPago(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
    );
  }
}
