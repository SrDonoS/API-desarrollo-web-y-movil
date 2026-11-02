// Prueba que los modelos leen bien el JSON del CONTRATO (hoja 5-Payloads).
// Se corre con:  flutter test
import 'dart:convert';

import 'package:biblioteca_app/core/api_exception.dart';
import 'package:biblioteca_app/models/libro.dart';
import 'package:biblioteca_app/models/pagina.dart';
import 'package:biblioteca_app/models/prestamo.dart';
import 'package:biblioteca_app/models/usuario.dart';
import 'package:biblioteca_app/utils/formatos.dart';
import 'package:biblioteca_app/utils/mensajes.dart';
import 'package:biblioteca_app/utils/validaciones.dart' as v;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String texto) => jsonDecode(texto) as Map<String, dynamic>;

void main() {
  test('Usuario (E01/E03)', () {
    final u = Usuario.fromJson(_json('''
      {"id": 7, "nombre": "Ana Rojas Pérez", "rut": "12345678-5", "email": "ana.rojas@correo.cl",
       "rol": "socio", "activo": true, "creado": "2026-10-13T09:15:00"}'''));
    expect(u.id, 7);
    expect(u.esBibliotecario, isFalse);
    expect(u.creado, DateTime(2026, 10, 13, 9, 15));
  });

  test('Libro con copias (E05)', () {
    final l = Libro.fromJson(_json('''
      {"id": 12, "titulo": "Cien años de soledad", "autor": "Gabriel García Márquez",
       "isbn": "9780307474728", "anio_publicacion": 1967,
       "categoria": {"id": 2, "nombre": "Novela"},
       "copias_total": 2, "copias_disponibles": 1, "disponible": true,
       "copias": [{"id": 31, "codigo_inventario": "LIB-000031", "estado": "disponible"},
                  {"id": 32, "codigo_inventario": "LIB-000032", "estado": "prestada"}]}'''));
    expect(l.categoria.nombre, 'Novela');
    expect(l.copias.length, 2);
    expect(l.copias.first.disponible, isTrue);
    expect(l.copias.last.disponible, isFalse);
  });

  test('Página de libros (E04) y libro sin año', () {
    final p = Pagina.fromJson(_json('''
      {"total": 3, "pagina": 1, "tam": 2, "paginas": 2,
       "items": [{"id": 1, "titulo": "A", "autor": "Autor", "isbn": "123456789X",
                  "anio_publicacion": null, "categoria": {"id": 1, "nombre": "X"},
                  "copias_total": 0, "copias_disponibles": 0, "disponible": false}]}'''),
        Libro.fromJson);
    expect(p.hayMas, isTrue);
    expect(p.items.single.anioPublicacion, isNull);
  });

  test('Préstamo devuelto con multa (E14)', () {
    final p = Prestamo.fromJson(_json('''
      {"id": 40, "socio": {"id": 7, "nombre": "Ana Rojas Pérez", "rut": "12345678-5"},
       "copia": {"id": 32, "codigo_inventario": "LIB-000032"},
       "libro": {"id": 12, "titulo": "Cien años de soledad"},
       "fecha_prestamo": "2026-09-20T11:00:00", "fecha_vencimiento": "2026-10-04",
       "fecha_devolucion": "2026-10-07T16:20:00", "estado": "devuelto",
       "atrasado": false, "dias_atraso": 3,
       "multa": {"id": 9, "monto": 1500, "dias_atraso": 3, "estado": "pendiente"}}'''));
    expect(p.activo, isFalse);
    expect(p.multa!.monto, 1500);
    expect(p.multa!.pendiente, isTrue);
    expect(p.fechaVencimiento, DateTime(2026, 10, 4));
  });

  test('Error 409 con motivo y 400 con detalles', () {
    final e409 = ApiException.desdeRespuesta(409, _json(
        '{"error": "El socio ya tiene 3 préstamos activos", "codigo": 409, "motivo": "LIMITE_PRESTAMOS"}'));
    expect(e409.motivo, 'LIMITE_PRESTAMOS');
    expect(mensajeAmigable(e409), contains('3 libros'));

    final e400 = ApiException.desdeRespuesta(400, _json(
        '{"error": "Datos inválidos en: isbn", "codigo": 400, "detalles": {"isbn": ["10 o 13 dígitos"]}}'));
    expect(e400.errorDe('isbn'), '10 o 13 dígitos');
    expect(e400.errorDe('titulo'), isNull);
  });

  test('Formatos chilenos', () {
    expect(pesos(1500), r'$1.500');
    expect(pesos(500), r'$500');
    expect(pesos(1234567), r'$1.234.567');
    expect(fecha(DateTime(2026, 10, 4)), '04-10-2026');
  });

  test('Validaciones de la hoja 3-Entradas', () {
    expect(v.rut('12345678-5'), isNull);
    expect(v.rut('12.345.678-5'), isNotNull);
    expect(v.isbn('9780307474728'), isNull);
    expect(v.isbn('978-0307'), isNotNull);
    expect(v.codigoInventario('LIB-000031'), isNull);
    expect(v.codigoInventario('lib-1'), isNotNull);
    expect(v.anio(''), isNull);
    expect(v.anio('1200'), isNotNull);
  });
}
