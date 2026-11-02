import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/categoria.dart';
import '../../models/libro.dart';
import '../../providers/sesion.dart';
import '../../utils/mensajes.dart';
import '../../utils/validaciones.dart' as v;
import '../../widgets/dialogos.dart';
import '../../widgets/estado_chip.dart';
import '../../widgets/vista_error.dart';
import 'libro_detalle_screen.dart';
import 'libro_form_screen.dart';

/// E04 (catálogo) + E10 (categorías para el filtro).
/// El bibliotecario además puede crear libros (E06) y categorías (E11).
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _buscar = TextEditingController();
  final _libros = <Libro>[];
  List<Categoria> _categorias = [];
  int? _categoriaId;
  bool _soloDisponibles = false;

  int _pagina = 0;
  bool _hayMas = true;
  bool _cargando = true; // la primera carga parte apenas se dibuja la pantalla
  Object? _error;
  int _version = 0; // para ignorar respuestas viejas si cambian los filtros rápido

  @override
  void initState() {
    super.initState();
    // Se carga apenas termina de dibujarse la pantalla (no se llama a setState en initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cargarCategorias();
      _recargar();
    });
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await context.read<Sesion>().categorias.listar();
      if (mounted) setState(() => _categorias = categorias);
    } catch (_) {
      // El filtro por categoría es opcional: si falla, el catálogo igual funciona.
    }
  }

  Future<void> _recargar() async {
    _version++;
    setState(() {
      _libros.clear();
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
    final servicio = context.read<Sesion>().libros;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pagina = await servicio.listar(
        buscar: _buscar.text.trim(),
        categoriaId: _categoriaId,
        disponible: _soloDisponibles ? true : null,
        pagina: _pagina + 1,
      );
      if (!mounted || version != _version) return;
      setState(() {
        _libros.addAll(pagina.items);
        _pagina = pagina.pagina;
        _hayMas = pagina.hayMas;
      });
    } catch (e) {
      if (mounted && version == _version) setState(() => _error = e);
    } finally {
      if (mounted && version == _version) setState(() => _cargando = false);
    }
  }

  Future<void> _abrir(Libro libro) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LibroDetalleScreen(libroId: libro.id)),
    );
    if (mounted) _recargar(); // pudo cambiar (copias, préstamos, edición...)
  }

  Future<void> _nuevoLibro() async {
    final creado = await Navigator.of(context).push<Libro>(
      MaterialPageRoute(builder: (_) => const LibroFormScreen()),
    );
    if (creado != null && mounted) {
      mostrarExito(context, 'Libro creado. Ahora agrégale copias 📗');
      _recargar();
    }
  }

  Future<void> _nuevaCategoria() async {
    final sesion = context.read<Sesion>();
    final nombre = await pedirTexto(
      context,
      titulo: 'Nueva categoría',
      etiqueta: 'Nombre',
      accion: 'Crear',
      validar: (x) => v.largo(x, 3, 60),
    );
    if (nombre == null || !mounted) return;
    try {
      final categoria = await sesion.categorias.crear(nombre);
      if (!mounted) return;
      mostrarExito(context, 'Categoría "${categoria.nombre}" creada');
      _cargarCategorias();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esBiblio = context.watch<Sesion>().esBibliotecario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          if (esBiblio)
            IconButton(
              tooltip: 'Nueva categoría',
              icon: const Icon(Icons.new_label_outlined),
              onPressed: _nuevaCategoria,
            ),
        ],
      ),
      floatingActionButton: esBiblio
          ? FloatingActionButton.extended(
              onPressed: _nuevoLibro,
              icon: const Icon(Icons.add),
              label: const Text('Libro'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _buscar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por título o autor',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscar.clear();
                    _recargar();
                  },
                ),
              ),
              onSubmitted: (_) => _recargar(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Solo disponibles'),
                  selected: _soloDisponibles,
                  onSelected: (seleccionado) {
                    setState(() => _soloDisponibles = seleccionado);
                    _recargar();
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<int?>(
                  value: _categoriaId,
                  hint: const Text('Todas las categorías'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todas las categorías')),
                    for (final c in _categorias)
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
                  ],
                  onChanged: (id) {
                    setState(() => _categoriaId = id);
                    _recargar();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    if (_error != null && _libros.isEmpty) {
      return VistaError(error: _error!, alReintentar: _recargar);
    }
    if (_libros.isEmpty && _cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _recargar,
      child: _libros.isEmpty
          ? const VistaVacia(icono: Icons.search_off, texto: 'No hay libros con esos filtros')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _libros.length + 1,
              itemBuilder: (context, i) {
                if (i == _libros.length) return _pie();
                final libro = _libros[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                    title: Text(libro.titulo),
                    subtitle: Text('${libro.autor} · ${libro.categoria.nombre}'),
                    trailing: EstadoChip(
                      texto: '${libro.copiasDisponibles}/${libro.copiasTotal}',
                      tipo: libro.disponible ? TipoEstado.bueno : TipoEstado.malo,
                    ),
                    onTap: () => _abrir(libro),
                  ),
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
