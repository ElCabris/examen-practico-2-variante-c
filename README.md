# SampleTrack - Examen Práctico 2 (G62)

**Variante C · Equipo de cuatro:** Emanuel Cabrera Novoa, Juliana Franco Alzate,
Samuel David Gallego Meneses, Emanuel Orozco Gallego.

El catálogo de muestras (id, tipo, origen, prioridad) sigue viniendo de la shell
(`lib/data/sample_seed.dart`). Firestore y Drift guardan **solo eventos**; el
estado actual de cada muestra se calcula a partir de su evento más reciente.

```
Shell (Sample) ─┐
                ├─> SampleEventRepository ──> UI (info + estado + historial + tablero)
Firestore ──────┤        │
 sample_events  │        └─ si Firestore falla ──> Drift (tabla sample_events)
```

## Puesta en marcha

1. Dependencias y código generado de Drift (ya incluido en el repositorio):

   ```bash
   flutter pub get
   dart run build_runner build   # solo si se modifica la tabla
   ```

2. Conectar el Firebase propio del equipo. `lib/firebase_options.dart` es un
   archivo provisional que debe sobrescribirse:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure            # elegir el proyecto del equipo, Android/iOS
   ```

3. En la consola de Firebase, crear Cloud Firestore. Para el examen se pueden
   usar reglas abiertas sobre la colección:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /sample_events/{eventId} {
         allow read, write: if true;
       }
     }
   }
   ```

4. `flutter run`

Sin el paso 2 la app arranca igual, avisa que está usando datos locales y
trabaja solo con la caché de Drift (el registro de eventos falla porque no se
puede confirmar en Firestore).

## Implementación

| Requisito | Dónde |
|---|---|
| Inicialización de Firebase antes de `runApp` | `lib/main.dart` |
| Colección `sample_events`, un documento por evento (`id`, `sampleId`, `type`, `createdAt`) | `lib/services/sample_event_remote_service.dart` |
| Tabla Drift `sample_events` (+ índice por `sampleId`), upsert y consultas | `lib/database/app_database.dart` (`.g.dart` generado) |
| Remoto primero → actualizar caché → fallback a Drift | `lib/repositories/sample_event_repository.dart` |
| Estado actual, siguiente estado válido, historial | `lib/models/sample_status.dart`, `lib/models/sample_history.dart` |
| Validación de transiciones antes de persistir | `SampleEventRepository.registerEvent` / `validateTransition` |
| Aviso de datos locales | `lib/widgets/data_source_banner.dart` |
| Tablero de la variante C | `lib/models/sample_dashboard.dart` (cálculos), `lib/pages/sample_list_page.dart` (UI) |

Detalles relevantes:

- **Lecturas** con `Source.server` y tiempo límite: así un fallo de red se
  detecta y se usa Drift, en lugar de la caché interna de Firestore.
- **Escrituras** con una transacción: si el servidor no confirma, falla (no
  queda en la cola offline) y el evento no se muestra como registrado ni se
  guarda en Drift.
- Cada evento tiene id propio (`<sampleId>_<microsegundos>`), por lo que el
  upsert en Drift nunca reemplaza eventos anteriores.
- Drift guarda las fechas como texto ISO-8601 (`build.yaml`) para conservar
  los milisegundos al ordenar.

## Variante C · Tablero operativo de trazabilidad

En la pantalla principal:

1. **Filtros combinables**: un dropdown de estado actual (incluye *Sin
   eventos*) y otro de prioridad; se aplican los dos a la vez. La lista se
   muestra ordenada por prioridad (Urgente, Alta, Normal) y luego por la
   actualización más antigua, igual que "Requieren atención".
2. **Contador dinámico**: "Mostrando N de 5 muestras".
3. **Resumen por estado**: cantidad de muestras en cada estado (sobre todo el
   catálogo).
4. **Requieren atención**: muestras no archivadas ordenadas por prioridad
   (Urgente, Alta, Normal) y luego por la actualización más antigua. Una
   muestra sin eventos nunca se ha actualizado, así que va primero dentro de su
   prioridad.

## Pruebas

```bash
flutter test
```

Cubren el cálculo del estado, los filtros/resumen/orden del tablero, el
fallback a Drift, la conservación del historial, el bloqueo de transiciones
inválidas y el caso de escritura remota fallida.
