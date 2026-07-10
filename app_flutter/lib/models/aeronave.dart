class Aeronave {
  final String id;
  final String matricula;
  final String? tipoAeronave;
  final String? modelo;
  final String? fabricante;
  final int? capacidad;
  final String? estado;
  final String? hangarAsignado;
  final String? aeropuertoNombre;
  final String? aeropuertoCodigo;
  final String? propietarioNombre;

  Aeronave({
    required this.id,
    required this.matricula,
    this.tipoAeronave,
    this.modelo,
    this.fabricante,
    this.capacidad,
    this.estado,
    this.hangarAsignado,
    this.aeropuertoNombre,
    this.aeropuertoCodigo,
    this.propietarioNombre,
  });

  factory Aeronave.fromMap(Map<String, dynamic> map) {
    final propietario = map['propietarios'] as Map<String, dynamic>?;
    final aeropuerto = map['aeropuertos'] as Map<String, dynamic>?;
    return Aeronave(
      id: map['id'] as String,
      matricula: map['matricula'] as String,
      tipoAeronave: map['tipo_aeronave'] as String?,
      modelo: map['modelo'] as String?,
      fabricante: map['fabricante'] as String?,
      capacidad: map['capacidad'] as int?,
      estado: map['estado'] as String?,
      hangarAsignado: map['hangar_asignado'] as String?,
      aeropuertoNombre: aeropuerto?['nombre'] as String?,
      aeropuertoCodigo: aeropuerto?['codigo'] as String?,
      propietarioNombre: propietario?['nombre'] as String?,
    );
  }
}
