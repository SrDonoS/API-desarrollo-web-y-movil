import 'multa.dart';

class Prestamo {
  const Prestamo({
    required this.id,
    required this.socioId,
    required this.socioNombre,
    required this.socioRut,
    required this.copiaId,
    required this.codigoInventario,
    required this.libroId,
    required this.libroTitulo,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    required this.estado,
    required this.atrasado,
    required this.diasAtraso,
    this.fechaDevolucion,
    this.multa,
  });

  final int id;
  final int socioId;
  final String socioNombre;
  final String socioRut;
  final int copiaId;
  final String codigoInventario;
  final int libroId;
  final String libroTitulo;
  final DateTime fechaPrestamo;
  final DateTime fechaVencimiento;
  final DateTime? fechaDevolucion;

  /// "activo" o "devuelto"
  final String estado;

  /// ¿Está atrasado AHORA? (solo puede serlo si sigue activo)
  final bool atrasado;
  final int diasAtraso;

  /// null si no hubo atraso al devolver.
  final Multa? multa;

  bool get activo => estado == 'activo';

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    final socio = json['socio'] as Map<String, dynamic>;
    final copia = json['copia'] as Map<String, dynamic>;
    final libro = json['libro'] as Map<String, dynamic>;
    final multa = json['multa'];
    return Prestamo(
      id: json['id'] as int,
      socioId: socio['id'] as int,
      socioNombre: socio['nombre'] as String,
      socioRut: socio['rut'] as String,
      copiaId: copia['id'] as int,
      codigoInventario: copia['codigo_inventario'] as String,
      libroId: libro['id'] as int,
      libroTitulo: libro['titulo'] as String,
      fechaPrestamo: DateTime.parse(json['fecha_prestamo'] as String),
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento'] as String),
      fechaDevolucion: json['fecha_devolucion'] == null
          ? null
          : DateTime.parse(json['fecha_devolucion'] as String),
      estado: json['estado'] as String,
      atrasado: json['atrasado'] as bool? ?? false,
      diasAtraso: json['dias_atraso'] as int? ?? 0,
      multa: multa == null ? null : Multa.fromJson(multa as Map<String, dynamic>),
    );
  }
}
