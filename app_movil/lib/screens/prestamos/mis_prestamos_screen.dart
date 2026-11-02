import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prestamo.dart';
import '../../providers/sesion.dart';
import '../../utils/formatos.dart';
import '../../widgets/prestamo_tile.dart';
import '../../widgets/vista_error.dart';

/// E15 · MIS préstamos (socio).
/// No se envía ningún id: el servidor saca al socio del token. Es imposible ver los de otro.
class MisPrestamosScreen extends StatefulWidget {
  const MisPrestamosScreen({super.key});

  @override
  State<MisPrestamosScreen> createState() => _MisPrestamosScreenState();
}

enum _Filtro { todos, activos, devueltos }

class _MisPrestamosScreenState extends State<MisPrestamosScreen> {
  List<Prestamo> _prestamos = [];
  _Filtro _filtro = _Filtro.todos;
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    final servicio = context.read<Sesion>().prestamos;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Se piden todos y se filtran aquí, para poder mostrar siempre el resumen de cupos.
      final prestamos = await servicio.misPrestamos();
      if (mounted) setState(() => _prestamos = prestamos);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos = _prestamos.where((p) => p.activo).length;
    final deuda = _prestamos
        .where((p) => p.multa != null && p.multa!.pendiente)
        .fold<int>(0, (total, p) => total + p.multa!.monto);
    final visibles = _prestamos
        .where((p) => switch (_filtro) {
              _Filtro.todos => true,
              _Filtro.activos => p.activo,
              _Filtro.devueltos => !p.activo,
            })
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis préstamos')),
      body: Builder(builder: (context) {
        if (_cargando && _prestamos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null && _prestamos.isEmpty) {
          return VistaError(error: _error!, alReintentar: _cargar);
        }
        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.auto_stories),
                  title: Text(resumenCupos(activos)),
                  subtitle: deuda > 0
                      ? Text('Tienes multas pendientes por ${pesos(deuda)}. Págalas en el mesón.')
                      : const Text('Sin multas pendientes 🙌'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _chip('Todos', _Filtro.todos),
                    _chip('Activos', _Filtro.activos),
                    _chip('Devueltos', _Filtro.devueltos),
                  ],
                ),
              ),
              if (visibles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nada por aquí todavía 📭', textAlign: TextAlign.center),
                ),
              for (final p in visibles) PrestamoTile(prestamo: p),
            ],
          ),
        );
      }),
    );
  }

  Widget _chip(String texto, _Filtro filtro) => ChoiceChip(
        label: Text(texto),
        selected: _filtro == filtro,
        onSelected: (_) => setState(() => _filtro = filtro),
      );
}
