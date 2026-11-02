import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/sesion.dart';
import '../../utils/formatos.dart';
import '../../utils/mensajes.dart';
import '../../utils/validaciones.dart' as v;

/// E12 · Registrar préstamo (bibliotecario), con número de socio y número de copia.
/// (También se puede prestar tocando una copia disponible en el detalle del libro).
class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _form = GlobalKey<FormState>();
  final _socio = TextEditingController();
  final _copia = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _socio.dispose();
    _copia.dispose();
    super.dispose();
  }

  Future<void> _prestar() async {
    if (!_form.currentState!.validate()) return;
    final servicio = context.read<Sesion>().prestamos;
    setState(() => _guardando = true);
    try {
      final p = await servicio.prestar(
        socioId: int.parse(_socio.text),
        copiaId: int.parse(_copia.text),
      );
      if (!mounted) return;
      mostrarExito(context,
          '"${p.libroTitulo}" prestado a ${p.socioNombre}. Vence el ${fecha(p.fechaVencimiento)} 📅');
      Navigator.of(context).pop(true);
    } catch (e) {
      // 400: socio/copia no existe · 409: LIMITE_PRESTAMOS o COPIA_NO_DISPONIBLE
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final soloNumeros = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo préstamo')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'El socio ve su número en "Mi perfil". El número de copia aparece en el '
              'detalle del libro (o toca la copia allí para prestarla directo).',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _socio,
              keyboardType: TextInputType.number,
              inputFormatters: soloNumeros,
              decoration: const InputDecoration(
                labelText: 'Número de socio',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (x) => v.entero(x, 'El número de socio'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _copia,
              keyboardType: TextInputType.number,
              inputFormatters: soloNumeros,
              decoration: const InputDecoration(
                labelText: 'Número de copia (id)',
                prefixIcon: Icon(Icons.qr_code_2),
                border: OutlineInputBorder(),
              ),
              validator: (x) => v.entero(x, 'El número de copia'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _prestar,
              icon: const Icon(Icons.check),
              label: const Text('Registrar préstamo (14 días)'),
            ),
          ],
        ),
      ),
    );
  }
}
