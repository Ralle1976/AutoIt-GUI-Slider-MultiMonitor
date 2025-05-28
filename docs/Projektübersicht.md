# Projektübersicht: GUI-Slider-MultiMonitor

## Zielsetzung

Ein GUI soll sich dynamisch an die Monitoranordnung und -auflösung anpassen und zwischen den Monitoren hin- und herfahren können. Dabei soll die Bewegung des GUI logisch und intuitiv sein, sodass bei angrenzenden Monitoren die Slider-Logik korrekt funktioniert.

## Kernfunktionalitäten

### 1. Monitor-Erkennung und -Struktur

- **Automatische Erkennung**: Das System erkennt automatisch alle angeschlossenen Monitore
- **Positionsbestimmung**: Erfassung der relativen Positionen (links, rechts, oben, unten)
- **Dimensionserfassung**: Breiten, Höhen und Startpositionen aller Monitore

### 2. Slider-Logik: Grundprinzipien

#### Vertikale Bewegung (oben, unten)
- Das GUI kann auf dem aktuellen Monitor nach oben oder unten herausfahren
- Voraussetzung: Es gibt keinen angrenzenden Monitor in der jeweiligen Richtung

#### Horizontale Bewegung (links, rechts)
- Bei Erreichen eines Monitorrands wechselt das GUI auf den angrenzenden Monitor
- Kein "Ping-Pong"-Effekt mehr - direkter Übergang zum Nachbarmonitor

## Bewegungsbeispiele

### Beispiel 1: Drei Monitore nebeneinander
**Anordnung**: Monitor 1 (links) | Monitor 2 (mitte, primär) | Monitor 3 (rechts)

**Bewegungslogik von Monitor 2:**
- **Nach oben/unten**: Möglich (keine angrenzenden Monitore in vertikaler Richtung)
- **Nach links**: Direkter Sprung zu Monitor 1, Ausfahrt am linken Rand
- **Nach rechts**: Direkter Sprung zu Monitor 3, Ausfahrt am rechten Rand

### Beispiel 2: Drei Monitore übereinander
**Anordnung**: 
```
Monitor 1 (oben)
Monitor 2 (mitte)
Monitor 3 (unten)
```

**Bewegungslogik:**
- **Nach oben**: Nur von Monitor 1 möglich
- **Nach unten**: Nur von Monitor 3 möglich
- **Nach links/rechts**: Von allen Monitoren möglich

## Technische Komponenten

### GUI-Darstellung
- **GDI+** für erweiterte Grafikfunktionen
- Visualisierung der Monitore und Slider-Bewegungen
- Smooth Animations beim Übergang

### Skalierung und Anpassung
- Automatische Skalierung basierend auf Monitorauflösung
- Responsive Design für verschiedene Monitor-Größen
- DPI-Awareness für hochauflösende Displays

### Persistenz
- Speicherung der GUI-Position in INI-Datei
- Wiederherstellung der letzten Position beim Start
- Konfigurierbare Standardpositionen

## Anwendungsfälle

1. **Multi-Monitor-Arbeitsplätze**: Optimale Nutzung des verfügbaren Bildschirmplatzes
2. **Präsentationen**: Nahtloser Übergang zwischen verschiedenen Displays
3. **Monitoring-Systeme**: Überwachung mehrerer Bildschirme mit einer GUI
4. **Gaming-Setups**: Anpassung an komplexe Monitor-Konfigurationen

## Erweiterungsmöglichkeiten

- **Hotkey-Unterstützung**: Schnelle Navigation per Tastenkombination
- **Touch-Gesten**: Unterstützung für Touch-Displays
- **Animations-Profile**: Verschiedene Übergangseffekte
- **Monitor-Gruppen**: Logische Gruppierung von Monitoren

---

**Dokumentversion**: 1.0  
**Letzte Aktualisierung**: 27.05.2025
