import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/paquetes/presentation/screens/paquetes_screen.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/lotes/presentation/screens/lotes_screen.dart';
import '../../theme/app_colors.dart';

// --- IMPORTACIÓN DE LA NUEVA PANTALLA SEPARADA ---
import '../../../features/perfil/presentation/screens/perfil_screen.dart'; 

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 1;

  List<Widget> _getScreensForRole(String rol) {
    if (rol == 'Dueño' || rol == 'Administrador') {
      return const [
        PaquetesScreen(), 
        LotesScreen(),    
        PerfilScreen(),
      ];
    } else {
      return const [
        LotesScreen(),    
        PerfilScreen(),
      ];
    }
  }

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
    final user = ref.watch(authProvider).user;
    final rol = user?.rol ?? 'Empleado';

    final screens = _getScreensForRole(rol);
    final navItems = _getNavItemsForRole(rol);

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent, 
        destinations: navItems,
      ),
    );
  }
}