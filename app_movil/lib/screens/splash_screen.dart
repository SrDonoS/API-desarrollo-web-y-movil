import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/sesion.dart';

/// Se ve mientras se revisa el token guardado, o si no hay conexión con la API.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.sinConexion = false});

  final bool sinConexion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📚', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Biblioteca Comunitaria',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              if (!sinConexion)
                const CircularProgressIndicator()
              else ...[
                const Text(
                  'No pudimos conectarnos con la API.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(ApiConfig.baseUrl, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.read<Sesion>().iniciar(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
