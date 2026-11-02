String _dos(int n) => n.toString().padLeft(2, '0');

/// 27-10-2026
String fecha(DateTime d) => '${_dos(d.day)}-${_dos(d.month)}-${d.year}';

/// 13-10-2026 10:30
String fechaHora(DateTime d) => '${fecha(d)} ${_dos(d.hour)}:${_dos(d.minute)}';

/// 1500 -> $1.500
String pesos(int monto) {
  final digitos = monto.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return '${monto < 0 ? '-' : ''}\$$buffer';
}
