# Auto-Slide-In Feature und Bugfixes

## Gelöste Probleme

### 1. Doppelte `_LogMonitorInfo()` Funktion
**Problem**: Die Funktion war doppelt definiert durch falsches `#include-once` in main.au3

**Lösung**: 
- Entfernt `#include-once` aus main.au3 (gehört nur in Module, nicht in die Hauptdatei)
- `#include-once` bleibt in allen Modulen erhalten

### 2. Auto-Slide-In Feature implementiert
**Problem**: GUI bleibt ausgefahren und kommt nicht automatisch zurück

**Lösung mit AdlibRegister**:
- Neue Funktion `_CheckAutoSlideIn()` prüft alle 250ms ob die Maus über der GUI ist
- Wenn GUI ausgefahren ist und Maus darüber, wird automatisch eingeslided
- Verwendet `AdlibRegister()` statt While-Schleife für bessere Performance

## Neue Features

### Auto-Slide-In Funktionalität
- **Funktion**: `_CheckAutoSlideIn()` in GUIControl.au3
- **Aktivierung**: Automatisch beim Start wenn in Konfiguration aktiviert
- **Konfiguration**: 
  - `AutoSlideIn=1` (aktiviert/deaktiviert)
  - `AutoSlideInDelay=250` (Prüfintervall in ms)
- **Toleranz**: 10 Pixel um die GUI herum

### Zusätzliche Funktionen
- `_EnableAutoSlideIn()`: Aktiviert das Feature zur Laufzeit
- `_DisableAutoSlideIn()`: Deaktiviert das Feature zur Laufzeit

## Technische Details

### AdlibRegister Vorteile
- Läuft unabhängig von der Hauptschleife
- Kein Performance-Impact auf andere Funktionen
- Saubere Trennung der Funktionalitäten
- Einfach zu aktivieren/deaktivieren

### Implementierung
```autoit
; Registrierung beim Start
If $bAutoSlideIn Then
    AdlibRegister("_CheckAutoSlideIn", $iAutoSlideInDelay)
EndIf

; Prüfung in der Funktion
If $bMouseOverGUI Then
    _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $g_sWindowIsAt, $ANIM_IN)
EndIf
```

## Konfiguration

In der `settings.ini`:
```ini
[Behavior]
AutoSlideIn=1          ; 1=aktiviert, 0=deaktiviert
AutoSlideInDelay=250   ; Prüfintervall in Millisekunden
```

## Nutzung

1. **Standard**: Auto-Slide-In ist standardmäßig aktiviert
2. **Deaktivierung**: Setze `AutoSlideIn=0` in der Konfiguration
3. **Anpassung**: Ändere `AutoSlideInDelay` für schnellere/langsamere Reaktion
4. **Zur Laufzeit**: 
   - `_DisableAutoSlideIn()` zum temporären Deaktivieren
   - `_EnableAutoSlideIn()` zum Reaktivieren
