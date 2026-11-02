/// Un error de la API, con el formato del contrato:
///   {"error": "...", "codigo": 409, "motivo": "LIMITE_PRESTAMOS"}
///   {"error": "...", "codigo": 400, "detalles": {"isbn": ["..."]}}
class ApiException implements Exception {
  const ApiException({
    required this.codigo,
    required this.mensaje,
    this.motivo,
    this.detalles = const {},
  });

  /// Código HTTP. 0 = no hubo respuesta (sin conexión).
  final int codigo;
  final String mensaje;

  /// Solo en los 409: LIMITE_PRESTAMOS, COPIA_NO_DISPONIBLE, ISBN_DUPLICADO...
  final String? motivo;

  /// Solo en los 400: campo -> problemas.
  final Map<String, List<String>> detalles;

  factory ApiException.desdeRespuesta(int status, Object? cuerpo) {
    if (cuerpo is Map<String, dynamic>) {
      final detalles = <String, List<String>>{};
      final crudo = cuerpo['detalles'];
      if (crudo is Map) {
        crudo.forEach((campo, problemas) {
          if (problemas is List) {
            detalles[campo.toString()] = problemas.map((p) => p.toString()).toList();
          } else {
            detalles[campo.toString()] = [problemas.toString()];
          }
        });
      }
      final motivo = cuerpo['motivo'];
      return ApiException(
        codigo: status,
        mensaje: (cuerpo['error'] ?? 'Error $status').toString(),
        motivo: motivo is String ? motivo : null,
        detalles: detalles,
      );
    }
    return ApiException(codigo: status, mensaje: 'Error $status del servidor');
  }

  factory ApiException.sinConexion() => const ApiException(
        codigo: 0,
        mensaje: 'No se pudo conectar con la API. ¿Está corriendo y la URL es la correcta?',
      );

  /// El primer problema de un campo del formulario (para mostrarlo debajo del campo).
  String? errorDe(String campo) {
    final lista = detalles[campo];
    if (lista == null || lista.isEmpty) return null;
    return lista.join(' ');
  }

  @override
  String toString() => mensaje;
}
