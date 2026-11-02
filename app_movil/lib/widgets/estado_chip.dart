import 'package:flutter/material.dart';

/// Etiqueta de color para estados: disponible, prestada, activo, atrasado, devuelto...
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.texto, required this.tipo});

  final String texto;
  final TipoEstado tipo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final (fondo, letra) = switch (tipo) {
      TipoEstado.bueno => (const Color(0xFFE4F0E9), const Color(0xFF1B5E20)),
      TipoEstado.alerta => (const Color(0xFFFFF4CE), const Color(0xFF7A5B00)),
      TipoEstado.malo => (esquema.errorContainer, esquema.onErrorContainer),
      TipoEstado.neutro => (const Color(0xFFE9EEF9), const Color(0xFF3B486B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(
        texto,
        style: TextStyle(color: letra, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

enum TipoEstado { bueno, alerta, malo, neutro }
