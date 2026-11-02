import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/sesion.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final u = sesion.usuario;
    if (u == null) return const SizedBox.shrink();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                style: textos.headlineMedium),
          ),
          const SizedBox(height: 12),
          Text(u.nombre, textAlign: TextAlign.center, style: textos.titleLarge),
          Text(
            u.esBibliotecario ? '👩‍💼 Bibliotecario/a' : '🙋 Socio/a',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!u.esBibliotecario)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Tu número de socio'),
                    Text('${u.id}', style: textos.displayMedium),
                    const Text(
                      'Muéstralo en el mesón para pedir un libro 📚',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ListTile(leading: const Icon(Icons.badge_outlined), title: Text(u.rut), subtitle: const Text('RUT')),
          ListTile(leading: const Icon(Icons.email_outlined), title: Text(u.email), subtitle: const Text('Correo')),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.read<Sesion>().cerrarSesion(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(height: 24),
          Text('API: ${ApiConfig.baseUrl}', textAlign: TextAlign.center, style: textos.bodySmall),
        ],
      ),
    );
  }
}
