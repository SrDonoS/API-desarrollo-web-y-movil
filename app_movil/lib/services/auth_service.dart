import '../core/api_client.dart';
import '../models/usuario.dart';

class RespuestaLogin {
  const RespuestaLogin({required this.token, required this.usuario});
  final String token;
  final Usuario usuario;
}

/// E01, E02, E03
class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  /// E01 · Crea una cuenta de SOCIO (el rol no se envía nunca).
  Future<Usuario> registrar({
    required String nombre,
    required String rut,
    required String email,
    required String clave,
  }) async {
    final datos = await _api.post('/api/auth/registro', {
      'nombre': nombre,
      'rut': rut,
      'email': email,
      'clave': clave,
    });
    return Usuario.fromJson(datos as Map<String, dynamic>);
  }

  /// E02 · Login: devuelve el token y el usuario.
  Future<RespuestaLogin> login({required String email, required String clave}) async {
    final datos = await _api.post('/api/auth/login', {'email': email, 'clave': clave})
        as Map<String, dynamic>;
    return RespuestaLogin(
      token: datos['access_token'] as String,
      usuario: Usuario.fromJson(datos['usuario'] as Map<String, dynamic>),
    );
  }

  /// E03 · ¿Quién soy? (se llama al abrir la app)
  Future<Usuario> yo() async {
    final datos = await _api.get('/api/auth/yo');
    return Usuario.fromJson(datos as Map<String, dynamic>);
  }
}
