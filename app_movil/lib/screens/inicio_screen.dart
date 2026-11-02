import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sesion.dart';
import 'biblio/prestamos_screen.dart';
import 'catalogo/catalogo_screen.dart';
import 'perfil_screen.dart';
import 'prestamos/mis_prestamos_screen.dart';

/// Barra de navegación de abajo. Cambia según el rol:
///   🙋 socio:          Catálogo · Mis préstamos · Perfil
///   👩‍💼 bibliotecario:  Catálogo · Préstamos     · Perfil
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final esBiblio = context.watch<Sesion>().esBibliotecario;

    final paginas = <Widget>[
      const CatalogoScreen(),
      if (esBiblio) const PrestamosScreen() else const MisPrestamosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz),
            label: esBiblio ? 'Préstamos' : 'Mis préstamos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
