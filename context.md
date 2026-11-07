GLOSARIO

Areas:
departamento que se encarga de solucionar solicitudes enfocadas a un tema especifico (logística, infraestructura, equipos tecnológicos físico o digital)

- Servicios: tarea especifica perteneciente a un area que debe resolverse

- Ejecutores técnicos: Empleados que pertenecen  a un area y se encargan de resolver solicitudes de los servicios del area



AREAS:
Tecnología: garantiza buen estado y distribución de herramientas digitales y equipos físicos de computo
Servicios
Soporte de computo: Solución de fallos digitales o de hardware de un equipo
Mantenimiento de equipos: Revision periodica o ajustes preventivos (Limpieza, evitar calentamiento, liberar memoria)
Cambio de equipo: sustitución de equipos físicos de trabajo o entrega de equipo nuevo (laptops, cargadores quemados, monitores, teclados o ratones). 
Gestion de acceso y cuentas: creación o restauración de correos corporativos, asignación de licencias de software(Microsoft, Claude), restablecer contraseña del equipo o red.

Infraestructura: se encarga de mantener en buen estado la planta física. Reparación y mantenimiento de oficinas e inmobiliario
Servicios
Reparación de espacios y mobiliario: Arreglo o ajuste de sillas ergonómicas, chapas de puertas, pintura de paredes o luminarias fundidas.
Mantenimiento de equipos: Atención a fallas en aire acondicionado, dispensadores de agua, proyectores.

Logistica: Se encarga de la organización de espacios compartidos, traslado de bienes y soporte operativo para eventos o jornadas de trabajo.
Servicios
Logistica de evento y reuniones: Reserva formal de salas de juntas, montaje de proyectores/sonido y gestión de alimentación para reuniones
Traslados y Mensajería Interna: Movimiento de cajas, envió de documentos entre sedes


Resumen Ejecutivo y Propósito del Negocio
Se construira una aplicación corporativa diseñada para gestionar de forma ordenada y trazable las necesidades operativas e internas que surgen en una organización (agrupadas en áreas de Tecnología, Infraestructura y Logística).

El objetivo principal de la plataforma es digitalizar el ciclo de vida completo de una solicitud: desde que un Empleado identifica una necesidad basándose en un catálogo de servicios, pasa por la Autorización y Asignación de un Supervisor, hasta la Ejecución Técnica y posterior Validación y Cierre, garantizando trazabilidad, control de cargas de trabajo y plazos de entrega.

Definición de Actores y Roles
El sistema interactúa con tres perfiles o actores bien diferenciados:

Empleado (Solicitante): Pertenece a un área de la empresa. Es el encargado de consultar el catálogo de servicios, crear solicitudes detalladas, realizar seguimiento a sus estados y cancelar la petición únicamente si se encuentra en estado inicial (SOLICITADA).

Supervisor (Aprobador / Validador): Es el responsable de coordinar el área. Evalúa las solicitudes entrantes, las aprueba (o rechaza con motivo), define la prioridad, establece la fecha límite y asigna un Responsable Ejecutor perteneciente al área técnica competente. Al final, valida el resultado del trabajo para cerrar la solicitud o devolverla si presenta fallas.

Nota: Todos los supervisores deben pertenecer al area central "Administracion", de esta manera puede recibir aprobar o rechazar solicitudes creadas por empleados de cualquier departamento (Tecnología, Logística, Infraestructura, administracion). Así mismo asignar ejecutores de las diferentes areas para cada solicitud.

Responsable Ejecutor (Operativo): Es el técnico o especialista asignado a una labor. Consulta sus tareas pendientes, las acepta, registra incrementalmente el porcentaje de avance (de 0% a 100%) y entrega la descripción del resultado final para su validación.

Catálogo de Servicios (Estructura de Oferta Interna)
El sistema opera sobre un catálogo organizado en tres áreas funcionales clave:

Área de Tecnología (TI): Soporte de cómputo, mantenimiento preventivo de equipos, cambio/reemplazo de hardware y gestión de accesos/cuentas.
Área de Mantenimiento e Infraestructura: Reparación de espacios físicos y mobiliario, y atención a fallas en equipos de instalaciones (aires acondicionados, dispensadores, etc.).
Área de Administración y Logística: Logística de eventos/reuniones y traslados o mensajería interna.





CASOS DE USO:

Registrar usuario con asignación rol de empleado
iniciar sesion
Crear Solicitud (Empleado).
Autorizar y Asignar a responsable ejecutor (Supervisor).
Registrar Avance y Entregar (Ejecutor).
Validar y Cerrar o Devolver (Supervisor).



CASO DE USO 1: Registro de usuario con asignación de rol "empleado"

Descripción: Permite a una persona registrarse por sí mismo en el sistema corporativo introduciendo sus credenciales seguras y datos de perfil. El sistema le asigna estricta y automáticamente el rol básico del dominio ("empleado") para garantizar control de acceso a funcionalidades generales desde el primer momento

Nota: El rol de un usuario se puede cambiar desde firestore console manualmente, únicamente cuando ya el usuario este registrado, en este caso con el rol asignado de base "empleado".

Actores:
Actor Principal: Usuario (Nuevo Empleado)
Firebase Authentication: Gestor de credenciales y seguridad.
Cloud Firestore: Base de datos NoSQL para el almacenamiento del usuario con (uid, nombre, correo (de las credenciales), rol, areaId )

Precondiciones:
El correo electrónico ingresado no debe estar registrado previamente en el sistema.
La contraseña debe tener mínimo 6 caracteres
El dispositivo debe tener conexión internet

Flujo Principal (Camino Feliz):
El usuario accede a la pantalla de registro (Sign Up) de la aplicación.
El usuario ingresa su Nombre, Correo electrónico y Contraseña en los campos correspondientes.
El usuario presiona el botón de "Registrarse".
El sistema valida que los campos no estén vacíos y deshabilita temporalmente el botón para evitar envíos múltiples.
El sistema envía las credenciales de correo y contraseña a Firebase Authentication.
Firebase Auth cifra la contraseña, crea la cuenta y devuelve un identificador único e irrepetible (uid) a la aplicación.
El sistema toma el uid y realiza un registro (escritura) en la colección usuarios de Cloud Firestore, usando dicho uid como la llave primaria (id) del documento.
El sistema para crear a entidad del usuario: asigna de forma automática y obligatoria el rol básico del dominio (rol: "empleado") y el área predeterminada (area_id: "general"), agregando además el nombre y el correo.
El sistema reactiva el botón, muestra un mensaje de éxito y redirige al usuario a su pantalla principal correspondiente.

Excepción que pueden ocurrir:
Credenciales invalidas con formato de correo incorrecto
El correo ya existe
Contraseña rechazada por seguridad(menos 6 caracteres)
Fallo no hay conexión internet

________________________________________________

Caso de uso 2: Inicio de sesión 
Descripción: Permite a un usuario previamente registrado autenticarse en el sistema mediante sus credenciales (correo y contraseña), recuperar su informacion de usuario (perfil) y se redirigdo a la vista correspondiente según su rol (empleado, supervisor o ejecutor).

Actores
Usuario (Empleado / Supervisor / Ejecutor): Persona que accede a la aplicación.
Flutter Frontend: Interfaz con formulario capturar credenciales y permite acceso a navegación según rol.
Firebase Authentication: Servicio externo encargado de validar las credenciales cifradas y emitir el identificador único (uid).
Cloud Firestore: base de datos NoSQL que almacena los datos del usuario, accede a traves del uid

Flujo (camino exitoso)
El usuario en pagina de login ingresa su Correo electrónico y su Contraseña en(LoginScreen).

2. El usuario presiona el botón de "Iniciar Sesión".

3. El sistema valida que los campos no estén vacíos y deshabilita inmediatamente el botón de envío para evitar múltiples solicitudes simultáneas mientras se procesa la autenticación.

4. Firebase Auth valida el correo y la contraseña cifrada, confirma la autenticidad y devuelve a la aplicación el identificador único del usuario (uid).

5. La aplicación toma el uid obtenido y realiza una consulta directa (get) a la colección usuarios en Cloud Firestore, buscando el documento exacto cuyo ID coincide con dicho uid.

6. Cloud Firestore devuelve el documento que contiene los atributos del usuario: id, nombre, correo, rol y areaId.

7. La aplicación almacena temporalmente los datos del usuario en la memoria local (gestión de estado) para su uso durante la sesión activa.

8. El sistema evalúa el atributo rol y ejecuta el enrutamiento de navegación correspondiente:

Si el rol es empleado: Lo rediriges a la vista de "Servicios y Creación" y aparece como opcion "Mis Solicitudes".
Si el rol es supervisor: Lo rediriges a la "Bandeja de Supervisión" para que pueda aprobar o rechazar solicitudes.
Si el rol es ejecutor: Lo rediriges al "Tablero de Trabajo" para que vea las tareas asignadas y registre avances.

Nota: tanto el rol supervisor como ejecutor, deben teer acceso a vistas como Servicios y creación y "Mis solicitudes". Al ser empleados también tienen el privilegio de crear solicitudes propias

Excepciones(Manejo de errores)
Credenciales invalidas o usuario no existente
Formato correo invalido
Formato contraseña invalida
Perfil con encontrado en firestore: usuario existe en auth , pero en la bd de firestore no existe un usuario asociado a ese uid
Fallo conexión de red
_____________________________________________________-

 CASO DE USO 3: Listar servicios y areas para crear una nueva solicitud

Garantizar que, al momento en que el usuario autenticado (cualquier rol) accede a la vista de "Servicios y Creación", la aplicación haya consumido exitosamente el catálogo externo de áreas y servicios mediante una petición HTTP a un servidor local, transformando el JSON en modelos Dart, y preparado los datos en la interfaz para permitir la selección de la necesidad operativa.

El sistema procesa el JSON recibido y agrupa los servicios bajo sus respectivas Áreas correspondientes (ej. Tecnología, Infraestructura, Logística). Una vez seleccionado el servicio se habilite la opción de crear solicitud

Origen de Datos Externo: El catálogo debe obtenerse estrictamente mediante una petición HTTP GET a un endpoint configurado (API local)


Arquitectura Limpia y Separación de Responsabilidades:
Modelo Dart: Estructura tipada para mapear el JSON (conteniendo ID, nombre, área, descripción y plazo orientativo).
2. Servicio HTTP: Encargado de ejecutar la petición de red, gestionando explícitamente timeouts y códigos de respuesta no exitosos.
3. Repository: Coordina el acceso a la capa HTTP y encapsula el manejo de errores (red caída, formato JSON inválido, fallos de servidor).

Gestión de Estados de la UI (Obligatorio):

Cargando (Loading): Mostrar un indicador visual de carga mientras se resuelve la petición de red.
2. Datos Disponibles (Success): Renderizar ordenadamente las áreas y sus respectivos servicios seleccionables.
3. Resultado Vacío (Empty): Mostrar un mensaje amigable en caso de que el catálogo no retorne elementos.
4. Error con Opción de Reintento (Error): Interceptar cualquier fallo técnico (sin mostrar trazas de código) y presentar un mensaje comprensible asociado al error ocurrido acompañado de un botón de "Reintentar" que permita disparar nuevamente la petición HTTP.

Flujo (Camino exitoso):

Paso 1: Selección del Área
El usuario visualiza lista con las Áreas disponibles en la empresa. Al seleccionar un área, el sistema filtra dinámicamente los servicios que le pertenecen.

Paso 2: Selección del Servicio Específico
El usuario despliega y elige el Servicio concreto que necesita. Al elegir el servicio, el sistema captura su identificador y su plazo orientativo.

Habilitación del Formulario
Una vez seleccionado el par Área + Servicio, el sistema desbloquea el campo de texto para que el empleado ingrese la descripción manual de su necesidad y habilita el botón de envío para registrar la solicitud en Firestore.

________________________________________________

CASO DE USO 4:Creacion de nueva solicitud
Descripción: Permite a cualquier usuario autenticado (empleado, supervisor o ejecutor) visualizar el catálogo externo de áreas y servicios obtenido por HTTP, seleccionar el requerimiento operativo e ingresar la descripción detallada de su necesidad.

2. Actores
Usuario Autenticado (Solicitante): Empleado, Supervisor o Ejecutor.

Sistema (Flutter Frontend): Interfaz que gestiona la vista de servicios, los estados de red y la habilitación reactiva del formulario.

Servidor Local (HTTP): Proveedor del catálogo externo de áreas y servicios.

3. Precondiciones
El usuario ha iniciado sesión exitosamente en el sistema.
El catálogo externo de áreas y servicios se ha cargado correctamente en la vista de "Servicios y Creación" mediante petición HTTP.

4. Flujo Principal (Camino Feliz)
El usuario accede a la vista de "Servicios y Creación" (disponible para todos los roles).

2. El sistema presenta el listado de Áreas y Servicios obtenidos mediante el consumo HTTP del catálogo.

3. Selección en Cascada:
Paso 1: El usuario selecciona un Área.
Paso 2: El usuario selecciona el Servicio Específico requerido (capturando su ID y plazo orientativo).

4. Al completarse la selección del par Área + Servicio, el sistema desbloquea de manera reactiva el campo de texto de descripción manual y habilita el botón de envío.

5. El usuario ingresa la descripción detallada de su necesidad operativa y presiona el botón de "Enviar Solicitud".

6. El sistema valida que la descripción no esté vacía, bloquea temporalmente el botón para prevenir envíos duplicados y transfiere el flujo de datos al caso de uso de asignación y sincronización (CU-05).

_________________________________________-

Caso de uso 5: Asignación de supervisor y sincronización de solicitud

Descripción: Aplica la regla para asignar automáticamente al supervisor óptimo ( balanceo de carga en área central), construye el objeto completo y gestiona la persistencia local en Drift con sincronización diferida hacia Cloud Firestore.

2. Actores
Sistema (Lógica de Negocio / Repositorio): Coordina la asignación y la persistencia.
Base de Datos Local (Drift): Almacenamiento local offline-first y gestión de estados de sincronización.
Base de Datos Remota (Cloud Firestore): Repositorio centralizado en la nube.

3. Precondiciones
El usuario presiona enviar solicitud, una vez seleccionado servicio e ingresado la descripción correctamente (CU-04).

El dispositivo cuenta con los datos del usuario autenticado en memoria.

4. Flujo Principal (Camino Feliz)

Validación del Rol del Solicitante:

El sistema evalúa el rol del usuario autenticado.

2. Si el usuario creador posee el rol de supervisor, el sistema lo excluye automáticamente de la lista de candidatos para cumplir la regla de negocio de evitar la auto-aprobación.

Aplicación de Lógica de Balanceo de Carga ("Supervisor con menos solicitudes activas"):

El sistema consulta los usuarios de rol "supervisor"

2. El sistema cuenta en tiempo real cuántas solicitudes activas (no cerradas ni vencidas) tiene asignadas cada supervisor central.

4. El algoritmo selecciona y asigna el ID del supervisor que posea la menor carga activa de trabajo (idSupervisorSeleccionado).

Construcción del Objeto Completo de la Solicitud:

El sistema instancia en memoria el objeto con todos sus atributos definidos desde el origen:

Dart
final nuevaSolicitud = {
  'id': idGenerado,
  'solicitante': usuarioActual.id,
  'descripcion': textoDescripcion,
  'estado': 'SOLICITADA',
  'avance': 0,
  'aprobador': idSupervisorSeleccionado,
  'ejecutor': null,
  'prioridad': null,
  'plazo': null,
};



Persistencia Local (Drift):

El repositorio guarda la solicitud en la base de datos local Drift y la marca explícitamente con estado de sincronización Pendiente.

2. La interfaz muestra el registro local, distinguiendo claramente el estado del negocio (SOLICITADA) del estado de sincronización (Pendiente de subida).

Sincronización Remota (Cloud Firestore):

El sistema intenta enviar el registro a Cloud Firestore cuando la sesión y la conexión a internet lo permitan.

2. Una vez obtenida la confirmación remota satisfactoria por parte de Firestore, el sistema actualiza el registro local en Drift marcándolo como Sincronizado.

3. El sistema libera el bloqueo de la interfaz, presenta un mensaje de éxito comprensible al usuario y actualiza la vista hacia la sección de "Mis Solicitudes".


5. Flujos Alternativos / Excepciones

Fallo temporal de red o conectividad:

Respuesta: Si la sincronización remota falla por falta de red, la solicitud se conserva de forma segura en Drift como Pendiente. La aplicación permite al usuario reintentar la sincronización manualmente de forma sencilla.

Rechazo por reglas de seguridad o conflicto en el servidor:

Respuesta: Si el servidor rechaza la operación debido a una regla de validación, el sistema conserva la evidencia local, detiene los reintentos automáticos indefinidos y muestra el motivo claro al usuario para que pueda corregir el datos o descartar el intento.

