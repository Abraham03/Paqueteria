// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/paquetes/presentation/screens/paquetes_screen.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/lotes/presentation/screens/lotes_screen.dart';
import '../../theme/app_colors.dart';

// --- IMPORTAMOS LAS PANTALLAS ADMINISTRATIVAS ---
import '../../../features/catalogos/presentation/screens/catalogo_screen.dart';
import '../../../features/recolector/presentation/screens/modal_nueva_recoleccion.dart'; // Ajusta la ruta a donde guardaste el modal de WhatsApp

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

// --- PANTALLA DE PERFIL REFACTORIZADA (CON SECCIÓN ADMINISTRATIVA) ---
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final esAdministrador = user?.rol == 'Dueño' || user?.rol == 'Administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      // Usamos SingleChildScrollView por si la pantalla es pequeña y los botones no caben
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            // --- HEADER DEL USUARIO ---
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

            // --- SECCIÓN DE ADMINISTRACIÓN (Solo visible para jefes) ---
            if (esAdministrador) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Panel Administrativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              
              // Botón 1: Recolecciones WhatsApp
              _buildMenuBoton(
                context, 
                titulo: 'Recolección (WhatsApp)', 
                subtitulo: 'Ingresar coordenadas manuales', 
                icono: Icons.location_on_outlined, 
                color: AppColors.primary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ModalNuevaRecoleccion(),
                  );
                }
              ),
              const SizedBox(height: 12),

              // Botón 2: Catálogo de Zonas
              _buildMenuBoton(
                context, 
                titulo: 'Zonas y Catálogos', 
                subtitulo: 'Administrar Estados y Colonias', 
                icono: Icons.map_outlined, 
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CatalogoCrudScreen()),
                  );
                }
              ),
              
              const SizedBox(height: 48),
            ],

            // --- BOTÓN DE CERRAR SESIÓN ---
            SizedBox(
              width: double.infinity, // Ocupa todo el ancho disponible
              height: 56, 
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

  // --- WIDGET REUTILIZABLE PARA LOS BOTONES DEL MENÚ ---
  Widget _buildMenuBoton(BuildContext context, {
    required String titulo, 
    required String subtitulo, 
    required IconData icono, 
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}