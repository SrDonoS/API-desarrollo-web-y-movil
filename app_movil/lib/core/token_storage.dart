import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token JWT CIFRADO en el teléfono (nunca en texto plano).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _clave = 'access_token';
  final FlutterSecureStorage _storage;

  Future<String?> leer() => _storage.read(key: _clave);

  Future<void> guardar(String token) => _storage.write(key: _clave, value: token);

  Future<void> borrar() => _storage.delete(key: _clave);
}
