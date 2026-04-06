// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/paquetes/presentation/screens/paquetes_screen.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/lotes/presentation/screens/lotes_screen.dart';
import '../../theme/app_colors.dart';
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // Creamos una función que devuelve las pantallas permitidas según el rol
  List<Widget> _getScreensForRole(String rol) {
    if (rol == 'Dueño' || rol == 'Administrador') {
      return const [
        PaquetesScreen(), // Puede ver y crear paquetes
        LotesScreen(),    // Puede ver y gestionar viajes
        PerfilScreen(),
      ];
    } else {
      // Si es un Chofer o Empleado regular
      return const [
        LotesScreen(),    // Solo ve sus viajes asignados
        PerfilScreen(),
      ];
    }
  }

  // Creamos una función que devuelve los botones (ítems) correspondientes
  List<NavigationDestination> _getNavItemsForRole(String rol) {
    if (rol == 'Dueño' || rol == 'Administrador') {
      return const [
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2, color: AppColors.surface),
          label: 'Paquetes',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping, color: AppColors.surface),
          label: 'Viajes',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.surface),
          label: 'Perfil',
        ),
      ];
    } else {
      // Menú simplificado para Choferes
      return const [
        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping, color: AppColors.surface),
          label: 'Mis Viajes',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.surface),
          label: 'Perfil',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al usuario para saber su rol
    final user = ref.watch(authProvider).user;
    final rol = user?.rol ?? 'Empleado';

    final screens = _getScreensForRole(rol);
    final navItems = _getNavItemsForRole(rol);

    // Seguridad: Si por alguna razón el índice es mayor a las pantallas permitidas, lo reiniciamos
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // NavigationBar es el widget moderno de Material 3
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent, // El color de la "píldora" seleccionada
        destinations: navItems,
      ),
    );
  }
}

// --- PANTALLA DE PERFIL REFACTORIZADA ---
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              user?.nombreCompleto ?? 'Usuario',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent),
              ),
              child: Text(
                user?.rol ?? 'Empleado',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 48),
            
            // Botón de Cerrar Sesión Estilizado
            SizedBox(
              width: 220,
              height: 56, // Altura estándar del AppTheme
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false, 
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
              ),
            )
          ],
        ),
      ),
    );
  }
}