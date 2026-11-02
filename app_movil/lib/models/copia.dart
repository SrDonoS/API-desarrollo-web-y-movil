class Copia {
  const Copia({
    required this.id,
    required this.codigoInventario,
    required this.estado,
    this.libroId,
    this.fechaIngreso,
  });

  final int id;

  /// La etiqueta física. Ej: LIB-000031
  final String codigoInventario;

  /// "disponible" o "prestada"
  final String estado;

  /// Solo vienen en la respuesta de E09.
  final int? libroId;
  final DateTime? fechaIngreso;

  bool get disponible => estado == 'disponible';

  factory Copia.fromJson(Map<String, dynamic> json) => Copia(
        id: json['id'] as int,
        codigoInventario: json['codigo_inventario'] as String,
        estado: (json['estado'] as String?) ?? 'disponible',
        libroId: json['libro_id'] as int?,
        fechaIngreso: json['fecha_ingreso'] == null
            ? null
            : DateTime.parse(json['fecha_ingreso'] as String),
      );
}
