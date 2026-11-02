class Multa {
  const Multa({
    required this.id,
    required this.monto,
    required this.diasAtraso,
    required this.estado,
    this.prestamoId,
    this.fechaPago,
  });

  final int id;

  /// En pesos, sin decimales.
  final int monto;
  final int diasAtraso;

  /// "pendiente" o "pagada"
  final String estado;

  /// Solo vienen en la respuesta del pago (E16).
  final int? prestamoId;
  final DateTime? fechaPago;

  bool get pendiente => estado == 'pendiente';

  factory Multa.fromJson(Map<String, dynamic> json) => Multa(
        id: json['id'] as int,
        monto: json['monto'] as int,
        diasAtraso: json['dias_atraso'] as int,
        estado: json['estado'] as String,
        prestamoId: json['prestamo_id'] as int?,
        fechaPago:
            json['fecha_pago'] == null ? null : DateTime.parse(json['fecha_pago'] as String),
      );
}
