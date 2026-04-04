import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/presentation/screens/main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();

    final success = await ref.read(authProvider.notifier).login(
          _usuarioController.text.trim(),
          _passwordController.text,
        );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido!'), backgroundColor: AppColors.success),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      // El fondo se toma de AppTheme automáticamente
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.local_shipping, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Tech Solutions',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                Text(
                  'Logística y Paquetería',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),

                // Input Usuario (El diseño de caja lo pone el AppTheme)
                TextFormField(
                  controller: _usuarioController,
                  enabled: !authState.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa tu usuario' : null,
                ),
                const SizedBox(height: 16),

                // Input Contraseña
                TextFormField(
                  controller: _passwordController,
                  enabled: !authState.isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 32),

                // Botón de Login (Tamaño y estilo definidos en AppTheme)
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submitLogin,
                  child: authState.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('INICIAR SESIÓN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}