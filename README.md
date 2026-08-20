# León Bus Live

Aplicación iOS nativa (SwiftUI) para consultar en tiempo real cuánto falta para que llegue cada autobús urbano a una parada de **León, España**.

> **Importante:** de momento no hay API oficial confirmada. La app incluye un proveedor **mock de demostración** claramente identificado. Los datos no son oficiales ni deben usarse como información de servicio real.

## Requisitos

- macOS con Xcode actual (SDK iOS 26+)
- iOS 26.0 o superior
- Sin dependencias externas de terceros

## Cómo ejecutar

1. Abre `LeonBusLive.xcodeproj` en Xcode.
2. Selecciona un simulador o un iPhone físico.
3. Pulsa Run (⌘R).

Si solo tienes `project.yml`, regenera el proyecto:

```bash
brew install xcodegen   # si hace falta
xcodegen generate
open LeonBusLive.xcodeproj
```

Ejecutar tests:

```bash
xcodebuild test -scheme LeonBusLive -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Objetivo de producto

- Ver paradas cercanas y próximos buses
- Consultar detalle de parada con llegadas en vivo
- Explorar líneas y recorrido
- Guardar favoritos (paradas con alias, líneas)
- Buscar líneas, paradas y destinos
- Funcionar sin permiso de ubicación (fallback al centro de León)

## Arquitectura

La UI **no conoce** el origen de los datos. Todo pasa por el protocolo `TransitDataProvider`.

```
Views / ViewModels
        │
        ▼
   AppModel (Observation)
        │
        ▼
 TransitDataProvider  ◄── MockTransitDataProvider
                      ◄── APITransitDataProvider (URLSession, listo para REST)
        │
        ▼
 MockRealtimeEngine (simulación 5–10 s)
 LocationService (CoreLocation)
 FavoritesStore / SettingsStore (UserDefaults)
```

### Estructura

```
LeonBusLive/
├── App/                 # Entrada, tabs, AppModel
├── Models/              # BusStop, BusLine, BusVehicle, BusArrival…
├── Services/            # Providers, ubicación, realtime, favoritos
├── Features/            # Nearby, Stops, Lines, Favorites, Search, Settings…
├── Components/          # ArrivalRow, LineBadge, glass helpers…
├── Resources/           # Assets + Info.plist
└── Utilities/           # Formatters, Liquid Glass helpers
```

## Sistema de datos mock

- Catálogo: `LeonDemoCatalog` (paradas y líneas inspiradas en León).
- Motor: `MockRealtimeEngine` mueve buses por polilíneas y recalcula ETAs.
- Cada modelo lleva `isDemoData` y la UI muestra el aviso *“Datos de demostración — no oficiales”*.

Cambiar de mock a API: **Ajustes → Fuente de datos**, o `SettingsStore.providerKind`.

## Cómo conectar una API real

1. Configura `APITransitConfiguration.baseURL` (y API key si aplica).
2. Completa/ajusta los DTOs en `APIModels.swift` al contrato real.
3. `APITransitDataProvider` ya usa `URLSession` + `async/await` y mapea a modelos de dominio.
4. Selecciona el proveedor `.api` en Ajustes.

Las vistas no requieren cambios si el protocolo se mantiene.

## Cómo integrar GTFS

GTFS es estático (paradas, rutas, trips, stop_times):

1. Descarga/publica el feed GTFS (zip).
2. Parsea `stops.txt`, `routes.txt`, `trips.txt`, `stop_times.txt`, `shapes.txt`.
3. Implementa un `GTFSTransitDataProvider` que conforme `TransitDataProvider`.
4. Mapea:
   - `stops` → `BusStop`
   - `routes` → `BusLine`
   - `shapes` / secuencia de `stop_times` → `LineRoute.polyline` y orden de paradas
5. Las llegadas teóricas salen de `stop_times` → `BusArrival` con `isRealtime = false`.

## Cómo integrar GTFS-Realtime

GTFS-RT aporta Vehicle Positions, Trip Updates y Service Alerts:

1. Consume el protobuf GTFS-RT (o un proxy JSON).
2. Combina con el GTFS estático:
   - Trip Updates → `predictedArrival`, `delaySeconds`, `isRealtime = true`
   - Vehicle Positions → `BusVehicle`
3. Puedes extender `MockRealtimeEngine` hacia un `RealtimeIngestor` que actualice un store observable.
4. Mantén el mismo `TransitDataProvider` para que la UI siga igual.

## Liquid Glass

La app usa componentes de sistema (TabView, NavigationStack, List, toolbars) que adoptan Liquid Glass automáticamente en iOS 26+.

Para superficies custom se usan APIs nativas cuando existen:

- `glassEffect(_:in:)`
- variante interactiva `.regular.interactive()`
- fallback a `.ultraThinMaterial` si la API no estuviera disponible

No se recrea el efecto con hacks visuales.

## Accesibilidad

- VoiceOver labels en filas, badges y mapa
- Dynamic Type (fuentes de sistema)
- Favoritos y acciones con área táctil ≥ 44 pt
- El color de línea no es el único canal de información (número + texto)

## Licencia / aviso

Proyecto de demostración. Nombres de paradas y líneas son ficticios o aproximados con fines de UI. No afiliado al Ayuntamiento de León ni a operadores de transporte.