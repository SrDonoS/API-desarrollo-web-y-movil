import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/sesion.dart';
import 'screens/auth/login_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/splash_screen.dart';

/// Para cerrar todas las pantallas abiertas cuando la sesión termina (o expira).
final navegador = GlobalKey<NavigatorState>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Sesion(
        alTerminar: () => navegador.currentState?.popUntil((ruta) => ruta.isFirst),
      )..iniciar(),
      child: const BibliotecaApp(),
    ),
  );
}

class BibliotecaApp extends StatelessWidget {
  const BibliotecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca Comunitaria',
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E2761)),
      ),
      home: const Raiz(),
    );
  }
}

/// Decide qué mostrar según la sesión:
///   cargando -> splash · sin conexión -> reintentar · sin sesión -> login · con sesión -> inicio
class Raiz extends StatelessWidget {
  const Raiz({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<Sesion>().estado) {
      EstadoSesion.cargando => const SplashScreen(),
      EstadoSesion.sinConexion => const SplashScreen(sinConexion: true),
      EstadoSesion.sinSesion => const LoginScreen(),
      EstadoSesion.conSesion => const InicioScreen(),
    };
  }
}
