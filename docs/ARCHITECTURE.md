# Architektur-Dokumentation

## Überblick

Das GUI-Slider-MultiMonitor System basiert auf einer modularen Architektur mit klarer Trennung der Verantwortlichkeiten.

## Module-Struktur

### 1. Kern-Module

#### MonitorDetection.au3
- **Zweck**: Erkennung und Verwaltung aller angeschlossenen Monitore
- **Hauptfunktionen**:
  - `_GetMonitors()`: Erkennt alle Monitore
  - `_GetPrimaryMonitor()`: Ermittelt den Hauptmonitor
  - `_GetMonitorAtPoint()`: Findet Monitor an bestimmter Position
  - `_HasAdjacentMonitor()`: Prüft angrenzende Monitore

#### SliderLogic.au3
- **Zweck**: Implementierung der Slider-Animation und -Logik
- **Hauptfunktionen**:
  - `_SlideWindow()`: Haupt-Slider-Funktion
  - `_DetermineSlideDirection()`: Automatische Richtungsbestimmung
  - `_MoveToNextMonitor()`: Monitor-Wechsel
  - `_CenterOnMonitor()`: GUI zentrieren

### 2. Include-Dateien

#### GlobalVars.au3
- Zentrale Verwaltung aller globalen Variablen
- Kategorisiert in:
  - Slider Core Variablen
  - Monitor Management
  - Animation
  - Konfiguration

#### Constants.au3
- Alle System-Konstanten
- Kategorien:
  - Window Positions
  - Animation
  - Monitor Detection
  - GUI Defaults
  - Error Codes

### 3. Datenfluss

```
Monitor-Erkennung
       ↓
Monitor-Array (g_aMonitors)
       ↓
Slider-Logik
       ↓
GUI-Bewegung
```

### 4. Animation-System

1. **Initialisierung**: Position und Richtung bestimmen
2. **Berechnung**: Start- und Endpunkte kalkulieren
3. **Animation**: Schrittweise Bewegung
4. **Finalisierung**: Status aktualisieren

### 5. Monitor-Übergangs-Logik

#### Horizontale Bewegung (Links/Rechts)
- Prüfung auf angrenzende Monitore
- Direkter Wechsel bei Vorhandensein
- Slide-Out bei keinem angrenzenden Monitor

#### Vertikale Bewegung (Oben/Unten)
- Nur möglich wenn kein Monitor in der Richtung
- Animation am Bildschirmrand

### 6. Fehlerbehandlung

- Definierte Error-Codes für alle Fehlerfälle
- Graceful degradation bei Monitor-Problemen
- Animation-Lock verhindert Überlappungen

## Erweiterbarkeit

Das System ist für folgende Erweiterungen vorbereitet:
- Zusätzliche Animations-Effekte
- Erweiterte Monitor-Konfigurationen
- Plugin-System für zusätzliche Features
