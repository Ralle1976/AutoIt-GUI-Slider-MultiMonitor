# Visualizer Verbesserungen - Realistische Implementierung

## Machbare Verbesserungen für AutoIt

### ✅ EDID-basierte Monitor-Erkennung (EMPFOHLEN)
```autoit
; EDID-Daten aus Registry lesen für eindeutige Monitor-Identifikation
Func _GetMonitorEDID($sDeviceName)
    ; Registry-Pfad für EDID-Daten
    Local $sBaseKey = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\DISPLAY"
    Local $i = 1
    
    While 1
        Local $sMonKey = RegEnumKey($sBaseKey, $i)
        If @error Then ExitLoop
        
        Local $j = 1
        While 1
            Local $sDevKey = RegEnumKey($sBaseKey & "\" & $sMonKey, $j)
            If @error Then ExitLoop
            
            ; Lese EDID Binary-Daten
            Local $sEDID = RegRead($sBaseKey & "\" & $sMonKey & "\" & $sDevKey & "\Device Parameters", "EDID")
            If Not @error Then
                ; Parse EDID für Monitor-Name
                Local $sModelName = _ParseEDIDName($sEDID)
                If $sModelName <> "" Then Return $sModelName
            EndIf
            $j += 1
        WEnd
        $i += 1
    WEnd
    
    Return "Generic Monitor"
EndFunc

; EDID Binary-Daten parsen
Func _ParseEDIDName($bEDID)
    If StringLen($bEDID) < 256 Then Return ""
    
    ; Monitor-Name beginnt typischerweise bei Byte 0x48 (72)
    Local $sName = ""
    For $i = 145 To 256 Step 2
        Local $sByte = StringMid($bEDID, $i, 2)
        Local $iChar = Dec($sByte)
        If $iChar = 0x0A Or $iChar = 0x00 Then ExitLoop
        If $iChar >= 0x20 And $iChar <= 0x7E Then
            $sName &= Chr($iChar)
        EndIf
    Next
    
    Return StringStripWS($sName, 3)
EndFunc
```

### ✅ WM_DISPLAYCHANGE für Live-Updates (SEHR EINFACH)
```autoit
; Registriere Message-Handler für Monitor-Änderungen
Global Const $WM_DISPLAYCHANGE = 0x007E
GUIRegisterMsg($WM_DISPLAYCHANGE, "_OnDisplayChange")

Func _OnDisplayChange($hWnd, $iMsg, $wParam, $lParam)
    ; $wParam = neue Farbtiefe
    ; $lParam = neue Auflösung (LOWORD = Breite, HIWORD = Höhe)
    _LogInfo("Monitor-Konfiguration geändert! Farbtiefe: " & $wParam)
    
    ; Verzögerte Aktualisierung für Stabilität
    AdlibRegister("_RefreshMonitorConfiguration", 500)
    
    Return $GUI_RUNDEFMSG
EndFunc

Func _RefreshMonitorConfiguration()
    AdlibUnRegister("_RefreshMonitorConfiguration")
    
    ; Monitore neu erkennen
    _GetMonitors()
    
    ; Visualizer aktualisieren
    If IsHWnd($g_hVisualizerGUI) Then
        _ClearVisualization()
        _UpdateVisualization()
    EndIf
    
    _LogInfo("Monitor-Konfiguration aktualisiert")
EndFunc
```

### ✅ Verbesserte _WinAPI_Enum Funktionen (BEREITS VORHANDEN)
```autoit
#include <WinAPIGdi.au3>

; Nutze AutoIt's eingebaute Funktionen optimal
Func _GetMonitorsEnhanced()
    ; Hole alle Display-Geräte
    Local $aDevice, $aMonitors[1][5] = [[0]]
    Local $i = 0
    
    While 1
        $aDevice = _WinAPI_EnumDisplayDevices("", $i)
        If @error Then ExitLoop
        
        If BitAND($aDevice[3], 0x00000001) Then ; DISPLAY_DEVICE_ACTIVE
            Local $aSettings = _WinAPI_EnumDisplaySettings($aDevice[0], -1)
            If Not @error Then
                ReDim $aMonitors[UBound($aMonitors) + 1][5]
                $aMonitors[0][0] += 1
                Local $idx = $aMonitors[0][0]
                
                $aMonitors[$idx][0] = $aSettings[0] ; Width
                $aMonitors[$idx][1] = $aSettings[1] ; Height
                $aMonitors[$idx][2] = $aSettings[4] ; X
                $aMonitors[$idx][3] = $aSettings[5] ; Y
                $aMonitors[$idx][4] = $aDevice[1]   ; Device String
            EndIf
        EndIf
        $i += 1
    WEnd
    
    Return $aMonitors
EndFunc
```

## Enhanced Visualizer Features

### ✅ Live-Mauszeiger (EINFACH UMSETZBAR)
```autoit
Func _DrawMouseCursor()
    Local $aPos = MouseGetPos()
    Local $iMonitor = _GetMonitorAtPoint($aPos[0], $aPos[1])
    
    ; Zeichne Mauszeiger im Visualizer
    Local $iScaledX = _ConvertToVisualizerX($aPos[0])
    Local $iScaledY = _ConvertToVisualizerY($aPos[1])
    
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xFFFFFF00) ; Gelb
    _GDIPlus_GraphicsFillEllipse($g_hBackBuffer, $iScaledX-3, $iScaledY-3, 6, 6, $hBrush)
    _GDIPlus_BrushDispose($hBrush)
EndFunc
```

### ✅ Monitor-Tooltips mit Details (EINFACH)
```autoit
; Zeige Monitor-Details beim Hover
Func _ShowMonitorTooltip($iMonitor)
    Local $sInfo = "Monitor " & $iMonitor & @CRLF
    $sInfo &= "Auflösung: " & $g_aMonitors[$iMonitor][0] & "x" & $g_aMonitors[$iMonitor][1] & @CRLF
    $sInfo &= "Position: " & $g_aMonitors[$iMonitor][2] & "," & $g_aMonitors[$iMonitor][3] & @CRLF
    
    ; EDID-Name wenn verfügbar
    If UBound($g_aMonitorDetails) > $iMonitor Then
        Local $sEDIDName = _GetMonitorEDID($g_aMonitorDetails[$iMonitor][0])
        $sInfo &= "Modell: " & $sEDIDName & @CRLF
    EndIf
    
    ToolTip($sInfo)
    AdlibRegister("_HideTooltip", 3000)
EndFunc
```

### ✅ DPI-Awareness (Windows 8.1+)
```autoit
; Nur für Windows 8.1+
Func _GetMonitorDPI($hMonitor)
    ; Prüfe Windows-Version
    If Not _IsWindows81OrNewer() Then Return 96
    
    Local $iDpiX = 96, $iDpiY = 96
    Local $MDT_EFFECTIVE_DPI = 0
    
    Local $aResult = DllCall("shcore.dll", "long", "GetDpiForMonitor", _
            "handle", $hMonitor, _
            "int", $MDT_EFFECTIVE_DPI, _
            "uint*", $iDpiX, _
            "uint*", $iDpiY)
    
    If @error Or $aResult[0] <> 0 Then Return 96
    
    Return $iDpiX
EndFunc

Func _IsWindows81OrNewer()
    Return Number(RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CurrentVersion")) >= 6.3
EndFunc
```

## Sofort umsetzbare Verbesserungen

### 1. ✅ Monitor-Stabilität durch EDID
```autoit
; Verwende EDID als eindeutige Monitor-ID statt Windows-Nummer
Global $g_aMonitorEDID[13] ; EDID-basierte IDs pro Monitor

Func _CreateStableMonitorMapping()
    For $i = 1 To $g_iMonitorCount
        ; Hole EDID für stabiles Mapping
        Local $sEDID = _GetMonitorEDID($g_aMonitorDetails[$i][0])
        $g_aMonitorEDID[$i] = $sEDID
        
        ; Speichere Mapping in INI
        IniWrite($g_sConfigFile, "MonitorMapping", $sEDID, $i)
    Next
EndFunc

; Finde Monitor anhand EDID statt Position
Func _GetMonitorByEDID($sEDID)
    For $i = 1 To $g_iMonitorCount
        If $g_aMonitorEDID[$i] = $sEDID Then Return $i
    Next
    Return 0
EndFunc
```

### 2. ✅ Visualizer-Zoom für große Setups
```autoit
; Mausrad-Zoom im Visualizer
Global $g_fVisualizerZoom = 1.0
Global Const $WM_MOUSEWHEEL = 0x020A

GUIRegisterMsg($WM_MOUSEWHEEL, "_OnMouseWheel")

Func _OnMouseWheel($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd <> $g_hVisualizerGUI Then Return $GUI_RUNDEFMSG
    
    Local $iDelta = BitShift($wParam, 16) / 120
    $g_fVisualizerZoom += $iDelta * 0.1
    
    ; Begrenze Zoom
    If $g_fVisualizerZoom < 0.5 Then $g_fVisualizerZoom = 0.5
    If $g_fVisualizerZoom > 3.0 Then $g_fVisualizerZoom = 3.0
    
    _UpdateVisualization()
    Return 0
EndFunc
```

## Realistische Implementierungs-Roadmap

### Phase 1: Basis-Verbesserungen (1-2 Tage)
- ✅ **WM_DISPLAYCHANGE** implementieren (bereits oben gezeigt)
- ✅ **EDID-Auslesung** für stabile Monitor-IDs
- ✅ **_WinAPI_Enum** Funktionen optimal nutzen
- ✅ **Live-Mauszeiger** im Visualizer

### Phase 2: Erweiterte Features (3-5 Tage)
- ✅ **Monitor-Tooltips** mit Details
- ✅ **Visualizer-Zoom** mit Mausrad
- ⛔ **DPI-Awareness** (nur Windows 8.1+)
- ⛔ **Monitor-Profile** speichern/laden

### Phase 3: Komplexere Features (Optional)
- ❌ **QueryDisplayConfig API** (zu komplex ohne Beispiele)
- ⛔ **Drag & Drop** im Visualizer (mittlerer Aufwand)
- ⛔ **Portrait-Monitor** Erkennung

## Empfehlung

**Starten Sie mit Phase 1** - diese Verbesserungen sind:
- Schnell umsetzbar (1-2 Tage)
- Bringen sofortigen Nutzen
- Haben geringes Fehlerrisiko
- Sind mit Standard-AutoIt-Funktionen machbar

**EDID + WM_DISPLAYCHANGE** sind die wichtigsten Verbesserungen für:
- Stabile Monitor-Erkennung (Monitor wechselt nicht mehr die Nummer)
- Live-Updates bei Konfigurationsänderungen
- Eindeutige Monitor-Identifikation