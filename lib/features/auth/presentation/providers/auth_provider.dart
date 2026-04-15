import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/usuario_model.dart';
// Importamos nuestro nuevo servicio
import '../../../../core/services/secure_storage_service.dart'; 

// 1. Inyectamos el repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// 2. Definimos los estados posibles del Login
class AuthState {
  final bool isLoading;
  final bool isCheckingAuth; // <-- NUEVA BANDERA: Para la pantalla de carga (Splash)
  final String errorMessage;
  final UsuarioModel? user;

  AuthState({
    this.isLoading = false,
    this.isCheckingAuth = true, // <-- Inicia en TRUE para que busque la sesión al abrir la app
    this.errorMessage = '',
    this.user,
  });

  AuthState copyWith({bool? isLoading, bool? isCheckingAuth, String? errorMessage, UsuarioModel? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

// 3. Creamos el Notificador
class AuthNotifier extends Notifier<AuthState> {
  
  @override
  AuthState build() {
    // Al construirse, disparamos la verificación automáticamente (Async)
    _checkAuthStatus();
    return AuthState(); // Estado inicial
  }

  // --- NUEVA FUNCIÓN: VERIFICAR SESIÓN GUARDADA ---
  Future<void> _checkAuthStatus() async {
    final storage = ref.read(secureStorageProvider);
    final savedUser = await storage.leerUsuario();
    
    if (savedUser != null) {
      // Sesión encontrada: Quitamos la bandera de carga y asignamos el usuario
      state = state.copyWith(isCheckingAuth: false, user: savedUser);
    } else {
      // No hay sesión: Quitamos la bandera de carga (lo mandará al login)
      state = state.copyWith(isCheckingAuth: false);
    }
  }

  Future<bool> login(String usuario, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(usuario, password);
      
      // ÉXITO: Guardamos al usuario en la memoria encriptada del teléfono
      await ref.read(secureStorageProvider).guardarUsuario(user);

      state = state.copyWith(isLoading: false, user: user);
      return true; 
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout(); 
    
    // BORRAMOS la memoria encriptada
    await ref.read(secureStorageProvider).borrarSesion();
    
    // Reiniciamos el estado, forzando a isCheckingAuth = false para que muestre el Login
    state = AuthState(isCheckingAuth: false); 
  }
}

// 4. El Provider principal
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});