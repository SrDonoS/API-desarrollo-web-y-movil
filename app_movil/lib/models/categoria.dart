class Categoria {
  const Categoria({required this.id, required this.nombre, this.totalLibros});

  final int id;
  final String nombre;

  /// Solo viene en E10/E11 (en un libro, la categoría viene resumida).
  final int? totalLibros;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        totalLibros: json['total_libros'] as int?,
      );
}
