import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../providers/sesion.dart';
import '../../utils/mensajes.dart';
import '../../utils/validaciones.dart' as v;
import 'registro_screen.dart';

/// E02 · Iniciar sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // "Tu sesión expiró": se muestra una sola vez, apenas se abre el login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final aviso = context.read<Sesion>().tomarAviso();
      if (aviso != null) mostrarExito(context, aviso);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<Sesion>().iniciarSesion(_email.text.trim(), _clave.text);
      // Si sale bien, la app cambia sola a la pantalla de inicio.
    } on ApiException catch (e) {
      // 401 = "Correo o contraseña incorrectos" (mismo mensaje siempre, por seguridad)
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _irARegistro() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
    if (email != null && mounted) {
      _email.text = email;
      mostrarExito(context, '¡Cuenta creada! Ahora inicia sesión 🙌');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('📚', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
                  Text(
                    'Biblioteca Comunitaria',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: v.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clave,
                    obscureText: !_verClave,
                    decoration: InputDecoration(
                      labelText: 'Clave',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _verClave = !_verClave),
                      ),
                    ),
                    validator: (valor) => v.requerido(valor, 'La clave'),
                    onFieldSubmitted: (_) => _ingresar(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _cargando ? null : _ingresar,
                    child: _cargando
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Ingresar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando ? null : _irARegistro,
                    child: const Text('¿No tienes cuenta? Hazte socio'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Usuarios de prueba (flask init-db):\n'
                      'biblio@biblioteca.cl / biblio1234\n'
                      'ana.rojas@correo.cl / clave-segura-123',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
