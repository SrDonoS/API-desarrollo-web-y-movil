import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/prestamo.dart';
import '../utils/formatos.dart';
import 'estado_chip.dart';

/// Tarjeta de un préstamo. La usan el socio (Mis préstamos) y el bibliotecario.
class PrestamoTile extends StatelessWidget {
  const PrestamoTile({
    super.key,
    required this.prestamo,
    this.mostrarSocio = false,
    this.acciones = const [],
  });

  final Prestamo prestamo;
  final bool mostrarSocio;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final p = prestamo;
    final textos = Theme.of(context).textTheme;
    final multa = p.multa;

    final EstadoChip chip;
    if (p.activo && p.atrasado) {
      chip = EstadoChip(texto: 'Atrasado ${p.diasAtraso} d', tipo: TipoEstado.malo);
    } else if (p.activo) {
      chip = const EstadoChip(texto: 'Activo', tipo: TipoEstado.alerta);
    } else {
      chip = const EstadoChip(texto: 'Devuelto', tipo: TipoEstado.bueno);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(p.libroTitulo, style: textos.titleMedium)),
                const SizedBox(width: 8),
                chip,
              ],
            ),
            const SizedBox(height: 6),
            Text('Copia ${p.codigoInventario} · préstamo #${p.id}', style: textos.bodySmall),
            if (mostrarSocio)
              Text('Socio #${p.socioId}: ${p.socioNombre} (${p.socioRut})',
                  style: textos.bodySmall),
            const SizedBox(height: 6),
            Text('Prestado: ${fechaHora(p.fechaPrestamo)}'),
            Text('Vence: ${fecha(p.fechaVencimiento)}'),
            if (p.fechaDevolucion != null) Text('Devuelto: ${fechaHora(p.fechaDevolucion!)}'),
            if (multa != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Multa ${pesos(multa.monto)} (${multa.diasAtraso} días × '
                      '${pesos(multa.monto ~/ multa.diasAtraso)})',
                    ),
                  ),
                  EstadoChip(
                    texto: multa.pendiente ? 'Pendiente' : 'Pagada',
                    tipo: multa.pendiente ? TipoEstado.malo : TipoEstado.bueno,
                  ),
                ],
              ),
            ],
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: acciones),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Tienes 2 de 3 préstamos activos"
String resumenCupos(int activos) =>
    'Tienes $activos de ${ApiConfig.maxPrestamosActivos} préstamos activos';
