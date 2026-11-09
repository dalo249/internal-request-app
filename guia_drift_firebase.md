# Guía de implementación: Movies con Drift + Firebase

**Curso:** Desarrollo Móvil · Movies · Drift + Firebase
**Tipo:** Guía de implementación para estudiantes

**Objetivo.** Continuar sobre el mismo proyecto Movies y cambiar únicamente la persistencia de `MovieNote`: primero Drift/SQLite como fuente local y, después, Firestore como sincronización remota.

**Ruta de trabajo.** Proyecto actual → dependencias → proyecto Firebase → FlutterFire → Drift → Repository → UI → Firestore → offline-first → Sync → pruebas.

---

## 0. Antes de comenzar

Esta guía no empieza una aplicación nueva. El catálogo continúa usando `MovieService`/`FutureBuilder` y `favoriteId` continúa en `SharedPreferences`. La práctica se concentra en la nota de cada película (`MovieNote`).

- Trabaja con Android Emulator. La configuración Firebase incluida en este flujo es para Android.
- No borres `movie_notes.json` si viene de la clase anterior. Queda como referencia del enfoque File/JSON.
- Cuando Drift quede conectado, las notas nuevas se leerán y escribirán desde SQLite.
- Firestore no reemplaza a Drift: será la copia remota que intentaremos sincronizar.

**Idea de arquitectura.** La pantalla no debería saber si una nota vive en JSON, SQLite o Firestore. La UI pide "guardar/leer una nota" y las capas de datos resuelven cómo hacerlo.

### 0.1 Versiones usadas en el proyecto base

En el proyecto entregado, el SDK y las dependencias quedaron alineados así. Mantener estas versiones evita el conflicto que puede aparecer si `drift` y `drift_dev` pertenecen a familias diferentes.

```yaml
environment:
  sdk: ^3.11.5

dependencies:
  drift: ^2.34.0
  path: ^1.9.1
  path_provider: ^2.1.6
  firebase_core: ^4.15.0
  cloud_firestore: ^6.10.0

dev_dependencies:
  drift_dev: ^2.34.0
  build_runner: ^2.4.15
```

**Qué debes notar.** `drift` es la librería que usa la app en ejecución. `drift_dev` y `build_runner` se usan durante el desarrollo para generar `app_database.g.dart`. Por eso estos dos últimos aparecen en `dev_dependencies`.

```bash
flutter pub get
```

**Comprueba antes de seguir.** El proyecto debe resolver dependencias sin errores y seguir compilando antes de agregar código nuevo.

---

## 1. Configurar Firebase y FlutterFire

En este bloque primero se crea o selecciona el proyecto Firebase que usará la práctica. Después FlutterFire relaciona la app Flutter con ese proyecto y genera `lib/firebase_options.dart`, archivo que `Firebase.initializeApp` utilizará más adelante.

### 1.1 Firebase CLI

```bash
firebase --version
firebase login
firebase projects:list
```

**Qué hace cada comando.**
- `firebase --version` confirma que la CLI está instalada.
- `firebase login` autentica la máquina.
- `firebase projects:list` muestra los proyectos que ya existen para esa cuenta.

Si todavía no tienes un proyecto para la práctica, créalo en el siguiente paso.

**Importante.** Para este flujo no necesitas `firebase init`. Lo que necesitamos en Flutter es configurar la app con FlutterFire CLI.

### 1.2 Crear el proyecto en Firebase

Antes de ejecutar FlutterFire Configure debe existir un proyecto Firebase que la aplicación pueda usar. Si todavía no tienes uno, créalo desde Firebase Console:

1. Abre Firebase Console e inicia sesión con la misma cuenta que usarás en Firebase CLI.
2. Selecciona "Agregar proyecto" (Add project).
3. Escribe un nombre para el proyecto y continúa con el asistente.
4. Google Analytics es opcional para esta práctica; puedes dejarlo desactivado si no lo necesitas.
5. Cuando el proyecto termine de crearse, entra a Configuración del proyecto (Project settings) → General, ubica el Project ID y, si quieres verificarlo desde terminal, vuelve a ejecutar `firebase projects:list`.

**Importante.** El comando de FlutterFire usa el Project ID, no solamente el nombre visible del proyecto. Ejemplo: si el ID es `movies-clase10-12345`, ese es el valor que reemplaza `<PROJECT_ID>`.

Project ID de ejemplo: `movies-clase10-12345`

**Qué consigues en este paso.** Ahora existe un proyecto Firebase concreto. Guarda su Project ID: lo usarás en el comando de FlutterFire del siguiente paso. Todavía no hemos creado Firestore.

### 1.3 FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

En Windows puede ocurrir que `flutterfire configure` no sea reconocido aunque la CLI sí esté instalada. Para evitar depender del PATH, usa directamente:

```bash
dart pub global run flutterfire_cli:flutterfire configure --project=<PROJECT_ID> --platforms=android
```

**Resultado esperado.** Al terminar debe existir `lib/firebase_options.dart` y debe incluir una configuración para Android. No edites ese archivo manualmente.

### 1.4 Crear Firestore en el mismo proyecto

El proyecto Firebase ya existe y FlutterFire ya dejó la app asociada a él, pero todavía falta crear la base de Cloud Firestore. FlutterFire no crea por sí solo esa base. En Firebase Console:

1. Abre el mismo proyecto usado en FlutterFire.
2. Entra a Firestore Database y crea la base.
3. Para la práctica de clase usa Test mode de forma temporal.
4. No crees manualmente la colección `movie_notes`: la primera escritura con `.set()` la creará.

**Por qué debe ser el mismo proyecto.** `firebase_options.dart` apunta a un `projectId` concreto. `FirebaseFirestore.instance` trabajará con Firestore de ese proyecto una vez Firebase haya sido inicializado.

**Antes de continuar.** Debe existir `firebase_options.dart` y Firestore debe estar habilitado. Si Firestore está en reglas que bloquean la escritura, la app puede mostrar `permission-denied` aunque la conexión Firebase sea correcta.

---

## 2. Definir la tabla MovieNotes en Drift

Crea `lib/local/movie_notes_table.dart`. La tabla representa el mismo dato que ya conocíamos como `MovieNote`, pero ahora en una estructura consultable de SQLite.

```dart
import 'package:drift/drift.dart';

@DataClassName('MovieNoteRow')
class MovieNotes extends Table {
  IntColumn get movieId => integer()();
  TextColumn get note => text()();
  IntColumn get rating => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {movieId};
}
```

**MovieNote vs MovieNoteRow.** `MovieNote` sigue siendo el modelo de la aplicación. `MovieNoteRow` será una clase generada por Drift para representar una fila de la tabla. Separarlos evita que la UI quede acoplada a Drift.

**movieId como primary key.** En esta práctica existe una nota por película. La clave primaria impide que tengamos dos filas diferentes con el mismo `movieId`.

**pendingSync.** No es parte del comentario escrito por el usuario. Es metadata local: `true` indica que ese cambio todavía debe enviarse correctamente al remoto.

---

## 3. Crear AppDatabase y movies.sqlite

Crea `lib/local/app_database.dart`. Esta clase registra las tablas de Drift y define dónde se abrirá la base SQLite.

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'movie_notes_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [MovieNotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'movies.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

**¿Para qué sirve `part`?** `part 'app_database.g.dart'` conecta este archivo con el código que Drift genera. `_$AppDatabase` no lo escribimos nosotros; aparecerá dentro del `.g.dart` después de ejecutar `build_runner`.

**schemaVersion = 1.** Es la primera versión del esquema de esta base. Si en el futuro cambia la estructura de tablas, esta versión participa en las migraciones. No es la versión 1.0.0 de la app.

**¿Dónde aparece movies.sqlite?** No se crea dentro de `lib/`. `getApplicationDocumentsDirectory()` obtiene una carpeta válida de la aplicación y allí se abre el archivo SQLite.

### 3.1 Generar el código de Drift

Drift genera clases auxiliares a partir de la tabla y la base que acabamos de declarar.

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Qué debe aparecer.** `lib/local/app_database.g.dart`. No lo edites manualmente: si cambias una tabla, modifica el archivo fuente y vuelve a ejecutar el generador.

**Si la generación queda inconsistente.** Prueba:

```bash
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

---

## 4. Crear MovieNoteLocalDataSource

Esta clase concentra las operaciones de Drift relacionadas con las notas. `MovieDetailPage` no necesita conocer queries, tablas ni `MovieNoteRow`.

```dart
import 'package:drift/drift.dart';

import '../models/movie_note.dart';
import 'app_database.dart';

class MovieNoteLocalDataSource {
  final AppDatabase db;

  MovieNoteLocalDataSource(this.db);

  MovieNote _toDomain(MovieNoteRow row) {
    return MovieNote(
      movieId: row.movieId,
      note: row.note,
      rating: row.rating,
      updatedAt: row.updatedAt,
    );
  }

  Future<MovieNote?> getNoteForMovie(int movieId) async {
    final query = db.select(db.movieNotes)
      ..where((t) => t.movieId.equals(movieId));

    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> saveNote(MovieNote note) async {
    await db.into(db.movieNotes).insertOnConflictUpdate(
      MovieNotesCompanion.insert(
        movieId: Value(note.movieId),
        note: note.note,
        rating: note.rating,
        updatedAt: note.updatedAt,
        pendingSync: const Value(true),
      ),
    );
  }
}
```

**¿Por qué `..where`?** Es el cascade operator de Dart. Se crea una consulta sobre `db.movieNotes` y luego se agrega la condición WHERE sobre ese mismo objeto de consulta.

**getSingleOrNull().** Tiene sentido porque `movieId` es primary key: esperamos como máximo una fila. Si nunca se ha guardado una nota para esa película, retorna `null`.

**insertOnConflictUpdate.** Es un upsert: inserta si la clave no existe y actualiza la fila si el `movieId` ya está guardado.

**MovieNotesCompanion.** Es una clase generada por Drift. Sirve para preparar valores de una inserción/actualización. No es un segundo insert.

**pendingSync vuelve a true.** Si una nota que ya estaba sincronizada se edita, vuelve a existir un cambio local pendiente. Por eso lo enviamos explícitamente como `true` al guardar.

### 4.1 Operaciones para sincronización

Además de leer y guardar una nota, necesitamos saber qué cambios todavía no han llegado al remoto y marcar los que sí se sincronizaron.

```dart
Future<List<MovieNote>> getPendingNotes() async {
  final rows = await (db.select(db.movieNotes)
        ..where((t) => t.pendingSync.equals(true)))
      .get();

  return rows.map(_toDomain).toList();
}

Future<void> markSynced(int movieId) async {
  await (db.update(db.movieNotes)
        ..where((t) => t.movieId.equals(movieId)))
      .write(
    const MovieNotesCompanion(
      pendingSync: Value(false),
    ),
  );
}
```

**getPendingNotes().** Devuelve `Future<List<MovieNote>>` con únicamente las notas cuyo `pendingSync` sigue en `true`. Las filas `MovieNoteRow` se convierten a `MovieNote` antes de salir del LocalDataSource.

**markSynced().** Solo cambia `pendingSync` a `false` para una película concreta. Debe llamarse después de confirmar que la escritura remota terminó correctamente.

| Método | Responsabilidad |
|---|---|
| `getNoteForMovie` | Recuperar una nota por `movieId`. |
| `saveNote` | Insertar/actualizar localmente y dejar pendiente. |
| `getPendingNotes` | Obtener el trabajo que falta enviar. |
| `markSynced` | Confirmar localmente que el remoto respondió bien. |

---

## 5. Crear un Repository local primero

El Repository es la frontera que usará la UI. Primero lo conectamos solo con lo local para poder comprobar Drift antes de agregar Firebase.

```dart
import '../local/movie_note_local_data_source.dart';
import '../models/movie_note.dart';

class MovieNoteRepository {
  final MovieNoteLocalDataSource local;

  MovieNoteRepository({required this.local});

  Future<MovieNote?> getNoteForMovie(int movieId) =>
      local.getNoteForMovie(movieId);

  Future<void> saveNote(MovieNote note) =>
      local.saveNote(note);
}
```

**Por qué parece una capa "extra".** Al principio solo delega. Su utilidad aparece después, cuando coordina Drift y Firestore sin obligar a `MovieDetailPage` a cambiar nuevamente.

---

## 6. Pasar el Repository hasta MovieDetailPage

Las dependencias se crean arriba y se entregan por constructor. El recorrido será: `main` → `MyApp` → `MovieScreen` → `MovieDetailPage`.

### 6.1 main.dart: crear dependencias locales

```dart
final database = AppDatabase();
final local = MovieNoteLocalDataSource(database);
final noteRepository = MovieNoteRepository(local: local);

runApp(MyApp(noteRepository: noteRepository));
```

**Qué ocurre aquí.** `AppDatabase` abre la infraestructura local; `LocalDataSource` conoce Drift; `Repository` ofrece un contrato más estable para la UI. Se crean una vez en la composición principal.

### 6.2 MyApp

```dart
class MyApp extends StatelessWidget {
  final MovieNoteRepository noteRepository;

  const MyApp({
    super.key,
    required this.noteRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MovieScreen(noteRepository: noteRepository),
    );
  }
}
```

**Por qué MyApp lo recibe.** `MyApp` no guarda notas por sí mismo; simplemente forma parte del camino por el que la dependencia llega a `MovieScreen`. En proyectos grandes esto puede resolverse con otras técnicas de inyección, pero aquí lo hacemos explícito.

### 6.3 MovieScreen

```dart
class MovieScreen extends StatefulWidget {
  final MovieNoteRepository noteRepository;

  const MovieScreen({
    super.key,
    required this.noteRepository,
  });

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}
```

Cuando abras el detalle, pasa el mismo Repository:

```dart
MovieDetailPage(
  movie: movie,
  noteRepository: widget.noteRepository,
)
```

**Por qué aparece `widget.noteRepository`.** Ese código vive dentro de `_MovieScreenState`. Las propiedades declaradas en `MovieScreen` se consultan desde su `State` mediante `widget`.

### 6.4 MovieDetailPage

```dart
class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  final MovieNoteRepository noteRepository;

  const MovieDetailPage({
    super.key,
    required this.movie,
    required this.noteRepository,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}
```

En los métodos de cargar y guardar que ya tienes, cambia únicamente el acceso al almacenamiento:

```dart
final saved = await widget.noteRepository
    .getNoteForMovie(widget.movie.id);

await widget.noteRepository.saveNote(note);
```

**Qué no debería cambiar.** `TextField`, rating, `initState`, `mounted`, `dispose`, `Navigator` y el diseño general de la pantalla no necesitan saber que JSON fue reemplazado por Drift.

---

## 7. Checkpoint: Drift debe funcionar sin Firebase

No continúes con Firestore hasta comprobar este flujo. Si falla aquí, el problema está en la ruta local y mezclar Firebase solo hace más difícil diagnosticarlo.

1. Guarda una nota y rating en una película.
2. Abre otra película: no debe heredar la nota anterior.
3. Vuelve a la primera: debe recuperar su nota.
4. Cierra completamente la app y vuelve a abrirla.
5. Confirma que la nota sigue disponible.
6. Confirma que `favoriteId` y el catálogo siguen funcionando como antes.

**Desde este punto.** Drift/SQLite es la fuente local activa de `MovieNote`. El archivo JSON anterior puede seguir existiendo, pero ya no participa en este flujo.

---

## 8. Crear el RemoteDataSource de Firestore

Crea `lib/remote/movie_note_remote_data_source.dart`. Esta clase conoce Firestore; la UI y el LocalDataSource no necesitan importarlo.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/movie_note.dart';

class MovieNoteRemoteDataSource {
  final FirebaseFirestore firestore;

  MovieNoteRemoteDataSource(this.firestore);

  Future<void> upsertNote(MovieNote note) async {
    await firestore
        .collection('movie_notes')
        .doc(note.movieId.toString())
        .set(note.toJson());
  }
}
```

**collection('movie_notes').** Selecciona la colección remota. No es necesario crearla manualmente: aparecerá con la primera escritura.

**doc(movieId).** La misma película usa siempre el mismo ID de documento. Esto facilita reintentos sin crear un documento nuevo en cada sincronización.

**set(...).** Si el documento no existe, lo crea; si ya existe con ese ID, vuelve a escribirlo. En esta práctica usamos este comportamiento como upsert remoto.

**toJson().** Convierte `MovieNote` a un `Map` serializable. `toJson` prepara los datos; quien realmente los envía es el `RemoteDataSource`.

---

## 9. Convertir el Repository en offline-first

Ahora el Repository coordina dos fuentes. La decisión importante es el orden: guardar localmente primero y tratar la escritura remota como una sincronización posterior.

### 9.1 Agregar la dependencia remota

```dart
final MovieNoteLocalDataSource local;
final MovieNoteRemoteDataSource? remote;

MovieNoteRepository({
  required this.local,
  this.remote,
});
```

**Por qué `remote` puede ser null.** Permite que el Repository funcione solo con Drift. Esto resulta útil para probar la ruta local antes de encender Firebase.

### 9.2 Guardar: local primero, remoto después

```dart
Future<void> saveNote(MovieNote note) async {
  await local.saveNote(note);

  final remoteSource = remote;
  if (remoteSource == null) return;

  try {
    await remoteSource.upsertNote(note);
    await local.markSynced(note.movieId);
  } catch (_) {
    // La nota ya quedó local y seguirá pendiente.
  }
}
```

**Qué pasa si Firebase falla.** La nota no se borra porque `local.saveNote` ya terminó. `pendingSync` se mantiene en `true` y puede reintentarse más tarde.

**Qué pasa si ya existía el documento remoto.** `set()` sobre el mismo `doc(movieId)` no produce un error por "ya existe"; actualiza ese mismo documento. El `catch` se ejecuta si una operación dentro del `try` lanza una excepción.

### 9.3 Reintentar pendientes

```dart
Future<void> syncPending() async {
  final remoteSource = remote;
  if (remoteSource == null) return;

  final pending = await local.getPendingNotes();

  for (final note in pending) {
    try {
      await remoteSource.upsertNote(note);
      await local.markSynced(note.movieId);
    } catch (_) {
      // Esa nota queda pendiente para otro intento.
    }
  }
}
```

**Qué recorre este método.** No vuelve a crear notas. Lee únicamente las que Drift marcó como pendientes, intenta enviarlas una por una y confirma cada una de forma independiente.

**Offline-first en esta práctica.** No significa simplemente "usar SQLite". La evidencia está en el flujo: la operación principal guarda localmente antes de depender de Firestore.

---

## 10. Inicializar Firebase en main.dart

Firebase debe inicializarse antes de pedir `FirebaseFirestore.instance`. Por eso `main` pasa a ser `async` y `Firebase.initializeApp` ocurre antes de `runApp`.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final database = AppDatabase();
  final local = MovieNoteLocalDataSource(database);
  final remote = MovieNoteRemoteDataSource(
    FirebaseFirestore.instance,
  );

  final noteRepository = MovieNoteRepository(
    local: local,
    remote: remote,
  );

  runApp(MyApp(noteRepository: noteRepository));
}
```

**¿Dónde se "pasa" el Firestore creado?** No se escribe una URL de Firestore. `firebase_options.dart` identifica el proyecto; `Firebase.initializeApp` conecta la app con ese proyecto; `FirebaseFirestore.instance` entrega la instancia de Firestore de ese proyecto.

**WidgetsFlutterBinding.ensureInitialized().** Garantiza que Flutter esté inicializado antes de ejecutar plugins de forma asíncrona antes de `runApp`.

---

## 11. Agregar un botón Sync mínimo

En `MovieScreen` agrega un botón dentro de `AppBar` → `actions`. El botón solo dispara el reintento; la lógica permanece en el Repository.

```dart
appBar: AppBar(
  title: const Text('Mis películas'),
  centerTitle: true,
  actions: [
    IconButton(
      tooltip: 'Sincronizar notas',
      icon: const Icon(Icons.sync),
      onPressed: () async {
        await widget.noteRepository.syncPending();
      },
    ),
  ],
),
```

**Por qué está en MovieScreen.** Es una acción general de sincronización y no necesita estar dentro de cada detalle. La pantalla solo pide "sincronizar pendientes"; no conoce las consultas ni Firestore.

---

## 12. Pruebas finales

| Prueba | Acción | Resultado esperado |
|---|---|---|
| Local | Guardar una nota, cerrar y abrir la app | La nota vuelve desde Drift. |
| Remoto | Guardar con Firestore disponible | Aparece/actualiza `movie_notes/{movieId}`. |
| Fallo remoto | Forzar temporalmente una excepción en `upsertNote` | La nota sigue local y queda `pendingSync=true`. |
| Retry | Quitar la excepción y tocar Sync | Se envía y luego `pendingSync` pasa a `false`. |
| Favorito | Cambiar `favoriteId` y reiniciar | Sigue usando `SharedPreferences`. |
| Catálogo | Abrir la pantalla con red | Sigue usando `MovieService`/`FutureBuilder`. |

Para una demostración controlada del fallo remoto, puedes colocar temporalmente al inicio de `upsertNote`:

```dart
throw Exception('Fallo remoto simulado para clase');
```

Después de comprobar el comportamiento, retira esa línea antes de continuar.

---

## 13. Problemas frecuentes

| Problema | Qué revisar primero |
|---|---|
| `flutterfire` no se reconoce | Usa `dart pub global run flutterfire_cli:flutterfire configure ...` |
| `firebase_options.dart` no aparece | Ejecuta FlutterFire desde la raíz del proyecto, verifica que el proyecto Firebase exista y usa su Project ID correcto en `--project`, además de `--platforms=android`. |
| `app_database.g.dart` no aparece | Revisa `part`, `@DriftDatabase` y ejecuta `build_runner`. |
| Conflicto `drift`/`drift_dev` | Mantén `drift` y `drift_dev` en la misma familia (proyecto base: 2.34.0). |
| `permission-denied` en Firestore | Verifica que Firestore exista y que las reglas de la práctica permitan la escritura. |
| La nota no vuelve al abrir | Revisa `getNoteForMovie`, `movieId` y la conexión a `AppDatabase`. |
| Todo queda pending | Verifica que `markSynced` ocurra solo después de `upsertNote` exitoso. |
| Se está ejecutando Chrome | Usa `flutter devices` y ejecuta el Android Emulator. |

---

## 14. Qué debes poder explicar al terminar

- Por qué `favoriteId` sigue en `SharedPreferences` y `MovieNote` pasa a Drift.
- La diferencia entre `MovieNote`, `MovieNoteRow` y `MovieNotesCompanion`.
- Para qué sirve `part 'app_database.g.dart'` y por qué el archivo generado no se edita.
- Por qué `getNoteForMovie` consulta por `movieId` en vez de leer una colección completa.
- Qué significa `pendingSync` y cuándo cambia de `true` a `false`.
- Por qué el Repository guarda localmente antes de intentar Firestore.
- Qué genera `flutterfire configure` y qué se crea manualmente en Firebase Console.
- Por qué `doc(movieId).set(...)` permite reintentar sin crear un documento nuevo por cada intento.

**Flujo final.** UI → `MovieNoteRepository` → Drift/SQLite. Si hay remoto: Repository → Firestore → `markSynced(false)`. La UI conserva el mismo contrato aunque cambie la infraestructura.