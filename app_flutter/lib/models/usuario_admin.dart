class UsuarioAdmin {
  final String id;
  final String nombre;
  final String rol;

  UsuarioAdmin({required this.id, required this.nombre, required this.rol});

  factory UsuarioAdmin.fromMap(Map<String, dynamic> map) {
    return UsuarioAdmin(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      rol: map['rol'] as String,
    );
  }
}
