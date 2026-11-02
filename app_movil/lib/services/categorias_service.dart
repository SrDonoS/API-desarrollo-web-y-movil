import '../core/api_client.dart';
import '../models/categoria.dart';

/// E10, E11
class CategoriasService {
  CategoriasService(this._api);
  final ApiClient _api;

  Future<List<Categoria>> listar() async {
    final datos = await _api.get('/api/categorias') as List<dynamic>;
    return datos.map((c) => Categoria.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Categoria> crear(String nombre) async {
    final datos = await _api.post('/api/categorias', {'nombre': nombre});
    return Categoria.fromJson(datos as Map<String, dynamic>);
  }
}
