/// Dónde está la API. NUNCA se escribe a mano en el código: se pasa al compilar.
///
///   flutter run                                              -> emulador (10.0.2.2)
///   flutter run --dart-define=API_URL=http://192.168.1.50:5000  -> celular en tu wifi
///   flutter build apk --dart-define=API_URL=https://api.tudominio.cl  -> AWS
class ApiConfig {
  ApiConfig._();

  /// 10.0.2.2 es "tu compu" vista desde el emulador de Android (localhost sería el emulador).
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const Duration timeout = Duration(seconds: 15);

  /// Regla del contrato (la valida el servidor; aquí solo se muestra).
  static const int maxPrestamosActivos = 3;
}
