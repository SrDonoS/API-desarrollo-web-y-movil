import 'package:flutter/material.dart';

import '../utils/mensajes.dart';

/// Pantalla de error con botón "Reintentar".
class VistaError extends StatelessWidget {
  const VistaError({super.key, required this.error, required this.alReintentar});

  final Object error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 12),
            Text(mensajeAmigable(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje centrado para listas vacías.
class VistaVacia extends StatelessWidget {
  const VistaVacia({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // ListView (y no Column) para que funcione el "tirar para refrescar"
      children: [
        const SizedBox(height: 120),
        Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(texto, textAlign: TextAlign.center),
      ],
    );
  }
}
