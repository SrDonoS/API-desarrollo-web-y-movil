import 'categoria.dart';
import 'copia.dart';

class Libro {
  const Libro({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.isbn,
    required this.categoria,
    required this.copiasTotal,
    required this.copiasDisponibles,
    required this.disponible,
    this.anioPublicacion,
    this.copias = const [],
  });

  final int id;
  final String titulo;
  final String autor;
  final String isbn;
  final int? anioPublicacion;
  final Categoria categoria;
  final int copiasTotal;
  final int copiasDisponibles;
  final bool disponible;

  /// Solo viene en el detalle (E05).
  final List<Copia> copias;

  factory Libro.fromJson(Map<String, dynamic> json) => Libro(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        autor: json['autor'] as String,
        isbn: json['isbn'] as String,
        anioPublicacion: json['anio_publicacion'] as int?,
        categoria: Categoria.fromJson(json['categoria'] as Map<String, dynamic>),
        copiasTotal: json['copias_total'] as int? ?? 0,
        copiasDisponibles: json['copias_disponibles'] as int? ?? 0,
        disponible: json['disponible'] as bool? ?? false,
        copias: (json['copias'] as List<dynamic>? ?? const [])
            .map((c) => Copia.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

/// Lo que se ENVÍA en E06 (crear) y E07 (reemplazar). Nunca lleva id.
class LibroEntrada {
  const LibroEntrada({
    required this.titulo,
    required this.autor,
    required this.isbn,
    required this.categoriaId,
    this.anioPublicacion,
  });

  final String titulo;
  final String autor;
  final String isbn;
  final int categoriaId;
  final int? anioPublicacion;

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'autor': autor,
        'isbn': isbn,
        'categoria_id': categoriaId,
        if (anioPublicacion != null) 'anio_publicacion': anioPublicacion,
      };
}
