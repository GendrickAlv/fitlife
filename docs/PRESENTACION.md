# FitLife — Guion de presentación y defensa (10–15 min)

Distribución sugerida: 12 diapositivas, ~12 minutos más 3 de preguntas. Cada integrante del Equipo 4 presenta 2–3 diapositivas (TODO: asignar nombres).

## Guion diapositiva por diapositiva

### 1. Portada (0:30)
- Título: **FitLife — tu compañero de entrenamiento, peso, hidratación y pasos**.
- Equipo 4, materia, fecha, enlace del repositorio: <https://github.com/GendrickAlv/fitlife>.
- Insignias: Flutter 3.50, Dart 3.14, SQLite, Provider.

### 2. Problema (1:00)
- Quien se ejercita suele usar varias aplicaciones separadas: una para rutinas, otra para peso, otra para agua y otra para pasos.
- Muchas exigen cuenta, conexión o suscripción.
- Se pierde la visión de conjunto del progreso.

### 3. Solución (1:00)
- Una sola app con: rutinas, historial, peso, hidratación, pasos con acelerómetro, desafíos semanales y estadísticas.
- Datos 100 % locales (SQLite), sin cuentas ni internet.
- Funciona en Android, web (Chrome) y Windows; interfaz en español con tema claro y oscuro.

### 4. Demo en vivo (4:00) — ver guion de clics abajo

### 5. Arquitectura (1:30)
- Capas: UI → Providers → Repositories → AppDatabase / SharedPreferences (diagrama de la sección 3 de la documentación técnica).
- 7 providers en un `MultiProvider`; un repositorio por tabla; modelos inmutables.
- Base inyectable: permite pruebas con SQLite en memoria.

### 6. Modelo de datos (1:00)
- 6 tablas: `routines`, `activities`, `weight_entries`, `water_entries`, `challenges`, `step_records`.
- Clave foránea `activities.routine_id` con `ON DELETE SET NULL`; `step_records.day` UNIQUE; 4 índices por fecha.
- El perfil vive en SharedPreferences. Mostrar el `erDiagram`.

### 7. Aspectos técnicos destacados (2:00)
- **Sensor**: magnitud del acelerómetro, umbral 11,5 / rearme 10,5 m/s², 300 ms entre pasos, guardado cada 20 pasos; si no hay sensor, modo manual.
- **Multiplataforma**: fábrica de base de datos por plataforma (nativo, FFI y WASM en web).
- **Progreso de desafíos calculado, no almacenado**: sin datos duplicados.
- **Deshacer** al eliminar con `Dismissible` y SnackBar.
- **Validación** centralizada en `Validators` y `FormRules`.
- **Gráficos** con `fl_chart`: barras, líneas y circular.

### 8. Calidad y pruebas (1:00)
- 53 casos de prueba en 13 archivos: utilidades, modelos, repositorios (CRUD y claves foráneas), providers (incluido el contador de pasos con un acelerómetro simulado) y pantallas.
- `flutter analyze` con 0 incidencias y `flutter_lints`.

### 9. Cumplimiento de los criterios de evaluación (1:00)

| Criterio | Evidencia |
|---|---|
| Flutter y Dart | App completa en Dart 3.14, Material 3 |
| Interfaz profesional | Tema claro/oscuro, estados vacíos, anillos de progreso, gráficos |
| Navegación | `NavigationBar` de 5 pestañas y `Navigator.push` |
| Formularios con validación | 6 formularios más diálogos, con reglas por campo |
| Datos locales | Repositorios sobre SQLite y SharedPreferences, con seed |
| CRUD completo | Rutinas, actividades, peso, agua y desafíos |
| Gestión de estado | Provider + ChangeNotifier |
| Persistencia SQLite | `sqflite` con versionado de esquema, claves foráneas e índices |
| Documentación | README, documentación técnica, manual y este guion |
| Repositorio GitHub | Enlace en el README |
| Funcionalidades avanzadas | Gráficos, acelerómetro y desafíos semanales |

### 10. Limitaciones y trabajo futuro (0:45)
- Sin copia de seguridad ni sincronización; el conteo de pasos es aproximado y sólo con la app activa.
- Futuro: exportar datos, notificaciones, servicio en segundo plano, migraciones de esquema.

### 11. Conclusiones (0:30)
- Se cumplieron los requisitos y las tres funcionalidades avanzadas.
- Aprendizajes: arquitectura por capas, pruebas y trabajo en equipo (TODO: añadir aprendizajes propios).

### 12. Preguntas (3:00)

## Guion de la demo (clics exactos)

Prepara antes: app recién abierta con las 4 rutinas de ejemplo y, si es posible, algunos datos previos para ver los gráficos. En Android, lleva el teléfono para el sensor.

1. **Inicio**: mostrar saludo, anillos Agua / Pasos / Semana y accesos rápidos. Pulsar **Agua +250 ml** y ver cómo sube el anillo de agua.
2. **Rutinas** (pestaña): mostrar las rutinas de ejemplo; escribir en *Buscar rutinas* y filtrar por una categoría; tocar la estrella para marcar una favorita.
3. Pulsar **Nueva rutina**. Pulsar **Crear rutina** vacío para mostrar los **errores de validación** (nombre y "Añade al menos un ejercicio"). Completar nombre, duración y calorías, pulsar **Añadir**, crear un ejercicio y pulsar **Crear rutina**.
4. Abrir la rutina creada y pulsar **Registrar entrenamiento** (se rellena el formulario); guardar.
5. **Historial** (pestaña): ver la actividad nueva, cambiar entre **Semana / Mes / Todo**, deslizar una actividad a la izquierda para eliminarla y pulsar **Deshacer**. Tocar una actividad para editarla.
6. **Progreso** (pestaña): recorrer **Actividad**, **Peso** e **Hidratación**; cambiar **7 días / 30 días**; tocar el gráfico circular.
7. **Más → Peso**: pulsar **Registrar peso**, introducir un valor fuera de rango (por ejemplo 5) para ver el error, luego uno válido; mostrar variación, IMC y gráfico.
8. **Más → Hidratación**: pulsar **Personalizado**, registrar 300 ml; mostrar el gráfico de los últimos 7 días y eliminar con deslizar + **Deshacer**.
9. **Más → Desafíos semanales**: pulsar **Nuevo desafío**, tipo *Entrenamientos*, objetivo 3; guardar y ver el progreso calculado.
10. **Más → Sensor de pasos**: pulsar **Iniciar conteo**, agitar/caminar con el teléfono y ver cómo suben los pasos; pulsar **Detener conteo**. En web o escritorio mostrar el aviso y **Agregar pasos**.
11. **Más → Perfil y ajustes**: cambiar el tema a **Oscuro** para mostrar el modo oscuro y guardar.
12. Cerrar y reabrir la app para demostrar la **persistencia**.

Plan B si falla la demo: usar las capturas de `docs/screenshots/` (inicio, rutinas, historial, progreso, formulario) y el modo web en Chrome.

## Preguntas probables del jurado

**¿Por qué Provider y no Bloc?**
Provider es el enfoque recomendado por Flutter para apps de este tamaño: poca ceremonia, curva de aprendizaje corta y suficiente para listas en memoria y consultas derivadas. Bloc aporta más estructura (eventos y estados) pero exige más código para un alcance como el nuestro. Nuestros `ChangeNotifier` son pequeños, uno por funcionalidad, y se prueban fácilmente. Si la app creciera, la capa de repositorios permitiría migrar a Bloc sin tocar los datos.

**¿Cómo garantizan la integridad de los datos?**
Con restricciones en el esquema (`NOT NULL`, `DEFAULT`, `UNIQUE` en `step_records.day`, claves primarias), claves foráneas activadas con `PRAGMA foreign_keys = ON` (al borrar una rutina, `routine_id` de sus actividades pasa a `NULL` y la actividad se conserva), validación de formularios antes de guardar, modelos inmutables y recarga de la lista desde la base tras cada escritura, de modo que la base es la fuente de verdad. Las pruebas de repositorios verifican el CRUD y el comportamiento de la clave foránea.

**¿Cómo funciona el contador de pasos?**
Se escucha el acelerómetro y se calcula la magnitud `√(x²+y²+z²)`. Un paso se cuenta cuando la magnitud supera 11,5 m/s², el detector está armado y han pasado al menos 300 ms desde el último paso; el detector se rearma cuando la magnitud baja de 10,5 m/s² (histéresis). Cada 20 pasos y al detener se guarda en SQLite (un registro por día). Si el sensor no existe o falla, la app pasa a modo no soportado y permite registrar pasos manualmente. Es una estimación y no cuenta con la app cerrada.

**¿Por qué SQLite y no Firebase?**
Los datos son personales y de uso individual: SQLite funciona sin conexión, no requiere cuentas ni servidor, no tiene costes y es privado. Además el proyecto exigía persistencia local con SQLite. El modelo es relacional (actividades que referencian rutinas) y se consulta por rangos de fechas. La desventaja es que no hay sincronización entre dispositivos, algo que recogemos como trabajo futuro.

**¿Cómo probaron la app?**
Con 53 casos de prueba automatizados (`flutter test`): pruebas unitarias de validadores, fechas y modelos; de repositorios sobre SQLite en memoria; de providers (incluido el contador de pasos con un flujo de acelerómetro falso y un reloj inyectado); y pruebas de widgets de las pantallas, incluyendo validación de formularios y estados vacíos. Además usamos `flutter analyze` y pruebas manuales en las plataformas soportadas (TODO: confirmar cuáles se probaron).

**¿Cómo funciona en web si SQLite es nativo?**
Con `sqflite_common_ffi_web`, que ejecuta SQLite compilado a WebAssembly (`web/sqlite3.wasm`) con un service worker (`web/sqflite_sw.js`). Una exportación condicional en `db_platform.dart` elige la fábrica correcta según la plataforma.

**¿Cómo se calcula el progreso de un desafío?**
No se guarda: `ChallengeProvider.progressFor` lo calcula en el momento a partir de las actividades, el agua y los pasos de la semana del desafío. Así nunca queda desincronizado con los datos reales.

**¿Qué pasa si se elimina algo por error?**
Actividades, pesos y registros de agua se eliminan con "Deshacer", que vuelve a insertar el registro. Rutinas y desafíos piden confirmación antes de eliminarse.

**¿Qué mejorarían?**
Copia de seguridad y exportación de datos, notificaciones, conteo de pasos en segundo plano y migraciones de esquema.

**¿Cómo se reparten el trabajo?**
TODO: completar con la distribución real del equipo.
