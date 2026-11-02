import 'package:biblioteca_app/models/prestamo.dart';
import 'package:biblioteca_app/widgets/estado_chip.dart';
import 'package:biblioteca_app/widgets/prestamo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La tarjeta de préstamo muestra la multa pendiente', (tester) async {
    final prestamo = Prestamo.fromJson({
      'id': 40,
      'socio': {'id': 7, 'nombre': 'Ana Rojas Pérez', 'rut': '12345678-5'},
      'copia': {'id': 32, 'codigo_inventario': 'LIB-000032'},
      'libro': {'id': 12, 'titulo': 'Cien años de soledad'},
      'fecha_prestamo': '2026-09-20T11:00:00',
      'fecha_vencimiento': '2026-10-04',
      'fecha_devolucion': '2026-10-07T16:20:00',
      'estado': 'devuelto',
      'atrasado': false,
      'dias_atraso': 3,
      'multa': {'id': 9, 'monto': 1500, 'dias_atraso': 3, 'estado': 'pendiente'},
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: PrestamoTile(prestamo: prestamo))),
    ));

    expect(find.text('Cien años de soledad'), findsOneWidget);
    expect(find.text('Devuelto'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.textContaining(r'$1.500'), findsOneWidget);
  });

  testWidgets('EstadoChip muestra su texto', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EstadoChip(texto: 'Disponible', tipo: TipoEstado.bueno)),
    ));
    expect(find.text('Disponible'), findsOneWidget);
  });
}
