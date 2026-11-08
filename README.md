# Solicitudes internas

Aplicación Flutter para gestionar solicitudes operativas de una organización: desde la creación por un empleado hasta la autorización, ejecución y validación del resultado.

## Alcance del Sprint 1

Casos de uso contemplados:

1. **Registro de usuario:** crear una cuenta con correo y contraseña; el perfil comienza con rol `empleado`.
2. **Inicio de sesión:** autenticar al usuario y dirigirlo según su rol.
3. **Consultar catálogo:** obtener áreas y servicios desde MockAPI.
4. **Crear solicitud:** seleccionar un servicio e ingresar la descripción de la necesidad.
5. **Asignar supervisor y sincronizar:** conservar la solicitud localmente y sincronizarla con Firestore cuando sea posible.

La base técnica ya incluye configuración de entorno, navegación con `go_router`, registro inicial de dependencias con `get_it` e inicialización de Firebase. **Los casos de uso anteriores describen el alcance funcional; no todos están implementados todavía.**

## Tecnologías

- Flutter y Dart
- Firebase Core; Firebase Authentication y Cloud Firestore se integrarán para los casos de uso correspondientes.
- MockAPI para el catálogo de áreas y servicios.
- `flutter_dotenv` para cargar la URL de MockAPI.
- `go_router` para navegación.
- `get_it` para inyección de dependencias.

## Requisitos

- Flutter SDK compatible con la versión indicada en `pubspec.yaml`.
- Git.
- Un dispositivo o emulador Android para ejecutar la configuración Firebase disponible.

## Clonar y ejecutar

```bash
git clone <URL_DEL_REPOSITORIO>
cd internal_request_app
```

Crea el archivo `.env` en la raíz del proyecto con:

```env
API_BASE_URL=https://6aef3c52b9925b27ce16c204.mockapi.io/api/v1
```

`.env` está excluido de Git; cada desarrollador debe crearlo localmente. La URL es configuración pública del catálogo, no debe usarse este archivo para guardar secretos.

Instala dependencias y ejecuta:

```bash
flutter pub get
flutter run
```

Para comprobar el análisis estático:

```bash
flutter analyze
```

## Inyección de dependencias y navegación

El punto de composición está en `lib/core/di/dependency_injection.dart`. `configureDependencies` registra `AppConfig` y `AppRouter` en GetIt; las dependencias futuras deben construirse allí y pasarse por constructor a los widgets o servicios que las necesiten.

Las rutas se definen en `lib/core/router/`. Actualmente muestran pantallas provisionales para validar la navegación; los controles de sesión y rol se agregarán al implementar autenticación.

## Firebase

La configuración generada por FlutterFire está incluida para Android. `main.dart` inicializa Firebase usando `DefaultFirebaseOptions`. Para agregar o configurar otras plataformas, ejecuta FlutterFire CLI desde la raíz del proyecto y selecciona las plataformas necesarias.

Las credenciales de Firebase Authentication no se guardan en Firestore. Antes de usar datos remotos, configura en Firebase Console los proveedores de acceso y reglas de Firestore apropiadas.