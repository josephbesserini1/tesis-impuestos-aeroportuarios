class Propietario {
  final String id;
  final String nombre;
  final String cedulaRif;
  final String? telefono;
  final String? email;

  Propietario({
    required this.id,
    required this.nombre,
    required this.cedulaRif,
    this.telefono,
    this.email,
  });

  factory Propietario.fromMap(Map<String, dynamic> map) {
    return Propietario(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      cedulaRif: map['cedula_rif'] as String,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
    );
  }
}
