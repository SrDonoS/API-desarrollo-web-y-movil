import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/categoria.dart';
import '../../models/libro.dart';
import '../../providers/sesion.dart';
import '../../utils/mensajes.dart';
import '../../utils/validaciones.dart' as v;

/// E06 (crear) y E07 (reemplazar). Solo bibliotecario.
/// Ojo: E07 es PUT = se envían TODOS los campos (si el año va vacío, queda null).
class LibroFormScreen extends StatefulWidget {
  const LibroFormScreen({super.key, this.libro});

  /// null = crear; con valor = editar ese libro
  final Libro? libro;

  @override
  State<LibroFormScreen> createState() => _LibroFormScreenState();
}

class _LibroFormScreenState extends State<LibroFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _autor;
  late final TextEditingController _isbn;
  late final TextEditingController _anio;
  int? _categoriaId;
  List<Categoria> _categorias = [];
  bool _guardando = false;
  ApiException? _error;
  String? _errorCategoria;

  bool get _editando => widget.libro != null;

  @override
  void initState() {
    super.initState();
    final l = widget.libro;
    _titulo = TextEditingController(text: l?.titulo ?? '');
    _autor = TextEditingController(text: l?.autor ?? '');
    _isbn = TextEditingController(text: l?.isbn ?? '');
    _anio = TextEditingController(text: l?.anioPublicacion?.toString() ?? '');
    _categoriaId = l?.categoria.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarCategorias();
    });
  }

  @override
  void dispose() {
    for (final c in [_titulo, _autor, _isbn, _anio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await context.read<Sesion>().categorias.listar();
      if (mounted) setState(() => _categorias = categorias);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _error = null;
      _errorCategoria = _categoriaId == null ? 'Elige una categoría' : null;
    });
    final valido = _form.currentState!.validate();
    if (!valido || _categoriaId == null) return;

    final entrada = LibroEntrada(
      titulo: _titulo.text.trim(),
      autor: _autor.text.trim(),
      isbn: _isbn.text.trim().toUpperCase(),
      categoriaId: _categoriaId!,
      anioPublicacion: int.tryParse(_anio.text.trim()),
    );
    final servicio = context.read<Sesion>().libros;
    setState(() => _guardando = true);
    try {
      final libro = _editando
          ? await servicio.reemplazar(widget.libro!.id, entrada)
          : await servicio.crear(entrada);
      if (mounted) Navigator.of(context).pop(libro);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _errorCategoria = e.errorDe('categoria_id');
      });
      // Los 400 con "detalles" se ven debajo de cada campo; el resto, abajo.
      if (e.detalles.isEmpty) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _deco(String etiqueta, String campo, {String? ayuda}) => InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        errorText: _error?.errorDe(campo),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar libro' : 'Nuevo libro')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titulo,
              decoration: _deco('Título', 'titulo'),
              validator: (x) => v.largo(x, 2, 200),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _autor,
              textCapitalization: TextCapitalization.words,
              decoration: _deco('Autor/a', 'autor'),
              validator: (x) => v.largo(x, 3, 120),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn,
              decoration: _deco('ISBN', 'isbn', ayuda: '10 o 13 dígitos, sin guiones'),
              validator: v.isbn,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _anio,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('Año de publicación (opcional)', 'anio_publicacion'),
              validator: v.anio,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Categoría',
                errorText: _errorCategoria,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _categorias.any((c) => c.id == _categoriaId) ? _categoriaId : null,
                  isExpanded: true,
                  isDense: true,
                  hint: Text(_categorias.isEmpty ? 'Cargando…' : 'Elige una'),
                  items: [
                    for (final c in _categorias)
                      DropdownMenuItem<int>(value: c.id, child: Text(c.nombre)),
                  ],
                  onChanged: (id) => setState(() {
                    _categoriaId = id;
                    _errorCategoria = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_editando ? 'Guardar cambios' : 'Crear libro'),
            ),
          ],
        ),
      ),
    );
  }
}
