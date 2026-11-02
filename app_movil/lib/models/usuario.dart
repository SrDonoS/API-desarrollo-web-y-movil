class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.rut,
    required this.email,
    required this.rol,
    required this.activo,
    this.creado,
  });

  /// También es el "número de socio" que se muestra en el mesón.
  final int id;
  final String nombre;
  final String rut;
  final String email;

  /// "socio" o "bibliotecario"
  final String rol;
  final bool activo;
  final DateTime? creado;

  bool get esBibliotecario => rol == 'bibliotecario';

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        rut: json['rut'] as String,
        email: json['email'] as String,
        rol: json['rol'] as String,
        activo: json['activo'] as bool? ?? true,
        creado: json['creado'] == null ? null : DateTime.parse(json['creado'] as String),
      );
}
