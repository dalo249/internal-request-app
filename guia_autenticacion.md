# Guía para agente de IA: Autenticación en Flutter (Firebase Auth) y paso a producción — Proyecto Movies

> **Propósito:** Instrucciones ejecutables, en orden, para agregar autenticación (email/password), cierre de sesión, Crashlytics, pruebas unitarias y build release a un proyecto Flutter existente llamado **Movies**.
> **Formato:** Cada paso indica archivo, acción, código y criterio de verificación.

---

## 0. Contexto y reglas del agente

### 0.1 Estado inicial del proyecto (NO se modifica)

El proyecto Movies ya:

- Consume una API HTTP mediante `MovieService` + `FutureBuilder`.
- Guarda `favoriteId` en `SharedPreferences`.
- Persiste `MovieNote` con Drift/SQLite (local) y Firestore (remoto) mediante `AppDatabase`, `MovieNoteLocalDataSource`, `MovieNoteRemoteDataSource` y `MovieNoteRepository`.
- Ya tiene Firebase inicializado (`Firebase.initializeApp`, `DefaultFirebaseOptions`) por el uso de Firestore.

### 0.2 Reglas obligatorias

1. **No reemplazar ni eliminar:** `MovieService`, `FutureBuilder`, `MovieNote`, `AppDatabase`, `MovieNoteRepository`.
2. **Nunca guardar contraseñas** en `SharedPreferences`, Drift ni Firestore. Firebase Authentication administra identidad y sesión.
3. **Trabajar por bloques:** implementar un bloque → ejecutar → verificar checkpoint → continuar. No pegar todos los archivos de una vez.
4. **Si un checkpoint falla, detenerse y corregir** antes de avanzar.
5. Hacer commit (o copia) del proyecto funcional antes de empezar.
6. Probar Crashlytics principalmente en **Android Emulator**.
7. Los plugins nativos (`firebase_auth`, `firebase_crashlytics`) **requieren reconstruir la app** (detener y volver a ejecutar `flutter run`). Hot Reload no basta.

### 0.3 Cambios previstos

| Pieza | Antes | Después |
|---|---|---|
| Catálogo | `MovieService` HTTP + `FutureBuilder` | Igual |
| Favorito | `favoriteId` + `SharedPreferences` | Igual |
| Notas | `MovieNote` + Drift + Firestore | Igual |
| Identidad | No existe sesión | Firebase Auth email/password |
| Entrada a la app | `MovieScreen` directa | `AuthGate` decide `LoginPage` o `MovieScreen` |
| Errores de producción | Consola/logs locales | `CrashService` + Crashlytics (Android) |
| Calidad | Prueba manual | Unit test mínimo + revisión manual |
| Entrega | `flutter run` | APK release; AAB como concepto de distribución |

### 0.4 Glosario mínimo

- **Autenticación:** ¿quién eres?
- **Autorización:** ¿qué puedes hacer?
- **Crashlytics:** ¿qué falló en manos del usuario?
- **Testing:** ¿qué puedo comprobar antes de entregar?
- **Release:** ¿qué artefacto se distribuye?

### 0.5 Checkpoint 0 — Punto de partida

Ejecutar el proyecto actual y comprobar: catálogo carga, detalle abre, favorito se guarda, una nota se guarda. **Si algo falla, corregirlo antes de continuar.**

### 0.6 Ruta de trabajo (resumen)

`Proyecto actual → firebase_auth → AuthValidators → AuthService → LoginPage → AuthGate → logout → autorización (concepto) → Crashlytics → CrashService → menú QA → tests → build release`

---

## 1. Preparar Firebase Authentication

### 1.1 Agregar dependencia

- **Dónde:** terminal, raíz del proyecto.

```bash
flutter pub add firebase_auth
```

> **Reconstruir:** detener la ejecución y volver a lanzar `flutter run`.

### 1.2 Habilitar Email/Password (manual, en consola web)

1. Firebase Console → proyecto que ya usa Firestore → **Authentication** (puede estar dentro de *Security*) → **Sign-in method**.
2. Habilitar **Email/Password** y guardar.
3. No habilitar Google/Apple (requieren configuración adicional).

> Con email/password la app envía credenciales a Firebase Authentication. Firestore no debe almacenar la contraseña.

**Checkpoint 1:** `flutter pub get` sin errores; la app se reconstruye y sigue funcionando; Email/Password aparece habilitado en consola.

---

## 2. Validadores independientes de la UI

- **Archivo nuevo:** `lib/validators/auth_validators.dart`
- **Acción:** crear funciones puras (sin Flutter ni Firebase) para correo y contraseña.
- **Convención:** en un `validator` de Flutter, retornar `null` = campo sin error.

```dart
class AuthValidators {
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'El correo es obligatorio';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }
    return null;
  }
}
```

**Por qué separarlo:** si la lógica estuviera dentro de `LoginPage`, probarla exigiría montar la pantalla. Aislada permite unit tests rápidos.

**Checkpoint 2:** el archivo compila.

---

## 3. `AuthService` (abstracción sobre FirebaseAuth)

La UI **no** debe usar `FirebaseAuth.instance` directamente.

- **Archivo nuevo:** `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Stream<User?> authStateChanges();
  Future<void> login({
    required String email,
    required String password,
  });
  Future<void> register({
    required String email,
    required String password,
  });
  Future<void> logout();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  Future<void> login({required String email, required String password}) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register({required String email, required String password}) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> logout() => _firebaseAuth.signOut();
}
```

**Checkpoint 3:** `AuthService` compila. **No modificar `main.dart` todavía.**

---

## 4. `LoginPage`

- **Archivo nuevo:** `lib/pages/login_page.dart`
- **Dos modos:** iniciar sesión y crear cuenta. Maneja validación, loading y mensajes amigables.
- El archivo completo es la concatenación en orden de 4.1 + 4.2 + 4.3 + 4.4 (todo dentro de la clase `_LoginPageState`; la llave final cierra la clase).

### 4.1 Estructura, controllers y estado

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../validators/auth_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
```

### 4.2 Método `_submit()`

```dart
  Future<void> _submit() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await widget.authService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      debugPrint('[Auth] FirebaseAuthException: ${error.code}');
      if (!mounted) return;
      setState(() => _errorMessage = _mapFirebaseError(error));
    } catch (error) {
      debugPrint('[Auth] Error inesperado: $error');
      if (!mounted) return;
      setState(() => _errorMessage = 'No fue posible completar la autenticación');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
```

> **Sobre `mounted`:** obligatorio porque hay `await`. El usuario podría salir de la pantalla mientras Firebase responde; no llamar `setState` en un `State` destruido.
> **No hay navegación manual tras login exitoso:** `AuthGate` reacciona al stream de sesión (ver sección 5).

### 4.3 Traducir errores técnicos

La UI no debe mostrar códigos crudos como `invalid-credential`.

```dart
  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo';
      case 'weak-password':
        return 'La contraseña no cumple la política requerida';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada';
      case 'operation-not-allowed':
        return 'El acceso con correo y contraseña no está habilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente más tarde';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return 'Las credenciales no coinciden';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet';
      default:
        return 'No fue posible completar la autenticación';
    }
  }
```

### 4.4 Interfaz (`build`)

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      autofocus: true,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthValidators.validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthValidators.validatePassword,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) _submit();
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegisterMode ? 'Registrarme' : 'Ingresar'),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              }),
                      child: Text(_isRegisterMode
                          ? 'Ya tengo cuenta'
                          : 'Crear una cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Checkpoint 4:** `LoginPage` compila (aún no es visible en la app).

---

## 5. Integración: `AuthService` + `AuthGate`

**Cadena de dependencias:** `main.dart` crea `AuthService` → `MyApp` lo recibe → `AuthGate` decide `LoginPage` o `MovieScreen` → `MovieScreen` conserva el servicio para cerrar sesión.

### 5.1 `MovieScreen` recibe `AuthService`

- **Archivo:** `lib/movie_screen.dart`

```dart
import 'services/auth_service.dart';

class MovieScreen extends StatefulWidget {
  final MovieNoteRepository noteRepository;
  final AuthService authService;

  const MovieScreen({
    super.key,
    required this.noteRepository,
    required this.authService,
  });

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}
```

### 5.2 Crear `AuthGate`

- **Archivo nuevo:** `lib/pages/auth_gate.dart`
- **Función:** escuchar `authStateChanges()` y entregar dependencias.

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../movie_screen.dart';
import '../repositories/movie_note_repository.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.noteRepository,
  });

  final AuthService authService;
  final MovieNoteRepository noteRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('No fue posible validar la sesión')),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginPage(authService: authService);
        }

        return MovieScreen(
          noteRepository: noteRepository,
          authService: authService,
        );
      },
    );
  }
}
```

### 5.3 `MyApp` recibe `AuthService`

```dart
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.noteRepository,
    required this.authService,
  });

  final MovieNoteRepository noteRepository;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movies',
      home: AuthGate(
        authService: authService,
        noteRepository: noteRepository,
      ),
    );
  }
}
```

### 5.4 Crear `AuthService` en `main.dart`

```dart
// Después de crear noteRepository como ya estaba:
final authService = FirebaseAuthService();
runApp(
  MyApp(
    noteRepository: noteRepository,
    authService: authService,
  ),
);
```

> **Hot Restart obligatorio:** detener y relanzar la app (o Hot Restart). Hot Reload no vuelve a ejecutar `main()`.

**Checkpoint 5:** al abrir la app aparece `LoginPage`. Registrar un usuario de prueba entra a `MovieScreen`. Cerrar y reabrir la app mantiene la sesión.

---

## 6. Cierre de sesión

- **Archivo:** `lib/movie_screen.dart`, dentro de `actions` del `AppBar`.

```dart
actions: [
  IconButton(
    tooltip: 'Cerrar sesión',
    onPressed: () async {
      await widget.authService.logout();
    },
    icon: const Icon(Icons.logout),
  ),
],
```

> **No navegar manualmente al login.** `signOut()` cambia el estado de Firebase Auth; `AuthGate` recibe el nuevo valor del stream y reconstruye la pantalla.

**Checkpoint 6:** al pulsar el icono de logout se vuelve a `LoginPage`. Iniciar sesión de nuevo regresa al catálogo.

---

## 7. Autorización (concepto — aislamiento de datos)

- **Autenticación:** Firebase Auth identifica al usuario y entrega un `User` con `uid` único.
- **Autorización:** comprobar que ese usuario solo lea/modifique sus propios datos.

### 7.1 Limitación actual

Las notas se envían a Firestore en una colección global: `movie_notes/{movieId}`. La ruta no contiene información del usuario: dos usuarios que guarden notas para la película `550` colisionan en el mismo documento remoto.

### 7.2 Estructura multiusuario ideal

```text
users/{uid}/movie_notes/{movieId}
```

### 7.3 Reglas de seguridad de Firestore (concepto)

```javascript
match /users/{userId}/movie_notes/{movieId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

> **Alcance:** esta sección es conceptual. **No migrar** la ruta de Firestore salvo que se solicite explícitamente. Si se implementa, el `uid` debe obtenerse del `User` autenticado (no de la UI) y propagarse a `MovieNoteRemoteDataSource`.

---

## 8. Instalar y validar Firebase Crashlytics

Crashlytics registra errores, versiones, dispositivos y stack traces en producción.

### 8.1 Dependencia

```bash
flutter pub add firebase_crashlytics
```

### 8.2 `minSdk` de Android

`firebase_crashlytics` requiere `minSdk` 24.

- **Archivo:** `android/app/build.gradle.kts`

```kotlin
defaultConfig {
    // ...
    minSdk = 24
}
```

### 8.3 Reconfigurar con FlutterFire CLI

Usar ejecución directa vía Dart para evitar problemas de PATH:

```bash
dart pub global run flutterfire_cli:flutterfire configure --project=<PROJECT_ID> --platforms=android
```

> Reemplazar `<PROJECT_ID>` por el ID real del proyecto Firebase.

### 8.4 Verificar plugins de Gradle

En `android/app/build.gradle.kts` deben aparecer:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}
```

**Checkpoint 8:** la app Android compila y se ejecuta tras reconstruir completamente.

---

## 9. `CrashService` con separación por plataforma

### 9.1 Estructura

```text
lib/services/crash/
  ├── crash_service.dart
  ├── firebase_crash_service.dart
  └── stub_crash_service.dart
```

### 9.2 `crash_service.dart` (export condicional)

```dart
export 'stub_crash_service.dart'
    if (dart.library.io) 'firebase_crash_service.dart';
```

> Ambos archivos definen una clase llamada `CrashService` con la misma API; el resto del código solo importa `crash_service.dart`.

### 9.3 `stub_crash_service.dart` (Web / entornos sin Crashlytics)

```dart
import 'package:flutter/foundation.dart';

class CrashService {
  const CrashService();

  Future<void> configure() async {
    debugPrint('[CrashService] Stub: sin Crashlytics');
  }

  Future<void> setUserIdentifier(String id) async {
    debugPrint('[CrashService] user=$id');
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    debugPrint('[CrashService] $reason:$error');
  }

  Future<void> simulateNonFatalError() async {
    try {
      throw StateError('Error no fatal de prueba');
    } catch (error, stackTrace) {
      await recordNonFatal(error, stackTrace, reason: 'Prueba QA');
    }
  }

  void simulateFatalCrash() {
    throw StateError('Crash fatal de prueba (stub)');
  }
}
```

### 9.4 `firebase_crash_service.dart` (implementación real móvil)

```dart
import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashService {
  const CrashService();

  Future<void> configure() async {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(true);

    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
      return true;
    };
  }

  Future<void> setUserIdentifier(String id) {
    return FirebaseCrashlytics.instance.setUserIdentifier(id);
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) {
    return FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  Future<void> simulateNonFatalError() async {
    try {
      throw StateError('Error no fatal de prueba');
    } catch (error, stackTrace) {
      await recordNonFatal(error, stackTrace, reason: 'Prueba QA');
    }
  }

  void simulateFatalCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
```

**Checkpoint 9:** ambos archivos compilan sin errores de import duplicado.

---

## 10. Conectar `CrashService` con `main.dart` y el usuario

### 10.1 Inicialización en `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final crashService = const CrashService();
  await crashService.configure();

  final database = AppDatabase();
  final local = MovieNoteLocalDataSource(database);
  final remote = MovieNoteRemoteDataSource(FirebaseFirestore.instance);
  final noteRepository = MovieNoteRepository(local: local, remote: remote);
  final authService = FirebaseAuthService();

  runApp(
    MyApp(
      noteRepository: noteRepository,
      authService: authService,
      crashService: crashService,
    ),
  );
}
```

> Importar `services/crash/crash_service.dart` en `main.dart`.

### 10.2 Propagar `crashService` por constructores

Agregar el campo `final CrashService crashService;` (como `required`) a `MyApp`, `AuthGate` y `MovieScreen`, y pasarlo en cadena: `MyApp → AuthGate → MovieScreen`.

En `AuthGate`, al detectar usuario autenticado, vincular el identificador técnico (solo `uid`, nunca correo ni contraseña):

```dart
final user = snapshot.data;
if (user != null) {
  unawaited(crashService.setUserIdentifier(user.uid));
  return MovieScreen(
    noteRepository: noteRepository,
    authService: authService,
    crashService: crashService,
  );
}
```

> `unawaited` requiere `import 'dart:async';` en `auth_gate.dart`. Mantener el caso `user == null` retornando `LoginPage(authService: authService)`.

**Checkpoint 10:** la app compila y arranca; con sesión iniciada, el flujo Movies funciona igual que antes.

---

## 11. Menú QA temporal (solo debug)

- **Archivo:** `lib/movie_screen.dart`
- **Condición:** visible únicamente con `kDebugMode`.

```dart
import 'package:flutter/foundation.dart';
import 'services/crash/crash_service.dart';

// Dentro de las actions del AppBar:
if (kDebugMode)
  PopupMenuButton<String>(
    tooltip: 'QA',
    onSelected: (value) async {
      if (value == 'non-fatal') {
        await widget.crashService.simulateNonFatalError();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error no fatal registrado')),
        );
      }
      if (value == 'fatal') {
        widget.crashService.simulateFatalCrash();
      }
    },
    itemBuilder: () => const [
      PopupMenuItem(
        value: 'non-fatal',
        child: Text('Registrar no fatal'),
      ),
      PopupMenuItem(
        value: 'fatal',
        child: Text('Forzar crash fatal'),
      ),
    ],
  ),
```

**Checkpoint 11:**

1. En Android Emulator, abrir el menú QA → *Registrar no fatal* → aparece el SnackBar.
2. *Forzar crash fatal* cierra la app; reabrirla para que Crashlytics envíe el reporte.
3. Verificar en Firebase Console → Crashlytics (puede tardar unos minutos en aparecer).

---

## 12. Testing antes del release

- **Archivo nuevo:** `test/auth_validators_test.dart`
- **Reemplazar `TU_PAQUETE`** por el nombre del paquete definido en `pubspec.yaml` (`name:`).

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:TU_PAQUETE/validators/auth_validators.dart';

void main() {
  group('AuthValidators.validateEmail', () {
    test('retorna error si el correo está vacío', () {
      expect(
        AuthValidators.validateEmail(''),
        'El correo es obligatorio',
      );
    });
    test('retorna null si el correo es válido', () {
      expect(
        AuthValidators.validateEmail('estudiante@demo.com'),
        isNull,
      );
    });
  });

  group('AuthValidators.validatePassword', () {
    test('retorna error si la contraseña es corta', () {
      expect(
        AuthValidators.validatePassword('123'),
        'La contraseña debe tener mínimo 6 caracteres',
      );
    });
    test('retorna null si cumple el mínimo', () {
      expect(AuthValidators.validatePassword('123456'), isNull);
    });
  });
}
```

```bash
flutter test
```

**Checkpoint 12:** las 4 pruebas pasan.

---

## 13. Build de Android (release)

1. Revisar versión en `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

2. Análisis estático y pruebas:

```bash
flutter analyze
flutter test
```

3. Generar APK release:

```bash
flutter build apk --release
```

- **Artefacto:** `build/app/outputs/flutter-apk/app-release.apk`
- **AAB:** concepto de distribución (Play Store); en esta práctica el entregable es el APK.

**Checkpoint 13:** `flutter analyze` sin errores, tests en verde, APK generado e instalable.

---

## 14. Checklist final para el agente

- [ ] Proyecto base funcionaba antes de empezar (Checkpoint 0).
- [ ] `firebase_auth` y `firebase_crashlytics` agregados; app reconstruida.
- [ ] Email/Password habilitado en Firebase Console.
- [ ] `AuthValidators`, `AuthService`/`FirebaseAuthService`, `LoginPage`, `AuthGate` creados.
- [ ] `MovieScreen`, `MyApp` y `main.dart` reciben `AuthService` y `CrashService`.
- [ ] Logout funciona y vuelve al login sin navegación manual.
- [ ] Ninguna contraseña se guarda en `SharedPreferences`, Drift ni Firestore.
- [ ] `minSdk = 24`, plugins de Gradle y `flutterfire configure` correctos.
- [ ] Menú QA solo bajo `kDebugMode`.
- [ ] Unit tests de validadores pasan.
- [ ] `flutter analyze`, `flutter test` y `flutter build apk --release` exitosos.
- [ ] Catálogo, favorito y notas siguen funcionando como antes.

## 15. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| `MissingPluginException` al usar Auth/Crashlytics | Plugin nativo agregado con Hot Reload | Detener y ejecutar `flutter run` de nuevo |
| La app no muestra `LoginPage` | `main.dart` sin `AuthService` o solo Hot Reload | Hot Restart / relanzar |
| `operation-not-allowed` | Email/Password no habilitado | Habilitarlo en Firebase Console |
| Falla build Android con Crashlytics | `minSdk` < 24 o plugins de Gradle ausentes | Revisar secciones 8.2 y 8.4 |
| `flutterfire` no se encuentra | PATH global de Dart | Usar `dart pub global run flutterfire_cli:flutterfire configure ...` |
| `unawaited` no definido | Falta `import 'dart:async';` | Agregar el import |
| Test no encuentra el paquete | `TU_PAQUETE` sin reemplazar | Usar el `name` de `pubspec.yaml` |
| Crash no aparece en consola | Reporte aún no enviado | Reabrir la app tras el crash y esperar unos minutos |