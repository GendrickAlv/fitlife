# FitLife — Contrato técnico interno (fuente de verdad para todo el equipo)

App Flutter (Dart 3, Material 3). Idioma de la UI: **español**. Código (identificadores) en inglés.
Paquete: `fitlife`. Plataformas objetivo: Android (principal), Windows/desktop para desarrollo.

> **IMPORTANTE (Flutter 3.50):** Material vive en el paquete `material_ui`. Importar SIEMPRE
> `import 'package:material_ui/material_ui.dart';` (NO `package:flutter/material.dart`).
> Ejecutar Flutter con `$env:Path="$env:USERPROFILE\flutter\bin;$env:Path"` en PowerShell.

## Dependencias (pubspec)
- `provider` — gestión de estado (ChangeNotifier + MultiProvider)
- `sqflite` + `sqflite_common_ffi` (desktop/tests) + `path` — persistencia SQLite
- `shared_preferences` — ajustes de perfil y preferencias
- `fl_chart` — gráficos
- `sensors_plus` — acelerómetro (contador de pasos)
- `intl` — formato de fechas/números (locale `es`)
- `flutter_localizations` (sdk) — localización Material en español
- dev: `flutter_test`, `flutter_lints`

## Estructura de carpetas
```
lib/
  main.dart                      # init DB factory (ffi en desktop), intl es, runApp
  app.dart                       # FitLifeApp: MultiProvider + MaterialApp (tema, rutas)
  core/
    theme/app_theme.dart         # AppTheme.light / AppTheme.dark, AppColors
    utils/date_utils.dart        # DateUtilsX: startOfDay, startOfWeek (lunes), dayKey 'yyyy-MM-dd', isSameDay
    utils/validators.dart        # Validators.required/positiveNumber/numberInRange/maxLength
    utils/formatters.dart        # Fmt.date, Fmt.dateTime, Fmt.shortDay, Fmt.kg, Fmt.ml, Fmt.liters
    constants.dart               # categorías, tipos, metas por defecto
  data/
    database/app_database.dart   # AppDatabase singleton (sqflite), schema v1, onCreate, seed opcional
    models/                      # routine.dart, activity.dart, weight_entry.dart, water_entry.dart,
                                 # challenge.dart, step_record.dart, user_profile.dart
    repositories/                # un repositorio por tabla (CRUD + consultas)
  providers/                     # un ChangeNotifier por feature
  screens/
    shell/home_shell.dart        # NavigationBar con 5 destinos + IndexedStack
    dashboard/                   # Inicio
    routines/                    # lista, detalle, formulario
    history/                     # historial de actividades + formulario actividad
    weight/                      # seguimiento de peso
    hydration/                   # hidratación
    stats/                       # gráficos estadísticos
    challenges/                  # desafíos semanales
    sensors/                     # contador de pasos (acelerómetro)
    settings/                    # perfil y ajustes
  widgets/                       # widgets compartidos
test/
```

## Modelos (todos inmutables, `final`, con `copyWith`, `toMap()`, `factory fromMap(Map<String, Object?>)`)
Fechas se guardan en SQLite como `INTEGER` (millisecondsSinceEpoch). Booleans como 0/1.

### Routine (tabla `routines`)
| campo | tipo Dart | columna |
|---|---|---|
| id | int? | id INTEGER PK AUTOINCREMENT |
| name | String | name TEXT NOT NULL |
| description | String | description TEXT NOT NULL DEFAULT '' |
| category | String (ver `RoutineCategory`) | category TEXT NOT NULL |
| difficulty | String ('Principiante','Intermedio','Avanzado') | difficulty TEXT NOT NULL |
| durationMinutes | int | duration_minutes INTEGER NOT NULL |
| estimatedCalories | int | estimated_calories INTEGER NOT NULL |
| exercises | List<Exercise> | exercises TEXT NOT NULL (JSON) |
| isFavorite | bool | is_favorite INTEGER NOT NULL DEFAULT 0 |
| createdAt | DateTime | created_at INTEGER NOT NULL |

`Exercise { String name; int sets; int reps; double? weightKg; int? restSeconds }` con toJson/fromJson.

### Activity (tabla `activities`) — una sesión de entrenamiento realizada (historial)
id, routineId (int?, FK routines ON DELETE SET NULL), title (String), category (String),
durationMinutes (int), calories (int), date (DateTime), notes (String, default ''), 
feeling (int 1..5, default 3).

### WeightEntry (tabla `weight_entries`)
id, weightKg (double), date (DateTime), note (String default '').

### WaterEntry (tabla `water_entries`)
id, amountMl (int), date (DateTime).

### Challenge (tabla `challenges`)
id, title, description, type (`ChallengeType` enum guardado por `name`: workouts, minutes, calories, water, steps),
target (double), weekStart (DateTime, lunes 00:00), createdAt (DateTime).
El **progreso NO se guarda**: se calcula en `ChallengeProvider` a partir de los demás datos de esa semana.

### StepRecord (tabla `step_records`)
id, day (String 'yyyy-MM-dd' UNIQUE), steps (int).

### UserProfile (SharedPreferences, no SQLite)
name (String, default 'Atleta'), heightCm (double, 170), goalWeightKg (double?), dailyWaterGoalMl (int, 2500),
dailyStepGoal (int, 8000), weeklyWorkoutGoal (int, 4), themeMode (ThemeMode, system).

## Constantes (`core/constants.dart`)
```dart
class RoutineCategory { static const all = ['Fuerza','Cardio','HIIT','Flexibilidad','Yoga','Deporte','Otro']; }
class Difficulty { static const all = ['Principiante','Intermedio','Avanzado']; }
enum ChallengeType { workouts, minutes, calories, water, steps }  // con extension: label (es), unit, icon
```
Icono y color por categoría: `CategoryStyle.icon(String)` / `CategoryStyle.color(String)` en constants.

## Repositorios (`data/repositories/`) — todos reciben `AppDatabase` en el constructor
Métodos async mínimos (CRUD completo):
- `RoutineRepository`: getAll(), getById(id), insert(Routine)→int, update(Routine), delete(id), toggleFavorite(id)
- `ActivityRepository`: getAll() (orden date DESC), getInRange(DateTime from, DateTime to), insert, update, delete
- `WeightRepository`: getAll() (date DESC), insert, update, delete
- `WaterRepository`: getAll(), getInRange(from,to), insert, update, delete
- `ChallengeRepository`: getAll(), getForWeek(weekStart), insert, update, delete
- `StepRepository`: getAll(), getForDay(String dayKey), upsert(StepRecord), getInRange(fromKey,toKey)
- `ProfileRepository` (SharedPreferences): load()→UserProfile, save(UserProfile)

## Providers (`providers/`) — ChangeNotifier, expuestos en `app.dart` con MultiProvider
Cada uno expone: `bool isLoading`, `String? error`, `Future<void> load()`, y operaciones CRUD que
persisten y luego actualizan la lista en memoria + `notifyListeners()`.
- `RoutineProvider`: routines, favorites, add/update/delete/toggleFavorite, byCategory(String?)
- `ActivityProvider`: activities, add/update/delete, todayActivities, activitiesInWeek(DateTime weekStart),
  minutesPerDay(lastNDays) → Map<DateTime,int>, caloriesPerDay(lastNDays), totals
- `WeightProvider`: entries (DESC), latest, add/update/delete, change since first, bmi(heightCm)
- `HydrationProvider`: entries, add/update/delete, todayTotalMl, totalForDay(DateTime), dailyTotals(lastNDays)
- `ChallengeProvider`: challenges (semana actual y pasadas), add/update/delete,
  `progressFor(Challenge, {required ActivityProvider, HydrationProvider, StepProvider})` → double (valor actual)
  — implementar como `ChangeNotifierProxyProvider` o calcular en la UI pasando providers; elegir la forma más simple.
- `StepProvider`: escucha `accelerometerEventStream()` (sensors_plus) con detección de picos (umbral de magnitud
  ~11.5 m/s², intervalo mínimo 300 ms), `todaySteps`, `isTracking`, `isSupported`, start()/stop(),
  persiste con upsert cada 20 pasos y al detener; history (StepRecord). Debe fallar con elegancia
  (isSupported=false) en plataformas sin sensor.
- `ProfileProvider`: profile, update(UserProfile), themeMode.

## Navegación
`HomeShell` con `NavigationBar` (Material 3), 5 destinos: **Inicio, Rutinas, Historial, Progreso, Más**.
- Inicio → `DashboardScreen`
- Rutinas → `RoutinesScreen`
- Historial → `HistoryScreen`
- Progreso → `StatsScreen` (pestañas: Actividad, Peso, Hidratación)
- Más → `MoreScreen` (lista: Peso, Hidratación, Desafíos semanales, Sensor de pasos, Perfil y ajustes, Acerca de)
Pantallas secundarias con `Navigator.push(MaterialPageRoute(...))`. Rutas nombradas en `app.dart` (`AppRoutes`).

## Widgets compartidos (`widgets/`)
- `EmptyState(icon, title, message, {actionLabel, onAction})`
- `StatCard(icon, label, value, {color, subtitle, onTap})`
- `SectionHeader(title, {actionLabel, onAction})`
- `ConfirmDialog.show(context, title, message) → Future<bool>` (para eliminar)
- `ProgressRing(progress 0..1, center Widget, color, size)`
- `AppSnack.success(context, msg)` / `AppSnack.error(...)`

## Reglas UI/UX
- Material 3, `ColorScheme.fromSeed(seedColor: Color(0xFF00BFA6))` (verde azulado), modo claro y oscuro.
- Usar `Theme.of(context).colorScheme` y `textTheme`; nada de colores fijos salvo `CategoryStyle`/`AppColors`.
- Formularios: `Form` + `GlobalKey<FormState>` + `TextFormField` con `Validators`; botón guardar deshabilitado
  mientras guarda; `DatePicker`/`TimePicker` para fechas. Mismo formulario para crear y editar (parámetro opcional).
- Eliminar siempre pide confirmación (`ConfirmDialog`) y/o `Dismissible` con SnackBar "Deshacer" cuando aplique.
- Estados vacíos con `EmptyState`. Estados de carga con `CircularProgressIndicator`.
- Textos en español, fechas con `intl` locale `es`.
- Sin `print`; sin warnings de `flutter analyze`.
