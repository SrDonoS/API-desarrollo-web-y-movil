// Las mismas reglas de la hoja 3-Entradas, para avisar ANTES de llamar a la API.
// (La API igual valida todo: esto es solo para que la persona no espere un 400).

final _rut = RegExp(r'^[0-9]{7,8}-[0-9Kk]$');
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _isbn = RegExp(r'^([0-9]{9}[0-9X]|[0-9]{13})$');
final _codigo = RegExp(r'^[A-Z0-9-]{3,30}$');

String? requerido(String? v, [String nombre = 'Este campo']) =>
    (v == null || v.trim().isEmpty) ? '$nombre es obligatorio' : null;

String? largo(String? v, int min, int max) {
  final t = v?.trim() ?? '';
  if (t.length < min || t.length > max) return 'Debe tener entre $min y $max caracteres';
  return null;
}

String? rut(String? v) =>
    _rut.hasMatch(v?.trim() ?? '') ? null : 'Formato 12345678-9 (sin puntos, con guion)';

String? email(String? v) => _email.hasMatch(v?.trim() ?? '') ? null : 'Correo inválido';

String? clave(String? v) => (v ?? '').length >= 8 ? null : 'Mínimo 8 caracteres';

String? isbn(String? v) =>
    _isbn.hasMatch(v?.trim() ?? '') ? null : '10 o 13 dígitos, sin guiones';

String? codigoInventario(String? v) =>
    _codigo.hasMatch(v?.trim() ?? '') ? null : 'Mayúsculas, números y guion (3 a 30)';

String? anio(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return null; // es opcional
  final n = int.tryParse(t);
  if (n == null || n < 1450 || n > DateTime.now().year) {
    return 'Entre 1450 y ${DateTime.now().year}';
  }
  return null;
}

String? entero(String? v, [String nombre = 'Este campo']) {
  final n = int.tryParse(v?.trim() ?? '');
  return (n == null || n < 1) ? '$nombre debe ser un número' : null;
}
