import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pregunta "¿seguro?" y devuelve true si la persona confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String accion = 'Sí, dale',
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(accion)),
      ],
    ),
  );
  return respuesta ?? false;
}

/// Pide un texto en un diálogo (ej. número de socio, código de inventario).
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  String? ayuda,
  String accion = 'Aceptar',
  TextInputType teclado = TextInputType.text,
  List<TextInputFormatter> formateadores = const [],
  String? Function(String?)? validar,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoTexto(
      titulo: titulo,
      etiqueta: etiqueta,
      ayuda: ayuda,
      accion: accion,
      teclado: teclado,
      formateadores: formateadores,
      validar: validar,
    ),
  );
}

class _DialogoTexto extends StatefulWidget {
  const _DialogoTexto({
    required this.titulo,
    required this.etiqueta,
    required this.accion,
    required this.teclado,
    required this.formateadores,
    this.ayuda,
    this.validar,
  });

  final String titulo;
  final String etiqueta;
  final String? ayuda;
  final String accion;
  final TextInputType teclado;
  final List<TextInputFormatter> formateadores;
  final String? Function(String?)? validar;

  @override
  State<_DialogoTexto> createState() => _DialogoTextoState();
}

class _DialogoTextoState extends State<_DialogoTexto> {
  final _form = GlobalKey<FormState>();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (_form.currentState!.validate()) Navigator.of(context).pop(_texto.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _texto,
          autofocus: true,
          keyboardType: widget.teclado,
          inputFormatters: widget.formateadores,
          decoration: InputDecoration(labelText: widget.etiqueta, helperText: widget.ayuda),
          validator: widget.validar,
          onFieldSubmitted: (_) => _aceptar(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: Text(widget.accion)),
      ],
    );
  }
}

/// Convierte a MAYÚSCULAS mientras se escribe (para los códigos de inventario).
class MayusculasFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
