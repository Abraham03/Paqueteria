import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/presentation/screens/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart'; // Ajusta la ruta
// Importa tu pantalla principal (Home / Menú / Paquetes)

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Convertimos a ConsumerWidget para poder leer Riverpod
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el estado de la autenticación
    final authState = ref.watch(authProvider);

    // Decidimos qué pantalla mostrar basándonos en el estado
    Widget screenToShow;

    if (authState.isCheckingAuth) {
      // 1. Está leyendo la memoria del teléfono (Splash Screen)
      screenToShow = const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Puedes cambiarlo por el Logo de tu app
      );
    } else if (authState.user != null) {
      // 2. Hay un usuario guardado: Lo mandamos directo adentro
      screenToShow = const MainScreen(); // <-- PANTALLA PRINCIPAL DE TU SISTEMA
    } else {
      // 3. No hay usuario o cerró sesión: Lo mandamos al Login
      screenToShow = const LoginScreen();
    }

    return MaterialApp(
      title: 'Tech Solutions',
      theme: AppTheme.lightTheme,
      home: screenToShow,
    );
  }
}