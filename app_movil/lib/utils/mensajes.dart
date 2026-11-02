import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../core/api_exception.dart';

/// Traduce un error de la API a algo que entienda una persona.
/// Los 409 se distinguen por su `motivo` (contrato, hoja 4-Salidas).
String mensajeAmigable(Object error) {
  if (error is! ApiException) return 'Ocurrió un error inesperado.';
  switch (error.motivo) {
    case 'LIMITE_PRESTAMOS':
      return 'Este socio ya tiene ${ApiConfig.maxPrestamosActivos} libros prestados. '
          'Tiene que devolver uno antes.';
    case 'COPIA_NO_DISPONIBLE':
      return 'Esa copia ya está prestada. Elige otra.';
    case 'USUARIO_DUPLICADO':
      return 'Ese RUT o correo ya tiene una cuenta.';
    case 'ISBN_DUPLICADO':
      return 'Ya hay otro libro con ese ISBN.';
    case 'LIBRO_CON_PRESTAMOS':
      return 'No se puede borrar: el libro ya se ha prestado (hay que cuidar el historial).';
    case 'CODIGO_DUPLICADO':
      return 'Ya existe una copia con ese código de inventario.';
    case 'CATEGORIA_DUPLICADA':
      return 'Esa categoría ya existe.';
    case 'PRESTAMO_YA_DEVUELTO':
      return 'Ese préstamo ya estaba devuelto.';
    case 'MULTA_YA_PAGADA':
      return 'Esa multa ya estaba pagada.';
  }
  switch (error.codigo) {
    case 403:
      return 'No tienes permiso para hacer esto.';
    case 404:
      return 'No se encontró (puede que alguien lo haya borrado).';
    default:
      return error.mensaje;
  }
}

/// Muestra el error abajo en un SnackBar.
/// Un 401 no se muestra: la sesión ya se encarga de mandar al login.
void mostrarError(BuildContext context, Object error) {
  if (error is ApiException && error.codigo == 401) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(mensajeAmigable(error))));
}

void mostrarExito(BuildContext context, String texto) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(texto)));
}
