import '../core/api_client.dart';
import '../models/multa.dart';
import '../models/pagina.dart';
import '../models/prestamo.dart';

/// E12 a E16
class PrestamosService {
  PrestamosService(this._api);
  final ApiClient _api;

  /// E12 · Registrar préstamo (bibliotecario). 409: LIMITE_PRESTAMOS / COPIA_NO_DISPONIBLE.
  Future<Prestamo> prestar({required int socioId, required int copiaId}) async {
    final datos = await _api.post('/api/prestamos', {'socio_id': socioId, 'copia_id': copiaId});
    return Prestamo.fromJson(datos as Map<String, dynamic>);
  }

  /// E13 · Préstamos de todos (bibliotecario).
  Future<Pagina<Prestamo>> listar({
    int? socioId,
    String? estado,
    bool? atrasado,
    String? multa,
    int pagina = 1,
    int tam = 20,
  }) async {
    final datos = await _api.get('/api/prestamos', query: {
      'socio_id': socioId?.toString(),
      'estado': estado,
      'atrasado': atrasado?.toString(),
      'multa': multa,
      'pagina': '$pagina',
      'tam': '$tam',
    });
    return Pagina.fromJson(datos as Map<String, dynamic>, Prestamo.fromJson);
  }

  /// E14 · Registrar devolución (bibliotecario). Si hubo atraso, viene la multa.
  Future<Prestamo> devolver(int prestamoId) async {
    final datos = await _api.post('/api/prestamos/$prestamoId/devolucion');
    return Prestamo.fromJson(datos as Map<String, dynamic>);
  }

  /// E15 · MIS préstamos: el servidor saca el socio del token. No se envía ningún id.
  Future<List<Prestamo>> misPrestamos({String? estado}) async {
    final datos = await _api.get('/api/mis-prestamos', query: {'estado': estado})
        as Map<String, dynamic>;
    return (datos['items'] as List<dynamic>)
        .map((p) => Prestamo.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// E16 · Registrar pago de multa (bibliotecario).
  Future<Multa> pagarMulta(int multaId) async {
    final datos = await _api.post('/api/multas/$multaId/pago');
    return Multa.fromJson(datos as Map<String, dynamic>);
  }
}
