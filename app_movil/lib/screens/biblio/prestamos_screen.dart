import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/prestamo.dart';
import '../../providers/sesion.dart';
import '../../utils/formatos.dart';
import '../../utils/mensajes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/prestamo_tile.dart';
import '../../widgets/vista_error.dart';
import 'nuevo_prestamo_screen.dart';

/// Panel del bibliotecario:
///   E13 ver préstamos de todos · E12 nuevo préstamo · E14 devolución · E16 cobrar multa
class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

enum _Vista { activos, atrasados, multasPendientes, todos }

class _PrestamosScreenState extends State<PrestamosScreen> {
  final _socio = TextEditingController();
  final _prestamos = <Prestamo>[];
  _Vista _vista = _Vista.activos;
  int _pagina = 0;
  bool _hayMas = true;
  bool _cargando = true;
  Object? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recargar();
    });
  }

  @override
  void dispose() {
    _socio.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    _version++;
    setState(() {
      _prestamos.clear();
      _pagina = 0;
      _hayMas = true;
      _cargando = false;
      _error = null;
    });
    await _cargarMas();
  }

  Future<void> _cargarMas() async {
    if (_cargando || !_hayMas) return;
    final version = _version;
    final servicio = context.read<Sesion>().prestamos;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pagina = await servicio.listar(
        socioId: int.tryParse(_socio.text.trim()),
        estado: _vista == _Vista.activos ? 'activo' : null,
        atrasado: _vista == _Vista.atrasados ? true : null,
        multa: _vista == _Vista.multasPendientes ? 'pendiente' : null,
        pagina: _pagina + 1,
      );
      if (!mounted || version != _version) return;
      setState(() {
        _prestamos.addAll(pagina.items);
        _pagina = pagina.pagina;
        _hayMas = pagina.hayMas;
      });
    } catch (e) {
      if (mounted && version == _version) setState(() => _error = e);
    } finally {
      if (mounted && version == _version) setState(() => _cargando = false);
    }
  }

  // --- Acciones -----------------------------------------------------------------
  Future<void> _devolver(Prestamo p) async {
    final servicio = context.read<Sesion>().prestamos;
    final ok = await confirmar(
      context,
      titulo: 'Registrar devolución',
      mensaje: '¿${p.socioNombre} devolvió "${p.libroTitulo}" (${p.codigoInventario})?',
      accion: 'Sí, devolvió',
    );
    if (!ok || !mounted) return;
    try {
      final devuelto = await servicio.devolver(p.id);
      if (!mounted) return;
      final multa = devuelto.multa;
      if (multa == null) {
        mostrarExito(context, 'Devuelto a tiempo ✅ La copia quedó disponible.');
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.payments_outlined),
            title: const Text('Devuelto con atraso'),
            content: Text('${multa.diasAtraso} días de atraso: se generó una multa de '
                '${pesos(multa.monto)} (pendiente).'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido')),
            ],
          ),
        );
      }
      if (mounted) _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _cobrar(Prestamo p) async {
    final multa = p.multa;
    if (multa == null) return;
    final servicio = context.read<Sesion>().prestamos;
    final ok = await confirmar(
      context,
      titulo: 'Cobrar multa',
      mensaje: '¿${p.socioNombre} pagó ${pesos(multa.monto)}?',
      accion: 'Sí, pagó',
    );
    if (!ok || !mounted) return;
    try {
      await servicio.pagarMulta(multa.id);
      if (!mounted) return;
      mostrarExito(context, 'Pago de ${pesos(multa.monto)} registrado 💸');
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _nuevo() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NuevoPrestamoScreen()),
    );
    if (creado == true && mounted) _recargar();
  }

  // --- Pantalla -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préstamos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        icon: const Icon(Icons.add),
        label: const Text('Préstamo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _socio,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Filtrar por número de socio',
                prefixIcon: const Icon(Icons.person_search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _socio.clear();
                    _recargar();
                  },
                ),
              ),
              onSubmitted: (_) => _recargar(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                _chip('Activos', _Vista.activos),
                _chip('Atrasados', _Vista.atrasados),
                _chip('Multa pendiente', _Vista.multasPendientes),
                _chip('Todos', _Vista.todos),
              ],
            ),
          ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _chip(String texto, _Vista vista) => ChoiceChip(
        label: Text(texto),
        selected: _vista == vista,
        onSelected: (_) {
          setState(() => _vista = vista);
          _recargar();
        },
      );

  Widget _lista() {
    if (_error != null && _prestamos.isEmpty) {
      return VistaError(error: _error!, alReintentar: _recargar);
    }
    if (_cargando && _prestamos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _recargar,
      child: _prestamos.isEmpty
          ? const VistaVacia(icono: Icons.inbox_outlined, texto: 'No hay préstamos con ese filtro')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _prestamos.length + 1,
              itemBuilder: (context, i) {
                if (i == _prestamos.length) return _pie();
                final p = _prestamos[i];
                final multa = p.multa;
                return PrestamoTile(
                  prestamo: p,
                  mostrarSocio: true,
                  acciones: [
                    if (p.activo)
                      FilledButton.tonalIcon(
                        onPressed: () => _devolver(p),
                        icon: const Icon(Icons.assignment_return),
                        label: const Text('Registrar devolución'),
                      ),
                    if (multa != null && multa.pendiente)
                      OutlinedButton.icon(
                        onPressed: () => _cobrar(p),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text('Cobrar ${pesos(multa.monto)}'),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _pie() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hayMas) {
      return Center(
        child: TextButton.icon(
          onPressed: _cargarMas,
          icon: const Icon(Icons.expand_more),
          label: const Text('Cargar más'),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}
