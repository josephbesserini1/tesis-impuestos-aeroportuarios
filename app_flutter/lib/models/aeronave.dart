class Aeronave {
  final String id;
  final String matricula;
  final String? tipoAeronave;
  final String? modelo;
  final String? hangarAsignado;
  final String? propietarioNombre;

  Aeronave({
    required this.id,
    required this.matricula,
    this.tipoAeronave,
    this.modelo,
    this.hangarAsignado,
    this.propietarioNombre,
  });

  factory Aeronave.fromMap(Map<String, dynamic> map) {
    final propietario = map['propietarios'] as Map<String, dynamic>?;
    return Aeronave(
      id: map['id'] as String,
      matricula: map['matricula'] as String,
      tipoAeronave: map['tipo_aeronave'] as String?,
      modelo: map['modelo'] as String?,
      hangarAsignado: map['hangar_asignado'] as String?,
      propietarioNombre: propietario?['nombre'] as String?,
    );
  }
}
