# Windows 11 Style Visualizer - Verbesserungskonzept

## Analyse: Windows 11 vs. Aktueller Visualizer

### Windows 11 Anzeigeeinstellungen zeigt:
1. **Proportionale Darstellung** - Monitore werden in korrektem Größenverhältnis angezeigt
2. **Nummerierung in Monitoren** - Große Nummern in der Mitte jedes Monitors
3. **Identifizieren-Button** - Zeigt Nummern auf echten Monitoren
4. **Drag & Drop** - Monitore können verschoben werden
5. **Auswahl-Highlighting** - Ausgewählter Monitor wird hervorgehoben
6. **Realistische Abstände** - Monitore können Lücken haben oder überlappen

### Unser aktueller Visualizer:
1. ✅ Zeigt alle Monitore
2. ✅ Zeigt Auflösungen
3. ❌ Skalierung stimmt nicht immer (besonders bei DPI-Skalierung)
4. ❌ Monitor-Nummern sind zu klein
5. ❌ Keine interaktiven Features

## Verbesserungskonzept für Windows 11 Style

### Phase 1: Korrekte Proportionen und Darstellung

#### 1.1 DPI-bewusste Skalierung
```autoit
; Neue Funktion für korrekte Monitor-Proportionen
Func _CalculateMonitorProportions()
    ; Basis-Referenz: 96 DPI = 100%
    Local $fBaseDPI = 96.0
    
    ; Für jeden Monitor die effektive Größe berechnen
    For $i = 1 To $g_iMonitorCount
        ; Hole DPI-Skalierung wenn möglich
        Local $fScaling = 1.0 ; Default 100%
        
        ; Windows kennt typische Skalierungen: 100%, 125%, 150%, 175%, 200%
        ; Berechne aus effektiver vs. physischer Auflösung
        If UBound($g_aMonitorDetails) > $i Then
            ; Wenn 4K Monitor als 2560x1440 gemeldet wird = 150% Skalierung
            If $g_aMonitors[$i][0] = 2560 And $g_aMonitors[$i][1] = 1440 Then
                ; Prüfe ob es eigentlich ein 4K Monitor ist
                Local $sDeviceName = $g_aMonitorDetails[$i][0]
                Local $aPhysical = _GetPhysicalResolution($sDeviceName)
                If $aPhysical[0] = 3840 And $aPhysical[1] = 2160 Then
                    $fScaling = 1.5 ; 150%
                EndIf
            EndIf
        EndIf
        
        ; Speichere Skalierungsfaktor
        $g_aMonitorScaling[$i] = $fScaling
    Next
EndFunc
```

#### 1.2 Windows 11 Style Monitor-Darstellung
```autoit
Func _DrawMonitorsWindows11Style()
    ; Hintergrund in Windows 11 Farbe
    Local $COLOR_WIN11_BG = 0xFFF3F3F3     ; Helles Grau
    Local $COLOR_WIN11_MONITOR = 0xFF0078D4 ; Windows Blau
    Local $COLOR_WIN11_SELECTED = 0xFF005A9E ; Dunkleres Blau
    Local $COLOR_WIN11_BORDER = 0xFFE5E5E5  ; Rand
    
    ; Clear mit Windows 11 Hintergrund
    _GDIPlus_GraphicsClear($g_hBackBuffer, $COLOR_WIN11_BG)
    
    ; Berechne Layout mit Mindestabstand zwischen Monitoren
    Local $fMinGap = 10 ; Mindestens 10 Pixel zwischen Monitoren im Visualizer
    
    For $i = 1 To $g_aMonitors[0][0]
        ; Monitor-Rechteck mit abgerundeten Ecken
        Local $hPath = _GDIPlus_PathCreate()
        _GDIPlus_PathAddRoundRect($hPath, $iX, $iY, $iW, $iH, 8) ; 8px Radius
        
        ; Füllung
        Local $hBrush = _GDIPlus_BrushCreateSolid($COLOR_WIN11_MONITOR)
        If $i = $g_iCurrentScreenNumber Then
            $hBrush = _GDIPlus_BrushCreateSolid($COLOR_WIN11_SELECTED)
        EndIf
        _GDIPlus_GraphicsFillPath($g_hBackBuffer, $hPath, $hBrush)
        
        ; Rand
        Local $hPen = _GDIPlus_PenCreate($COLOR_WIN11_BORDER, 1)
        _GDIPlus_GraphicsDrawPath($g_hBackBuffer, $hPath, $hPen)
        
        ; Große Monitor-Nummer in der Mitte
        Local $sFontFamily = _GDIPlus_FontFamilyCreate("Segoe UI")
        Local $iFontSize = Int(Min($iW, $iH) * 0.3) ; 30% der kleineren Dimension
        If $iFontSize < 20 Then $iFontSize = 20
        If $iFontSize > 60 Then $iFontSize = 60
        
        Local $hFont = _GDIPlus_FontCreate($sFontFamily, $iFontSize, 0)
        Local $hBrushText = _GDIPlus_BrushCreateSolid(0xFFFFFFFF) ; Weiß
        
        ; Nummer zentriert
        Local $sNumber = String($i)
        Local $tLayout = _GDIPlus_RectFCreate($iX, $iY + ($iH - $iFontSize)/2, $iW, $iFontSize)
        Local $hFormat = _GDIPlus_StringFormatCreate()
        _GDIPlus_StringFormatSetAlign($hFormat, 1) ; Center
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sNumber, $hFont, $tLayout, $hFormat, $hBrushText)
        
        ; Kleine Auflösung unten
        Local $hFontSmall = _GDIPlus_FontCreate($sFontFamily, 9, 0)
        Local $tLayoutSmall = _GDIPlus_RectFCreate($iX, $iY + $iH - 20, $iW, 20)
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $g_aMonitors[$i][0] & " × " & $g_aMonitors[$i][1], _
                                     $hFontSmall, $tLayoutSmall, $hFormat, $hBrushText)
        
        ; Aufräumen
        _GDIPlus_PathDispose($hPath)
        _GDIPlus_BrushDispose($hBrush)
        _GDIPlus_PenDispose($hPen)
        _GDIPlus_FontDispose($hFont)
        _GDIPlus_FontDispose($hFontSmall)
        _GDIPlus_FontFamilyDispose($sFontFamily)
        _GDIPlus_StringFormatDispose($hFormat)
        _GDIPlus_BrushDispose($hBrushText)
    Next
EndFunc
```

### Phase 2: Interaktive Features

#### 2.1 Monitor-Auswahl per Klick
```autoit
; In Message-Handler
Case $WM_LBUTTONDOWN
    If $hWnd = $g_hVisualizerGUI Then
        Local $iX = BitAND($lParam, 0xFFFF)
        Local $iY = BitShift($lParam, 16)
        
        ; Welcher Monitor wurde geklickt?
        Local $iClickedMonitor = _GetMonitorAtVisualizerPoint($iX, $iY)
        If $iClickedMonitor > 0 Then
            $g_iCurrentScreenNumber = $iClickedMonitor
            _UpdateVisualization()
        EndIf
    EndIf
```

#### 2.2 Monitor-Info Tooltip
```autoit
; Mouse-Move Handler für Tooltips
Case $WM_MOUSEMOVE
    If $hWnd = $g_hVisualizerGUI Then
        Local $iX = BitAND($lParam, 0xFFFF)
        Local $iY = BitShift($lParam, 16)
        
        Local $iHoverMonitor = _GetMonitorAtVisualizerPoint($iX, $iY)
        Static $iLastHoverMonitor = 0
        
        If $iHoverMonitor <> $iLastHoverMonitor Then
            If $iHoverMonitor > 0 Then
                ; Zeige Tooltip mit Details
                Local $sInfo = "Monitor " & $iHoverMonitor & @CRLF
                $sInfo &= "Auflösung: " & $g_aMonitors[$iHoverMonitor][0] & " × " & $g_aMonitors[$iHoverMonitor][1] & @CRLF
                $sInfo &= "Position: " & $g_aMonitors[$iHoverMonitor][2] & ", " & $g_aMonitors[$iHoverMonitor][3]
                
                ; DPI-Info wenn verfügbar
                If $g_aMonitorScaling[$iHoverMonitor] > 1.0 Then
                    $sInfo &= @CRLF & "Skalierung: " & Int($g_aMonitorScaling[$iHoverMonitor] * 100) & "%"
                EndIf
                
                ToolTip($sInfo, MouseGetPos(0) + 10, MouseGetPos(1) + 10)
            Else
                ToolTip("")
            EndIf
            $iLastHoverMonitor = $iHoverMonitor
        EndIf
    EndIf
```

### Phase 3: Erweiterte Darstellung

#### 3.1 Monitor-Identifikation (wie Windows 11)
```autoit
; Zeige große Nummern auf echten Monitoren
Func _IdentifyMonitors()
    Local $aIdentifyGUIs[$g_iMonitorCount + 1]
    
    For $i = 1 To $g_iMonitorCount
        ; Erstelle transparentes Vollbild-Fenster pro Monitor
        Local $hIdentifyGUI = GUICreate("", $g_aMonitors[$i][0], $g_aMonitors[$i][1], _
                                       $g_aMonitors[$i][2], $g_aMonitors[$i][3], _
                                       $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TRANSPARENT, $WS_EX_TOPMOST))
        
        ; Setze Transparenz
        _WinAPI_SetLayeredWindowAttributes($hIdentifyGUI, 0x000000, 0, $LWA_COLORKEY)
        
        ; Zeichne große Nummer
        Local $hGraphic = _GDIPlus_GraphicsCreateFromHWND($hIdentifyGUI)
        Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
        Local $hBrushBg = _GDIPlus_BrushCreateSolid(0xCCFFFFFF)
        
        ; Hintergrund-Kreis
        Local $iSize = 200
        Local $iX = ($g_aMonitors[$i][0] - $iSize) / 2
        Local $iY = ($g_aMonitors[$i][1] - $iSize) / 2
        _GDIPlus_GraphicsFillEllipse($hGraphic, $iX, $iY, $iSize, $iSize, $hBrushBg)
        
        ; Nummer
        Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 120, 0)
        Local $tLayout = _GDIPlus_RectFCreate($iX, $iY + 20, $iSize, $iSize)
        Local $hFormat = _GDIPlus_StringFormatCreate()
        _GDIPlus_StringFormatSetAlign($hFormat, 1)
        _GDIPlus_GraphicsDrawStringEx($hGraphic, String($i), $hFont, $tLayout, $hFormat, $hBrush)
        
        GUISetState(@SW_SHOWNOACTIVATE, $hIdentifyGUI)
        $aIdentifyGUIs[$i] = $hIdentifyGUI
        
        ; Cleanup
        _GDIPlus_GraphicsDispose($hGraphic)
        _GDIPlus_BrushDispose($hBrush)
        _GDIPlus_BrushDispose($hBrushBg)
        _GDIPlus_FontDispose($hFont)
        _GDIPlus_StringFormatDispose($hFormat)
    Next
    
    ; Zeige für 2 Sekunden
    Sleep(2000)
    
    ; Schließe alle
    For $i = 1 To $g_iMonitorCount
        GUIDelete($aIdentifyGUIs[$i])
    Next
EndFunc
```

## Implementierungsplan

### Schritt 1: Basis-Verbesserungen (Tag 1)
1. **DPI-Skalierung** korrekt berechnen
2. **Windows 11 Farben** implementieren
3. **Große Monitor-Nummern** wie in Windows 11

### Schritt 2: Interaktivität (Tag 2)
1. **Monitor-Auswahl** per Klick
2. **Hover-Tooltips** mit Details
3. **Highlight** für ausgewählten Monitor

### Schritt 3: Erweiterte Features (Tag 3)
1. **Identifizieren-Button** 
2. **Bessere Proportionen** mit DPI-Awareness
3. **Monitor-Namen** aus EDID

## Erwartetes Ergebnis
- Visualizer sieht aus wie Windows 11 Anzeigeeinstellungen
- Korrekte Proportionen auch bei DPI-Skalierung
- Interaktive Bedienung
- Professionelles Aussehen