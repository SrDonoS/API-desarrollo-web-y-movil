/// Respuesta paginada del contrato: {"total", "pagina", "tam", "paginas", "items"}
class Pagina<T> {
  const Pagina({
    required this.total,
    required this.pagina,
    required this.tam,
    required this.paginas,
    required this.items,
  });

  final int total;
  final int pagina;
  final int tam;
  final int paginas;
  final List<T> items;

  bool get hayMas => pagina < paginas;

  factory Pagina.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) convertir,
  ) =>
      Pagina<T>(
        total: json['total'] as int,
        pagina: json['pagina'] as int,
        tam: json['tam'] as int,
        paginas: json['paginas'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => convertir(e as Map<String, dynamic>))
            .toList(),
      );
}
