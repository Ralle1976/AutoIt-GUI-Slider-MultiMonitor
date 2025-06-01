# Arbeitsbericht - 31.05.2025

## Problemanalyse: Auto-Slide GUI fährt nicht wieder aus

### Problem
Nach dem automatischen Einfahren (Auto-Slide IN) der GUI muss man erneut den Button drücken, damit die GUI wieder ausfährt. Die GUI "vergisst" die manuelle Slide-Richtung.

### Ursache
Das Problem liegt in der Verwaltung der Variable `$g_sSwitchSide`:

1. **Beim manuellen Button-Klick**: `$g_sSwitchSide` wird auf die gewünschte Richtung gesetzt (z.B. "Right")
2. **Beim Auto-Slide IN**: Die GUI wird zentriert (`$g_sWindowIsAt = "Center"`), aber `$g_sSwitchSide` wird nicht für den nächsten manuellen Klick aufbewahrt
3. **Beim nächsten Button-Klick**: Die GUI denkt, sie müsste erst die Richtung setzen, statt direkt auszufahren

### Lösung

#### 1. SliderLogic.au3 - Richtung beim Auto-Slide beibehalten
```autoit
; In _SlideWindow() - Zeile 30-50
If $bResult Then
    ; WICHTIG: Überschreibe g_sSwitchSide nur bei manuellen Slides, NICHT bei Auto-Slide!
    If Not $g_bAutoSlideActive_Internal Then
        $g_sSwitchSide = $sSide
        _LogDebug("Manueller Slide: g_sSwitchSide auf '" & $sSide & "' gesetzt")
    Else
        _LogDebug("Auto-Slide: g_sSwitchSide NICHT überschrieben (bleibt: '" & $g_sSwitchSide & "')")
    EndIf
    
    ; Bei Auto-Slide IN behalte die vorherige Slide-Richtung für den nächsten manuellen Klick
    If $g_bAutoSlideActive_Internal And $sInOrOut = $ANIM_IN Then
        _LogDebug("Auto-Slide IN: Behalte g_sSwitchSide='" & $g_sSwitchSide & "' für nächsten manuellen Slide")
    EndIf
EndIf
```

#### 2. GUIControl.au3 - Button-Handler angepasst
Alle Button-Handler (Left, Right, Up, Down) prüfen nun zusätzlich:
```autoit
ElseIf Not $g_bWindowIsOut And $g_sSwitchSide = $POS_RIGHT Then
    ; GUI ist zentriert, aber letzte manuelle Richtung war RIGHT -> Slide OUT
    _LogDebug("GUI zentriert, aber g_sSwitchSide='RIGHT' -> Slide OUT")
    _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
```

#### 3. ConfigManager.au3 - Persistenz der Slide-Richtung
Die letzte Slide-Richtung wird nun in der Konfiguration gespeichert:
```autoit
; Beim Laden
$g_sSwitchSide = IniRead($g_sConfigFile, "General", "LastSlideDirection", $POS_TOP)

; Beim Speichern
IniWrite($g_sConfigFile, "General", "LastSlideDirection", $g_sSwitchSide)
```

### Geänderte Dateien
1. `/src/modules/SliderLogic.au3` - Auto-Slide Logik verbessert
2. `/src/modules/GUIControl.au3` - Button-Handler für alle Richtungen angepasst
3. `/src/modules/ConfigManager.au3` - Persistenz der Slide-Richtung hinzugefügt

### Testergebnis
Nach den Änderungen sollte die GUI nach einem Auto-Slide IN beim nächsten Button-Klick direkt wieder in die gleiche Richtung ausfahren, ohne dass ein zweiter Klick nötig ist.

### Weitere Verbesserungen
- Die Lösung funktioniert für alle Slider-Modi (Standard, Classic, Direct, Continuous)
- Die letzte Slide-Richtung bleibt auch nach einem Programmneustart erhalten
- Logging wurde verbessert für besseres Debugging