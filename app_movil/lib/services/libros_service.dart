import '../core/api_client.dart';
import '../models/copia.dart';
import '../models/libro.dart';
import '../models/pagina.dart';

/// E04 a E09
class LibrosService {
  LibrosService(this._api);
  final ApiClient _api;

  /// E04 · Catálogo con búsqueda, filtros y paginación (máx. 50 por página).
  Future<Pagina<Libro>> listar({
    String? buscar,
    int? categoriaId,
    bool? disponible,
    int pagina = 1,
    int tam = 20,
  }) async {
    final datos = await _api.get('/api/libros', query: {
      'buscar': buscar,
      'categoria': categoriaId?.toString(),
      'disponible': disponible?.toString(),
      'pagina': '$pagina',
      'tam': '$tam',
    });
    return Pagina.fromJson(datos as Map<String, dynamic>, Libro.fromJson);
  }

  /// E05 · Detalle con sus copias.
  Future<Libro> detalle(int id) async {
    final datos = await _api.get('/api/libros/$id');
    return Libro.fromJson(datos as Map<String, dynamic>);
  }

  /// E06 · Crear (bibliotecario).
  Future<Libro> crear(LibroEntrada libro) async {
    final datos = await _api.post('/api/libros', libro.toJson());
    return Libro.fromJson(datos as Map<String, dynamic>);
  }

  /// E07 · Reemplazar TODO el libro (bibliotecario).
  Future<Libro> reemplazar(int id, LibroEntrada libro) async {
    final datos = await _api.put('/api/libros/$id', libro.toJson());
    return Libro.fromJson(datos as Map<String, dynamic>);
  }

  /// E08 · Eliminar (bibliotecario). 409 si alguna copia tiene préstamos.
  Future<void> eliminar(int id) async {
    await _api.delete('/api/libros/$id');
  }

  /// E09 · Agregar una copia física (bibliotecario).
  Future<Copia> agregarCopia(int libroId, String codigoInventario) async {
    final datos = await _api.post(
      '/api/libros/$libroId/copias',
      {'codigo_inventario': codigoInventario},
    );
    return Copia.fromJson(datos as Map<String, dynamic>);
  }
}
