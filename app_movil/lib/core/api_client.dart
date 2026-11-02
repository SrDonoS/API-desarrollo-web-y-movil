import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Función que entrega el token actual (o null si no hay sesión).
typedef LectorToken = Future<String?> Function();

/// El ÚNICO lugar de la app que habla HTTP con la API.
///
/// - Agrega `Authorization: Bearer <token>` si hay sesión.
/// - Si la respuesta es 2xx devuelve el JSON ya decodificado.
/// - Si no, lanza [ApiException] con el formato del contrato.
/// - Si llega un 401 teniendo token, avisa con [alExpirarSesion] (la app vuelve al login).
class ApiClient {
  ApiClient({
    required this.leerToken,
    this.alExpirarSesion,
    http.Client? cliente,
    String? baseUrl,
  })  : _cliente = cliente ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final LectorToken leerToken;
  final void Function()? alExpirarSesion;
  final http.Client _cliente;

  Future<dynamic> get(String ruta, {Map<String, String?>? query}) =>
      _enviar('GET', ruta, query: query);

  Future<dynamic> post(String ruta, [Object? cuerpo]) => _enviar('POST', ruta, cuerpo: cuerpo);

  Future<dynamic> put(String ruta, Object cuerpo) => _enviar('PUT', ruta, cuerpo: cuerpo);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Map<String, String?>? query,
    Object? cuerpo,
  }) async {
    // Query string: se omiten los filtros vacíos
    final parametros = <String, String>{};
    query?.forEach((clave, valor) {
      if (valor != null && valor.isNotEmpty) parametros[clave] = valor;
    });
    var uri = Uri.parse('$baseUrl$ruta');
    if (parametros.isNotEmpty) uri = uri.replace(queryParameters: parametros);

    final token = await leerToken();
    final peticion = http.Request(metodo, uri);
    peticion.headers['Accept'] = 'application/json';
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json';
      peticion.body = jsonEncode(cuerpo);
    }

    final respuesta = await _hacer(peticion);
    final datos = _decodificar(respuesta);
    final status = respuesta.statusCode;
    if (status >= 200 && status < 300) return datos;

    final error = ApiException.desdeRespuesta(status, datos);
    if (status == 401 && token != null) alExpirarSesion?.call();
    throw error;
  }

  /// Envía la petición. Cualquier problema de red se convierte en "sin conexión".
  Future<http.Response> _hacer(http.Request peticion) async {
    try {
      final enviada = await _cliente.send(peticion).timeout(ApiConfig.timeout);
      return await http.Response.fromStream(enviada);
    } on TimeoutException {
      throw ApiException.sinConexion();
    } on SocketException {
      throw ApiException.sinConexion();
    } on http.ClientException {
      throw ApiException.sinConexion();
    }
  }

  /// UTF-8 siempre (si no, "Pérez" llega como "PÃ©rez"). Un cuerpo vacío (204) es null.
  Object? _decodificar(http.Response respuesta) {
    if (respuesta.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(respuesta.bodyBytes));
    } on FormatException {
      return null; // p. ej. una página HTML de error de Nginx (502)
    }
  }
}
