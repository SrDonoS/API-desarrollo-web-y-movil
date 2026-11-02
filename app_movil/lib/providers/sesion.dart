import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/categorias_service.dart';
import '../services/libros_service.dart';
import '../services/prestamos_service.dart';

enum EstadoSesion { cargando, sinConexion, sinSesion, conSesion }

/// Quién está conectado, y los servicios para hablar con la API.
///
/// Toda la app la lee con `context.watch<Sesion>()` / `context.read<Sesion>()`.
class Sesion extends ChangeNotifier {
  Sesion({TokenStorage? storage, this.alTerminar}) : _storage = storage ?? TokenStorage() {
    api = ApiClient(leerToken: () async => _token, alExpirarSesion: _expirar);
    auth = AuthService(api);
    libros = LibrosService(api);
    categorias = CategoriasService(api);
    prestamos = PrestamosService(api);
  }

  final TokenStorage _storage;

  /// Se llama cuando la sesión termina (para cerrar las pantallas abiertas).
  final VoidCallback? alTerminar;

  late final ApiClient api;
  late final AuthService auth;
  late final LibrosService libros;
  late final CategoriasService categorias;
  late final PrestamosService prestamos;

  String? _token;
  Usuario? _usuario;
  EstadoSesion _estado = EstadoSesion.cargando;
  String? _aviso;

  EstadoSesion get estado => _estado;
  Usuario? get usuario => _usuario;
  bool get esBibliotecario => _usuario?.esBibliotecario ?? false;

  /// Mensaje para mostrar en el login (ej. "tu sesión expiró"). Se lee una vez.
  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  /// Al abrir la app: si hay token guardado, se pregunta "¿quién soy?" (E03).
  Future<void> iniciar() async {
    _estado = EstadoSesion.cargando;
    notifyListeners();

    _token = await _storage.leer();
    if (_token == null) {
      _estado = EstadoSesion.sinSesion;
      notifyListeners();
      return;
    }
    try {
      _usuario = await auth.yo();
      _estado = EstadoSesion.conSesion;
    } on ApiException catch (e) {
      if (e.codigo == 0) {
        _estado = EstadoSesion.sinConexion; // se puede reintentar
      } else {
        await _limpiar(); // token vencido o inválido -> al login
        _estado = EstadoSesion.sinSesion;
      }
    }
    notifyListeners();
  }

  /// E02. Lanza [ApiException] si falla (la pantalla de login lo muestra).
  Future<void> iniciarSesion(String email, String clave) async {
    final respuesta = await auth.login(email: email, clave: clave);
    _token = respuesta.token;
    _usuario = respuesta.usuario;
    await _storage.guardar(respuesta.token);
    _estado = EstadoSesion.conSesion;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _limpiar();
    _estado = EstadoSesion.sinSesion;
    alTerminar?.call();
    notifyListeners();
  }

  /// La API respondió 401 teniendo token: venció (dura 1 hora) o la cuenta se desactivó.
  void _expirar() {
    if (_estado != EstadoSesion.conSesion) return;
    _aviso = 'Tu sesión expiró. Vuelve a iniciar sesión.';
    _token = null;
    _usuario = null;
    _storage.borrar();
    _estado = EstadoSesion.sinSesion;
    alTerminar?.call();
    notifyListeners();
  }

  Future<void> _limpiar() async {
    _token = null;
    _usuario = null;
    await _storage.borrar();
  }
}
