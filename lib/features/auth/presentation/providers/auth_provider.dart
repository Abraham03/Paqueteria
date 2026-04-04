import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/usuario_model.dart';

// 1. Inyectamos el repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// 2. Definimos los estados posibles del Login
class AuthState {
  final bool isLoading;
  final String errorMessage;
  final UsuarioModel? user;

  AuthState({
    this.isLoading = false,
    this.errorMessage = '',
    this.user,
  });

  AuthState copyWith({bool? isLoading, String? errorMessage, UsuarioModel? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

// 3. Creamos el Notificador moderno (Notifier es el nuevo estándar en lugar de StateNotifier)
class AuthNotifier extends Notifier<AuthState> {
  
  @override
  AuthState build() {
    return AuthState(); // Este es el estado inicial cuando la app arranca
  }

  Future<bool> login(String usuario, String password) async {
    // Cambiamos el estado a "Cargando"
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      // Como usamos Notifier, tenemos acceso a 'ref' automáticamente para leer el repositorio
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(usuario, password);
      
      // Éxito: Guardamos el usuario en el estado
      state = state.copyWith(isLoading: false, user: user);
      return true; 
    } catch (e) {
      // Error: Guardamos el mensaje para mostrarlo en un SnackBar
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // MÉTODO LOGOUT
  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout(); // Borra los datos del Secure Storage
    state = AuthState(); // Reinicia el estado a los valores de fábrica (vacío)
  }

}

// 4. El Provider principal que usará la pantalla
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});