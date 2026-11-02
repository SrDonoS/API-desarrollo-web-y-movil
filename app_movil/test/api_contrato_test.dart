// OPCIONAL: prueba la app contra tu API corriendo de verdad (con datos de `flask init-db`).
//
//   1. En backend/:  flask --app run init-db   y   python run.py
//   2. Aquí:         flutter test test/api_contrato_test.dart --dart-define=API_URL=http://127.0.0.1:5000
//
// Sin --dart-define=API_URL se salta sola.
import 'package:biblioteca_app/core/api_client.dart';
import 'package:biblioteca_app/core/api_exception.dart';
import 'package:biblioteca_app/services/auth_service.dart';
import 'package:biblioteca_app/services/libros_service.dart';
import 'package:biblioteca_app/services/prestamos_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = String.fromEnvironment('API_URL');

void main() {
  final saltar = _url.isEmpty ? 'Define --dart-define=API_URL=http://127.0.0.1:5000' : false;

  test('login, catálogo y mis préstamos contra la API real', () async {
    String? token;
    final api = ApiClient(baseUrl: _url, leerToken: () async => token);
    final auth = AuthService(api);

    // 401 con el MISMO mensaje para correo inexistente o clave mala
    try {
      await auth.login(email: 'noexiste@correo.cl', clave: 'mala-clave');
      fail('Debía responder 401');
    } on ApiException catch (e) {
      expect(e.codigo, 401);
    }

    final login = await auth.login(email: 'ana.rojas@correo.cl', clave: 'clave-segura-123');
    token = login.token;
    expect(login.usuario.rol, 'socio');

    final pagina = await LibrosService(api).listar(tam: 5);
    expect(pagina.items, isNotEmpty);

    final mios = await PrestamosService(api).misPrestamos();
    expect(mios.every((p) => p.socioId == login.usuario.id), isTrue);

    // Un socio NO puede ver los préstamos de todos -> 403 (no 401)
    try {
      await PrestamosService(api).listar();
      fail('Debía responder 403');
    } on ApiException catch (e) {
      expect(e.codigo, 403);
    }
  }, skip: saltar);
}
