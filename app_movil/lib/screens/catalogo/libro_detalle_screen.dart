import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/copia.dart';
import '../../models/libro.dart';
import '../../providers/sesion.dart';
import '../../utils/formatos.dart';
import '../../utils/mensajes.dart';
import '../../utils/validaciones.dart' as v;
import '../../widgets/dialogos.dart';
import '../../widgets/estado_chip.dart';
import '../../widgets/vista_error.dart';
import 'libro_form_screen.dart';

/// E05 (detalle). El bibliotecario además puede:
///   E07 editar · E08 eliminar · E09 agregar copia · E12 prestar una copia disponible
class LibroDetalleScreen extends StatefulWidget {
  const LibroDetalleScreen({super.key, required this.libroId});

  final int libroId;

  @override
  State<LibroDetalleScreen> createState() => _LibroDetalleScreenState();
}

class _LibroDetalleScreenState extends State<LibroDetalleScreen> {
  Libro? _libro;
  Object? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    final servicio = context.read<Sesion>().libros;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final libro = await servicio.detalle(widget.libroId);
      if (mounted) setState(() => _libro = libro);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // --- Acciones del bibliotecario -----------------------------------------------
  Future<void> _prestar(Copia copia) async {
    final servicio = context.read<Sesion>().prestamos;
    final socio = await pedirTexto(
      context,
      titulo: 'Prestar ${copia.codigoInventario}',
      etiqueta: 'Número de socio',
      ayuda: 'El socio lo ve en "Mi perfil" de su app',
      accion: 'Prestar',
      teclado: TextInputType.number,
      formateadores: [FilteringTextInputFormatter.digitsOnly],
      validar: (x) => v.entero(x, 'El número de socio'),
    );
    if (socio == null || !mounted) return;
    try {
      final prestamo =
          await servicio.prestar(socioId: int.parse(socio), copiaId: copia.id);
      if (!mounted) return;
      mostrarExito(context,
          'Préstamo #${prestamo.id} a ${prestamo.socioNombre}. Vence el ${fecha(prestamo.fechaVencimiento)} 📅');
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _agregarCopia() async {
    final servicio = context.read<Sesion>().libros;
    final codigo = await pedirTexto(
      context,
      titulo: 'Nueva copia física',
      etiqueta: 'Código de inventario',
      ayuda: 'El de la etiqueta. Ej: LIB-000123',
      accion: 'Agregar',
      formateadores: [MayusculasFormatter()],
      validar: v.codigoInventario,
    );
    if (codigo == null || !mounted) return;
    try {
      await servicio.agregarCopia(widget.libroId, codigo);
      if (!mounted) return;
      mostrarExito(context, 'Copia $codigo agregada ✅');
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _editar() async {
    final libro = _libro;
    if (libro == null) return;
    final editado = await Navigator.of(context).push<Libro>(
      MaterialPageRoute(builder: (_) => LibroFormScreen(libro: libro)),
    );
    if (editado != null && mounted) {
      mostrarExito(context, 'Libro actualizado');
      _cargar();
    }
  }

  Future<void> _eliminar() async {
    final libro = _libro;
    if (libro == null) return;
    final servicio = context.read<Sesion>().libros;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar libro',
      mensaje: '¿Eliminar "${libro.titulo}" y sus ${libro.copiasTotal} copias? '
          'No se puede si alguna vez se prestó.',
      accion: 'Eliminar',
    );
    if (!ok || !mounted) return;
    try {
      await servicio.eliminar(libro.id);
      if (!mounted) return;
      mostrarExito(context, 'Libro eliminado 🗑️');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) mostrarError(context, e); // 409 LIBRO_CON_PRESTAMOS
    }
  }

  // --- Pantalla ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final esBiblio = sesion.esBibliotecario;
    final libro = _libro;

    return Scaffold(
      appBar: AppBar(
        title: Text(libro?.titulo ?? 'Libro'),
        actions: [
          if (esBiblio && libro != null) ...[
            IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit), onPressed: _editar),
            IconButton(
                tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
          ],
        ],
      ),
      floatingActionButton: esBiblio && libro != null
          ? FloatingActionButton.extended(
              onPressed: _agregarCopia,
              icon: const Icon(Icons.library_add),
              label: const Text('Copia'),
            )
          : null,
      body: _cuerpo(libro, esBiblio, sesion.usuario?.id),
    );
  }

  Widget _cuerpo(Libro? libro, bool esBiblio, int? numeroSocio) {
    if (_cargando && libro == null) return const Center(child: CircularProgressIndicator());
    if (_error != null && libro == null) return VistaError(error: _error!, alReintentar: _cargar);
    if (libro == null) return const SizedBox.shrink();

    final textos = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(libro.titulo, style: textos.headlineSmall),
          const SizedBox(height: 4),
          Text(libro.autor, style: textos.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EstadoChip(texto: libro.categoria.nombre, tipo: TipoEstado.neutro),
              if (libro.anioPublicacion != null)
                EstadoChip(texto: '${libro.anioPublicacion}', tipo: TipoEstado.neutro),
              EstadoChip(texto: 'ISBN ${libro.isbn}', tipo: TipoEstado.neutro),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                libro.disponible ? Icons.check_circle : Icons.hourglass_bottom,
                color: libro.disponible ? Colors.green : Colors.orange,
              ),
              title: Text(libro.disponible
                  ? '${libro.copiasDisponibles} de ${libro.copiasTotal} copias disponibles'
                  : 'Sin copias disponibles por ahora'),
              subtitle: esBiblio
                  ? const Text('Toca una copia disponible para prestarla')
                  : Text(libro.disponible
                      ? 'Pídelo en el mesón con tu número de socio: #${numeroSocio ?? '-'}'
                      : 'Vuelve a revisar en unos días'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Copias físicas (${libro.copias.length})', style: textos.titleMedium),
          const SizedBox(height: 4),
          if (libro.copias.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Este libro todavía no tiene copias.'),
            ),
          for (final copia in libro.copias)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code_2),
              title: Text(copia.codigoInventario),
              subtitle: Text('N.º de copia: ${copia.id}'),
              trailing: EstadoChip(
                texto: copia.disponible ? 'Disponible' : 'Prestada',
                tipo: copia.disponible ? TipoEstado.bueno : TipoEstado.alerta,
              ),
              onTap: esBiblio && copia.disponible ? () => _prestar(copia) : null,
            ),
        ],
      ),
    );
  }
}
