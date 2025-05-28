# Technische Spezifikation

## Systemarchitektur

### Modulare Struktur

```
┌─────────────────┐
│    main.au3     │ ← Hauptprogramm
└────────┬────────┘
         │
    ┌────┴─────────────────────────┐
    │                              │
┌───▼──────────┐      ┌───────────▼──────────┐
│ Monitor      │      │ GUI Management       │
│ Detection    │      │ - Slider Logic       │
│ - EnumDisplay│      │ - Animations         │
│ - Positioning│      │ - State Management   │
└──────────────┘      └──────────────────────┘
```

## API-Funktionen

### Monitor-Erkennung

```autoit
Func _GETMONITORS()
    ; Verwendet Windows API EnumDisplayMonitors
    ; Rückgabe: Array mit Monitor-Informationen
    ; [0] = Anzahl Monitore
    ; [n][0] = Breite
    ; [n][1] = Höhe
    ; [n][2] = X-Position (left)
    ; [n][3] = Y-Position (top)
EndFunc
```

### Slider-Animation

```autoit
Func _SLIDEWINDOW($hWindow, $aScreenValues, $iScreenNum, $sDirection, $sInOrOut)
    ; Parameter:
    ; - $hWindow: Handle des GUI-Fensters
    ; - $aScreenValues: Array mit Monitor-Daten
    ; - $iScreenNum: Aktuelle Monitor-Nummer
    ; - $sDirection: "Left", "Right", "Top", "Bottom"
    ; - $sInOrOut: "In" oder "Out"
    
    ; Animation in 10 Schritten
    ; Sleep(20) zwischen jedem Schritt für smooth animation
EndFunc
```

## Datenstrukturen

### Globale Variablen

```autoit
; Slider-Status
Global $BWINDOWSISOUT = False      ; GUI ausgefahren?
Global $SWINDOWSISAT = "Top"        ; Aktuelle Position

; Monitor-Informationen
Global $ICURSCREENX                 ; X-Position aktueller Monitor
Global $ICURSCREENY                 ; Y-Position aktueller Monitor
Global $ICURSCREENWIDTH             ; Breite aktueller Monitor
Global $ICURSCREENHEIGHT            ; Höhe aktueller Monitor
Global $ICURRENTSCREENNUMBER        ; Nummer aktueller Monitor

; Bewegungsrichtung
Global $SWITCHSIDE                  ; Aktuelle Bewegungsrichtung
```

### Monitor-Array-Struktur

```autoit
; $aMonitors[0][0] = Anzahl der Monitore
; $aMonitors[n][0] = Breite des Monitors n
; $aMonitors[n][1] = Höhe des Monitors n
; $aMonitors[n][2] = X-Position (links)
; $aMonitors[n][3] = Y-Position (oben)
```

## Algorithmen

### Monitor-Nachbarschaftserkennung

```autoit
Func _FindAdjacentMonitor($aMonitors, $iCurrentMonitor, $sDirection)
    ; Algorithmus:
    ; 1. Bestimme Kanten des aktuellen Monitors
    ; 2. Prüfe alle anderen Monitore auf Überlappung
    ; 3. Berücksichtige Toleranz für nicht-perfekte Ausrichtung
    ; 4. Rückgabe: Monitor-Nummer oder -1 wenn kein Nachbar
EndFunc
```

### Bewegungsvalidierung

```autoit
Func _CanMoveInDirection($aMonitors, $iCurrentMonitor, $sDirection)
    ; Prüft ob Bewegung in Richtung möglich ist
    ; - Bei angrenzenden Monitoren: False (direkter Wechsel)
    ; - Ohne angrenzende Monitore: True (Ausfahren möglich)
EndFunc
```

## Windows API Integration

### EnumDisplayMonitors Callback

```autoit
Func MonitorEnumProc($hMonitor, $hDC, $pRect, $lParam)
    ; Callback-Funktion für EnumDisplayMonitors
    ; Sammelt Monitor-Informationen in DllStruct
    ; Rückgabe: 1 für Fortsetzung der Enumeration
EndFunc
```

### DLL-Aufrufe

```autoit
; User32.dll für Monitor-Funktionen
DllCall("User32.dll", "ubyte", "EnumDisplayMonitors", ...)

; Für erweiterte Funktionen
; - GetMonitorInfo
; - MonitorFromWindow
; - GetSystemMetrics
```

## Performance-Optimierungen

### Animation
- 10 Schritte für Balance zwischen Flüssigkeit und Performance
- 20ms Delay zwischen Schritten (50 FPS)
- Vorberechnung der Positionen

### Monitor-Erkennung
- Caching der Monitor-Konfiguration
- Nur bei WM_DISPLAYCHANGE neu laden
- Effiziente Nachbarschaftsberechnung

## Fehlerbehandlung

### Monitor-Änderungen
- Erkennung von Monitor-Verbindung/-Trennung
- Graceful Degradation bei fehlenden Monitoren
- Rückfall auf Primärmonitor

### GUI-Zustand
- Konsistenz-Checks für Position
- Recovery bei ungültigen Zuständen
- Logging für Debugging

## Konfiguration

### settings.ini Struktur

```ini
[General]
DefaultPosition=Top
AnimationSpeed=20
AnimationSteps=10

[Hotkeys]
SlideLeft=^{LEFT}
SlideRight=^{RIGHT}
SlideUp=^{UP}
SlideDown=^{DOWN}

[Advanced]
MonitorTolerance=5
EnableLogging=True
LogLevel=INFO
```

---

**Dokumentversion**: 1.0  
**Letzte Aktualisierung**: 27.05.2025
