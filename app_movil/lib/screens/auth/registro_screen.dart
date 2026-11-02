import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../providers/sesion.dart';
import '../../utils/mensajes.dart';
import '../../utils/validaciones.dart' as v;

/// E01 · Hacerse socio. El rol NO se envía: el servidor siempre crea "socio".
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _rut = TextEditingController();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  final _clave2 = TextEditingController();
  bool _cargando = false;
  ApiException? _error; // para mostrar los errores 400 debajo de cada campo

  @override
  void dispose() {
    for (final c in [_nombre, _rut, _email, _clave, _clave2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final usuario = await context.read<Sesion>().auth.registrar(
            nombre: _nombre.text.trim(),
            rut: _rut.text.trim().toUpperCase(),
            email: _email.text.trim(),
            clave: _clave.text,
          );
      if (mounted) Navigator.of(context).pop(usuario.email);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.detalles.isEmpty) mostrarError(context, e); // 409 u otro
    } finally {
      if (mounted) setState(() => _cargando = false);
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
      appBar: AppBar(title: const Text('Hazte socio')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: _deco('Nombre completo', 'nombre'),
              validator: (x) => v.largo(x, 3, 100),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rut,
              decoration: _deco('RUT', 'rut', ayuda: 'Sin puntos y con guion: 12345678-9'),
              validator: v.rut,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _deco('Correo', 'email'),
              validator: v.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clave,
              obscureText: true,
              decoration: _deco('Clave', 'clave', ayuda: 'Mínimo 8 caracteres'),
              validator: v.clave,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clave2,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Repite la clave',
                border: OutlineInputBorder(),
              ),
              validator: (x) => x == _clave.text ? null : 'Las claves no coinciden',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _cargando ? null : _registrar,
              child: _cargando
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear mi cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
