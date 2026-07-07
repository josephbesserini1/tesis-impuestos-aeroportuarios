class Operacion {
  final String id;
  final String aeronaveId;
  final String matricula;
  final String tipoOperacion;
  final DateTime fechaOperacion;
  final String? pilotoResponsable;

  Operacion({
    required this.id,
    required this.aeronaveId,
    required this.matricula,
    required this.tipoOperacion,
    required this.fechaOperacion,
    this.pilotoResponsable,
  });

  factory Operacion.fromMap(Map<String, dynamic> map) {
    final aeronave = map['aeronaves'] as Map<String, dynamic>?;
    return Operacion(
      id: map['id'] as String,
      aeronaveId: map['aeronave_id'] as String,
      matricula: aeronave?['matricula'] as String? ?? '—',
      tipoOperacion: map['tipo_operacion'] as String,
      fechaOperacion: DateTime.parse(map['fecha_operacion'] as String),
      pilotoResponsable: map['piloto_responsable'] as String?,
    );
  }
}
