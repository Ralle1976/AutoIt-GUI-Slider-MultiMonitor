#include-once
#include <GDIPlus.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <Math.au3>
#include <WinAPIGdi.au3>
#include <WinAPIGdiDC.au3>
#include <WinAPISysWin.au3>
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "MonitorDetection.au3"
#include "Logging.au3"

; ==========================================
; Windows 11 Style Monitor Visualisierung
; ==========================================

Global $g_hVisualizerGUI = 0
Global $g_hGraphics = 0
Global $g_hBitmap = 0
Global $g_hBackBuffer = 0
Global $g_iVisWidth = 600
Global $g_iVisHeight = 400
Global $g_fScale = 0.1  ; Skalierungsfaktor für die Darstellung

; Windows 11 Farben
Global Const $COLOR_WIN11_BG = 0xFFF3F3F3        ; Heller Hintergrund
Global Const $COLOR_WIN11_MONITOR = 0xFF0078D4   ; Windows Blau
Global Const $COLOR_WIN11_SELECTED = 0xFF005A9E  ; Dunkleres Blau für Auswahl
Global Const $COLOR_WIN11_BORDER = 0xFFD6D6D6    ; Monitor-Rand
Global Const $COLOR_WIN11_TEXT = 0xFFFFFFFF      ; Weißer Text
Global Const $COLOR_WIN11_SHADOW = 0x20000000    ; Leichter Schatten


; Monitor-Skalierungsfaktoren
Global $g_aMonitorScaling[13] ; DPI-Skalierung pro Monitor

; Hover-Status
Global $g_iHoveredMonitor = 0
Global $g_iLastHoveredMonitor = 0

; Initialisiert die Windows 11 Style Visualisierung
Func _InitVisualization()
    _LogInfo("Initialisiere Windows 11 Style Monitor-Visualisierung...")

    ; GDI+ initialisieren
    _GDIPlus_Startup()

    ; Visualisierungs-GUI erstellen
    $g_hVisualizerGUI = GUICreate("Anzeigeeinstellungen - GUI Slider", $g_iVisWidth, $g_iVisHeight, -1, -1, _
                                  BitOR($WS_POPUP, $WS_BORDER), BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST))

    If Not IsHWnd($g_hVisualizerGUI) Then
        _LogError("Konnte Visualisierungs-GUI nicht erstellen")
        Return False
    EndIf

    ; GDI+ Objekte erstellen
    $g_hGraphics = _GDIPlus_GraphicsCreateFromHWND($g_hVisualizerGUI)
    $g_hBitmap = _GDIPlus_BitmapCreateFromGraphics($g_iVisWidth, $g_iVisHeight, $g_hGraphics)
    $g_hBackBuffer = _GDIPlus_ImageGetGraphicsContext($g_hBitmap)

    ; Anti-Aliasing aktivieren
    _GDIPlus_GraphicsSetSmoothingMode($g_hBackBuffer, 4) ; SmoothingModeAntiAlias8x8
    _GDIPlus_GraphicsSetTextRenderingHint($g_hBackBuffer, 5) ; TextRenderingHintAntiAliasGridFit

    ; Skalierung berechnen
    _CalculateScale()

    ; GUI positionieren (rechts unten)
    Local $iX = @DesktopWidth - $g_iVisWidth - 20
    Local $iY = @DesktopHeight - $g_iVisHeight - 60
    WinMove($g_hVisualizerGUI, "", $iX, $iY)

    ; Message-Handler registrieren
    GUIRegisterMsg($WM_LBUTTONDOWN, "_OnVisualizerClick")
    GUIRegisterMsg($WM_MOUSEMOVE, "_OnVisualizerMouseMove")
    GUIRegisterMsg($WM_MOUSELEAVE, "_OnVisualizerMouseLeave")

    ; GUI anzeigen
    GUISetState(@SW_SHOW, $g_hVisualizerGUI)

    ; WICHTIG: Sofort die erste Visualisierung zeichnen
    _UpdateVisualization()

    _LogInfo("Windows 11 Style Monitor-Visualisierung initialisiert und gezeichnet")
    Return True
EndFunc

; Berechnet den optimalen Skalierungsfaktor
Func _CalculateScale()
    If Not IsArray($g_aMonitors) Or $g_aMonitors[0][0] = 0 Then
        _LogError("_CalculateScale: Keine Monitor-Daten verfügbar")
        Return
    EndIf

    ; Berechne DPI-Skalierung für jeden Monitor
    _CalculateMonitorScaling()

    ; Finde die Gesamtgröße aller Monitore
    Local $iMinX = 99999, $iMinY = 99999
    Local $iMaxX = -99999, $iMaxY = -99999

    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iMinX Then $iMinX = $g_aMonitors[$i][2]
        If $g_aMonitors[$i][3] < $iMinY Then $iMinY = $g_aMonitors[$i][3]
        If $g_aMonitors[$i][2] + $g_aMonitors[$i][0] > $iMaxX Then $iMaxX = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $g_aMonitors[$i][3] + $g_aMonitors[$i][1] > $iMaxY Then $iMaxY = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
    Next

    Local $iTotalWidth = $iMaxX - $iMinX
    Local $iTotalHeight = $iMaxY - $iMinY

    ; Skalierung mit mehr Rand berechnen (Windows 11 Style)
    Local $iAvailableWidth = $g_iVisWidth - 80   ; 40px Rand links und rechts
    Local $iAvailableHeight = $g_iVisHeight - 120  ; 60px oben und unten

    Local $fScaleX = ($iTotalWidth > 0) ? ($iAvailableWidth / $iTotalWidth) : 1.0
    Local $fScaleY = ($iTotalHeight > 0) ? ($iAvailableHeight / $iTotalHeight) : 1.0

    $g_fScale = ($fScaleX < $fScaleY) ? $fScaleX : $fScaleY
    
    ; Begrenze Skalierung
    If $g_fScale < 0.05 Then $g_fScale = 0.05
    If $g_fScale > 2.0 Then $g_fScale = 2.0  ; Nicht zu groß

    _LogDebug("Windows 11 Visualisierungs-Skalierung: " & $g_fScale)
EndFunc

; Berechnet DPI-Skalierung für jeden Monitor
Func _CalculateMonitorScaling()
    For $i = 1 To $g_iMonitorCount
        $g_aMonitorScaling[$i] = 1.0 ; Default 100%
        
        ; Erkenne DPI-Skalierung durch Systeminfo
        Local $fDetectedScale = _DetectMonitorDPIScale($i)
        If $fDetectedScale > 0 Then
            $g_aMonitorScaling[$i] = $fDetectedScale
            _LogDebug("Monitor " & $i & " DPI-Skalierung erkannt: " & Int($g_aMonitorScaling[$i] * 100) & "%")
            ContinueLoop
        EndIf
        
        ; Fallback: Erkenne typische DPI-Skalierungen durch physische Auflösung
        If UBound($g_aMonitorDetails) > $i Then
            Local $sDeviceName = $g_aMonitorDetails[$i][0]
            Local $aPhysical = _GetPhysicalResolution($sDeviceName)
            
            If $aPhysical[0] > 0 And $aPhysical[1] > 0 Then
                ; Berechne Skalierung aus Verhältnis physisch zu effektiv
                Local $fScaleX = $aPhysical[0] / $g_aMonitors[$i][0]
                Local $fScaleY = $aPhysical[1] / $g_aMonitors[$i][1]
                
                ; Runde auf typische Windows-Skalierungen
                Local $fAvgScale = ($fScaleX + $fScaleY) / 2
                If $fAvgScale >= 0.95 And $fAvgScale <= 1.05 Then
                    $g_aMonitorScaling[$i] = 1.0   ; 100%
                ElseIf $fAvgScale >= 1.20 And $fAvgScale <= 1.30 Then
                    $g_aMonitorScaling[$i] = 1.25  ; 125%
                ElseIf $fAvgScale >= 1.45 And $fAvgScale <= 1.55 Then
                    $g_aMonitorScaling[$i] = 1.5   ; 150%
                ElseIf $fAvgScale >= 1.70 And $fAvgScale <= 1.80 Then
                    $g_aMonitorScaling[$i] = 1.75  ; 175%
                ElseIf $fAvgScale >= 1.95 And $fAvgScale <= 2.05 Then
                    $g_aMonitorScaling[$i] = 2.0   ; 200%
                Else
                    ; Exakte Skalierung für ungewöhnliche Werte
                    $g_aMonitorScaling[$i] = $fAvgScale
                EndIf
                
                _LogDebug("Monitor " & $i & " DPI-Skalierung (physisch): " & Int($g_aMonitorScaling[$i] * 100) & "% (Berechnet: " & Round($fAvgScale, 2) & ")")
            EndIf
        EndIf
        
        ; Heuristik für typische Monitor-Auflösungen
        If $g_aMonitorScaling[$i] = 1.0 Then
            $g_aMonitorScaling[$i] = _HeuristicScaleDetection($i)
            If $g_aMonitorScaling[$i] > 1.0 Then
                _LogDebug("Monitor " & $i & " DPI-Skalierung (Heuristik): " & Int($g_aMonitorScaling[$i] * 100) & "%")
            EndIf
        EndIf
    Next
EndFunc

; Erkennt DPI-Skalierung über Windows-APIs
Func _DetectMonitorDPIScale($iMonitor)
    ; Verwende Windows API zur DPI-Erkennung
    Local $hMonitor = _GetMonitorHandle($iMonitor)
    If $hMonitor = 0 Then Return 0
    
    ; GetDpiForMonitor API (Windows 8.1+)
    Local $aDPI = DllCall("Shcore.dll", "int", "GetDpiForMonitor", "handle", $hMonitor, "int", 0, "uint*", 0, "uint*", 0)
    If Not @error And $aDPI[0] = 0 Then
        Local $iDPI = $aDPI[2] ; X-DPI
        Local $fScale = $iDPI / 96.0 ; 96 DPI = 100%
        
        ; Runde auf Windows-typische Werte
        If $fScale >= 0.95 And $fScale <= 1.05 Then Return 1.0
        If $fScale >= 1.20 And $fScale <= 1.30 Then Return 1.25
        If $fScale >= 1.45 And $fScale <= 1.55 Then Return 1.5
        If $fScale >= 1.70 And $fScale <= 1.80 Then Return 1.75
        If $fScale >= 1.95 And $fScale <= 2.05 Then Return 2.0
        
        Return $fScale
    EndIf
    
    Return 0
EndFunc

; Heuristische Skalierungserkennung basierend auf Monitor-Auflösung
Func _HeuristicScaleDetection($iMonitor)
    Local $iWidth = $g_aMonitors[$iMonitor][0]
    Local $iHeight = $g_aMonitors[$iMonitor][1]
    
    ; Typische 4K-Auflösungen bei Skalierung
    If ($iWidth = 2560 And $iHeight = 1440) Then
        ; Könnte 4K bei 150% Skalierung sein (3840x2160 -> 2560x1440)
        Return 1.5
    ElseIf ($iWidth = 1920 And $iHeight = 1080) Then
        ; Könnte 4K bei 200% Skalierung sein (3840x2160 -> 1920x1080)
        ; Oder native Full HD bei 100%
        ; Schwer zu unterscheiden - Default belassen
        Return 1.0
    ElseIf ($iWidth = 3072 And $iHeight = 1728) Then
        ; 4K bei 125% Skalierung (3840x2160 -> 3072x1728)
        Return 1.25
    ElseIf ($iWidth = 2160 And $iHeight = 1215) Then
        ; 4K bei 175% Skalierung (3840x2160 -> ~2194x1234)
        Return 1.75
    EndIf
    
    ; Standard-Wert
    Return 1.0
EndFunc

; Hilfsfunktion um Monitor-Handle zu erhalten
Func _GetMonitorHandle($iMonitor)
    ; Diese Funktion müsste den Windows-Monitor-Handle für den gegebenen Monitor-Index zurückgeben
    ; Vereinfachte Implementation - in einer vollständigen Version würde man EnumDisplayMonitors verwenden
    Return 0 ; Fallback wenn nicht implementiert
EndFunc

; Zeichnet die Windows 11 Style Visualisierung
Func _DrawVisualization()
    If Not IsHWnd($g_hVisualizerGUI) Then Return

    ; Clear background mit Windows 11 Farbe
    _GDIPlus_GraphicsClear($g_hBackBuffer, $COLOR_WIN11_BG)

    ; Zeichne Titel
    _DrawTitle()

    ; Zeichne Monitore
    _DrawMonitors()

    ; Zeichne GUI-Position
    _DrawGUIWindow()

    ; Zeichne Info-Button (wieder aktiviert)
    _DrawInfoButton()

    ; Buffer auf Bildschirm kopieren
    _GDIPlus_GraphicsDrawImage($g_hGraphics, $g_hBitmap, 0, 0)
EndFunc

; Zeichnet den Titel im Windows 11 Style
Func _DrawTitle()
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF000000) ; Schwarz
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 14, 0)
    Local $hFormat = _GDIPlus_StringFormatCreate()
    
    Local $tLayout = _GDIPlus_RectFCreate(40, 20, $g_iVisWidth - 80, 30)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, "Anzeigeeinstellungen", $hFont, $tLayout, $hFormat, $hBrush)
    
    ; Untertitel
    Local $hFontSmall = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 11, 0)
    Local $hBrushGray = _GDIPlus_BrushCreateSolid(0xFF666666)
    $tLayout = _GDIPlus_RectFCreate(40, 45, $g_iVisWidth - 80, 20)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, "Monitor-Layout", $hFontSmall, $tLayout, $hFormat, $hBrushGray)
    
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_BrushDispose($hBrushGray)
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_FontDispose($hFontSmall)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Zeichnet alle Monitore im Windows 11 Style - exakte Kopie der Windows-Anzeigeeinstellungen
Func _DrawMonitors()
    If Not IsArray($g_aMonitors) Or $g_aMonitors[0][0] = 0 Then Return

    ; Berechne PHYSISCHE Monitore für exakte Windows-Darstellung
    Local $aPhysicalMonitors[$g_aMonitors[0][0] + 1][6] ; [width, height, x, y, scaling, effective_index]
    $aPhysicalMonitors[0][0] = $g_aMonitors[0][0]
    
    ; Konvertiere zu physischen Dimensionen
    For $i = 1 To $g_aMonitors[0][0]
        ; Physische Auflösung berechnen
        Local $fScale = $g_aMonitorScaling[$i]
        $aPhysicalMonitors[$i][0] = Int($g_aMonitors[$i][0] * $fScale) ; Physische Breite
        $aPhysicalMonitors[$i][1] = Int($g_aMonitors[$i][1] * $fScale) ; Physische Höhe
        $aPhysicalMonitors[$i][2] = $g_aMonitors[$i][2] ; Effektive X-Position (wird neu berechnet)
        $aPhysicalMonitors[$i][3] = $g_aMonitors[$i][3] ; Effektive Y-Position (wird neu berechnet)
        $aPhysicalMonitors[$i][4] = $fScale ; Skalierungsfaktor
        $aPhysicalMonitors[$i][5] = $i ; Original-Index
        
        _LogDebug("Monitor " & $i & " physisch: " & $aPhysicalMonitors[$i][0] & "x" & $aPhysicalMonitors[$i][1] & " (Skalierung: " & Int($fScale * 100) & "%)")
    Next
    
    ; Neupositionierung für Windows-exakte Darstellung (sequenziell ohne Lücken)
    _RepositionMonitorsSequentially($aPhysicalMonitors)
    
    ; Berechne Gesamtgröße der physischen Monitore
    Local $iMinX = 999999, $iMinY = 999999
    Local $iMaxX = -999999, $iMaxY = -999999

    For $i = 1 To $aPhysicalMonitors[0][0]
        If $aPhysicalMonitors[$i][2] < $iMinX Then $iMinX = $aPhysicalMonitors[$i][2]
        If $aPhysicalMonitors[$i][3] < $iMinY Then $iMinY = $aPhysicalMonitors[$i][3]
        If $aPhysicalMonitors[$i][2] + $aPhysicalMonitors[$i][0] > $iMaxX Then $iMaxX = $aPhysicalMonitors[$i][2] + $aPhysicalMonitors[$i][0]
        If $aPhysicalMonitors[$i][3] + $aPhysicalMonitors[$i][1] > $iMaxY Then $iMaxY = $aPhysicalMonitors[$i][3] + $aPhysicalMonitors[$i][1]
    Next

    Local $iTotalWidth = $iMaxX - $iMinX
    Local $iTotalHeight = $iMaxY - $iMinY

    ; Skalierung für Visualizer berechnen
    Local $iAvailableWidth = $g_iVisWidth - 80
    Local $iAvailableHeight = $g_iVisHeight - 120
    Local $fScaleX = ($iTotalWidth > 0) ? ($iAvailableWidth / $iTotalWidth) : 1.0
    Local $fScaleY = ($iTotalHeight > 0) ? ($iAvailableHeight / $iTotalHeight) : 1.0
    $g_fScale = ($fScaleX < $fScaleY) ? $fScaleX : $fScaleY
    
    ; Begrenze Skalierung
    If $g_fScale < 0.05 Then $g_fScale = 0.05
    If $g_fScale > 2.0 Then $g_fScale = 2.0

    ; Zentriere das Layout
    Local $iScaledWidth = $iTotalWidth * $g_fScale
    Local $iScaledHeight = $iTotalHeight * $g_fScale
    Local $iOffsetX = ($g_iVisWidth - $iScaledWidth) / 2
    Local $iOffsetY = 80 + (($g_iVisHeight - 160) - $iScaledHeight) / 2

    ; Zeichne jeden Monitor basierend auf physischen Dimensionen
    For $i = 1 To $aPhysicalMonitors[0][0]
        Local $iOriginalIndex = $aPhysicalMonitors[$i][5]
        Local $iX = $iOffsetX + (($aPhysicalMonitors[$i][2] - $iMinX) * $g_fScale)
        Local $iY = $iOffsetY + (($aPhysicalMonitors[$i][3] - $iMinY) * $g_fScale)
        Local $iW = $aPhysicalMonitors[$i][0] * $g_fScale
        Local $iH = $aPhysicalMonitors[$i][1] * $g_fScale

        ; Zeichne Monitor-Schatten
        Local $hBrushShadow = _GDIPlus_BrushCreateSolid($COLOR_WIN11_SHADOW)
        _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX + 2, $iY + 2, $iW, $iH, $hBrushShadow)
        _GDIPlus_BrushDispose($hBrushShadow)

        ; Monitor-Farbe basierend auf Status
        Local $iMonitorColor = $COLOR_WIN11_MONITOR
        If $iOriginalIndex = $g_iCurrentScreenNumber Then
            $iMonitorColor = $COLOR_WIN11_SELECTED
        ElseIf $iOriginalIndex = $g_iHoveredMonitor Then
            $iMonitorColor = 0xFF1A86D8
        EndIf

        ; Zeichne Monitor-Rechteck mit abgerundeten Ecken
        _DrawRoundedRectangle($iX, $iY, $iW, $iH, 6, $iMonitorColor, $COLOR_WIN11_BORDER)

        ; Zeichne große Monitor-Nummer
        _DrawMonitorNumber($iOriginalIndex, $iX, $iY, $iW, $iH)

        ; Zeichne Auflösung mit physischen und effektiven Werten
        Local $aPhysicalData[6]
        $aPhysicalData[0] = $aPhysicalMonitors[$i][0]  ; Physische Breite
        $aPhysicalData[1] = $aPhysicalMonitors[$i][1]  ; Physische Höhe
        $aPhysicalData[2] = $aPhysicalMonitors[$i][2]  ; X-Position
        $aPhysicalData[3] = $aPhysicalMonitors[$i][3]  ; Y-Position
        $aPhysicalData[4] = $aPhysicalMonitors[$i][4]  ; Skalierungsfaktor
        $aPhysicalData[5] = $aPhysicalMonitors[$i][5]  ; Original-Index
        _DrawMonitorResolutionDetailed($iOriginalIndex, $iX, $iY, $iW, $iH, $aPhysicalData)
    Next
EndFunc

; Repositioniert Monitore für Windows-exakte Darstellung
Func _RepositionMonitorsSequentially(ByRef $aPhysicalMonitors)
    If $aPhysicalMonitors[0][0] <= 1 Then Return
    
    ; Verwende ORIGINALE Windows-Positionen aber skaliere auf physische Größen
    ; Zuerst: Behalte relative Y-Positionen aus den originalen Windows-Positionen
    For $i = 1 To $aPhysicalMonitors[0][0]
        Local $iOriginalIndex = $aPhysicalMonitors[$i][5]
        
        ; Konvertiere effektive Position zu physischer Position basierend auf Skalierung
        Local $fScale = $aPhysicalMonitors[$i][4]
        
        ; Y-Position: Verwende die originale Windows-Y-Position (bereits in effektiven Koordinaten)
        ; Diese bleibt unverändert, da sie die korrekte relative Position darstellt
        $aPhysicalMonitors[$i][3] = $g_aMonitors[$iOriginalIndex][3]
        
        _LogDebug("Monitor " & $iOriginalIndex & " - Original Y: " & $g_aMonitors[$iOriginalIndex][3] & ", Physische Größe: " & $aPhysicalMonitors[$i][0] & "x" & $aPhysicalMonitors[$i][1])
    Next
    
    ; Sortiere Monitore nach X-Position für korrekte horizontale Anordnung
    For $i = 1 To $aPhysicalMonitors[0][0] - 1
        For $j = $i + 1 To $aPhysicalMonitors[0][0]
            Local $iOriginalIndexI = $aPhysicalMonitors[$i][5]
            Local $iOriginalIndexJ = $aPhysicalMonitors[$j][5]
            If $g_aMonitors[$iOriginalIndexI][2] > $g_aMonitors[$iOriginalIndexJ][2] Then
                ; Tausche Monitore
                For $k = 0 To 5
                    Local $temp = $aPhysicalMonitors[$i][$k]
                    $aPhysicalMonitors[$i][$k] = $aPhysicalMonitors[$j][$k]
                    $aPhysicalMonitors[$j][$k] = $temp
                Next
            EndIf
        Next
    Next
    
    ; Repositioniere X-Koordinaten sequenziell ohne Lücken
    Local $iCurrentX = 0
    
    For $i = 1 To $aPhysicalMonitors[0][0]
        Local $iOriginalIndex = $aPhysicalMonitors[$i][5]
        $aPhysicalMonitors[$i][2] = $iCurrentX
        $iCurrentX += $aPhysicalMonitors[$i][0] ; Nächster Monitor direkt anschließend
        
        _LogDebug("Monitor " & $iOriginalIndex & " repositioniert: X=" & $aPhysicalMonitors[$i][2] & ", Y=" & $aPhysicalMonitors[$i][3] & " (Original: " & $g_aMonitors[$iOriginalIndex][2] & "," & $g_aMonitors[$iOriginalIndex][3] & ")")
    Next
EndFunc

; Zeichnet ein Rechteck mit abgerundeten Ecken
Func _DrawRoundedRectangle($iX, $iY, $iW, $iH, $iRadius, $iFillColor, $iBorderColor)
    ; Erstelle Pfad für abgerundete Ecken
    Local $hPath = _GDIPlus_PathCreate()
    
    ; Oben links
    _GDIPlus_PathAddArc($hPath, $iX, $iY, $iRadius * 2, $iRadius * 2, 180, 90)
    ; Oben rechts
    _GDIPlus_PathAddArc($hPath, $iX + $iW - $iRadius * 2, $iY, $iRadius * 2, $iRadius * 2, 270, 90)
    ; Unten rechts
    _GDIPlus_PathAddArc($hPath, $iX + $iW - $iRadius * 2, $iY + $iH - $iRadius * 2, $iRadius * 2, $iRadius * 2, 0, 90)
    ; Unten links
    _GDIPlus_PathAddArc($hPath, $iX, $iY + $iH - $iRadius * 2, $iRadius * 2, $iRadius * 2, 90, 90)
    
    _GDIPlus_PathCloseFigure($hPath)

    ; Fülle den Pfad
    Local $hBrush = _GDIPlus_BrushCreateSolid($iFillColor)
    _GDIPlus_GraphicsFillPath($g_hBackBuffer, $hPath, $hBrush)
    _GDIPlus_BrushDispose($hBrush)

    ; Zeichne Rand
    Local $hPen = _GDIPlus_PenCreate($iBorderColor, 1)
    _GDIPlus_GraphicsDrawPath($g_hBackBuffer, $hPath, $hPen)
    _GDIPlus_PenDispose($hPen)

    _GDIPlus_PathDispose($hPath)
EndFunc

; Zeichnet die große Monitor-Nummer mit verbesserter Lesbarkeit
Func _DrawMonitorNumber($iMonitor, $iX, $iY, $iW, $iH)
    ; Berechne Schriftgröße basierend auf Monitor-Größe - besser lesbar
    Local $iFontSize = Int(_Min($iW, $iH) * 0.3)  ; Etwas kleiner für bessere Proportionen
    If $iFontSize < 28 Then $iFontSize = 28      ; Mindestgröße erhöht
    If $iFontSize > 60 Then $iFontSize = 60      ; Maximalgröße reduziert

    ; Erstelle Font mit besserer Lesbarkeit
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), $iFontSize, 1)  ; Bold für bessere Lesbarkeit
    
    ; Text-Schatten für bessere Lesbarkeit
    Local $hBrushShadow = _GDIPlus_BrushCreateSolid(0x80000000)  ; Halbtransparenter Schatten
    Local $hBrushText = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)    ; Weißer Text
    
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1)      ; Center horizontal
    _GDIPlus_StringFormatSetLineAlign($hFormat, 1)  ; Center vertical

    ; Zeichne Schatten (leicht versetzt)
    Local $tLayoutShadow = _GDIPlus_RectFCreate($iX + 2, $iY + 2, $iW, $iH)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, String($iMonitor), $hFont, $tLayoutShadow, $hFormat, $hBrushShadow)
    
    ; Zeichne Haupttext
    Local $tLayout = _GDIPlus_RectFCreate($iX, $iY, $iW, $iH)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, String($iMonitor), $hFont, $tLayout, $hFormat, $hBrushText)

    ; Cleanup
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_BrushDispose($hBrushShadow)
    _GDIPlus_BrushDispose($hBrushText)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Zeichnet die Monitor-Auflösung (Original-Version für Rückwärtskompatibilität)
Func _DrawMonitorResolution($iMonitor, $iX, $iY, $iW, $iH)
    Local $hFontSmall = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 10, 0)
    Local $hFontTiny = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 8, 0)
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xDDFFFFFF) ; Etwas transparenter
    Local $hBrushDim = _GDIPlus_BrushCreateSolid(0xAAFFFFFF) ; Noch transparenter
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1) ; Center

    ; Effektive Auflösung (das was Windows sieht)
    Local $sEffective = $g_aMonitors[$iMonitor][0] & " × " & $g_aMonitors[$iMonitor][1]
    
    ; Native/Physische Auflösung und Skalierung
    Local $sScaling = ""
    Local $sNative = ""
    If $g_aMonitorScaling[$iMonitor] > 1.0 Then
        ; Berechne native Auflösung
        Local $iNativeWidth = Int($g_aMonitors[$iMonitor][0] * $g_aMonitorScaling[$iMonitor])
        Local $iNativeHeight = Int($g_aMonitors[$iMonitor][1] * $g_aMonitorScaling[$iMonitor])
        
        $sScaling = Int($g_aMonitorScaling[$iMonitor] * 100) & "% Skalierung"
        $sNative = "Nativ: " & $iNativeWidth & " × " & $iNativeHeight
    Else
        $sScaling = "100% (keine Skalierung)"
    EndIf

    ; Zeichne die Informationen untereinander
    Local $iLineHeight = 15
    Local $iStartY = $iY + $iH - 50
    
    ; Zeile 1: Effektive Auflösung (größer)
    Local $tLayout = _GDIPlus_RectFCreate($iX, $iStartY, $iW, $iLineHeight)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sEffective, $hFontSmall, $tLayout, $hFormat, $hBrush)
    
    ; Zeile 2: Skalierung
    $tLayout = _GDIPlus_RectFCreate($iX, $iStartY + $iLineHeight, $iW, $iLineHeight)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sScaling, $hFontTiny, $tLayout, $hFormat, $hBrushDim)
    
    ; Zeile 3: Native Auflösung (wenn skaliert)
    If $sNative <> "" Then
        $tLayout = _GDIPlus_RectFCreate($iX, $iStartY + $iLineHeight * 2, $iW, $iLineHeight)
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sNative, $hFontTiny, $tLayout, $hFormat, $hBrushDim)
    EndIf

    _GDIPlus_FontDispose($hFontSmall)
    _GDIPlus_FontDispose($hFontTiny)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_BrushDispose($hBrushDim)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Zeichnet detaillierte Monitor-Auflösung mit physischen Daten - verbesserte Lesbarkeit
Func _DrawMonitorResolutionDetailed($iMonitor, $iX, $iY, $iW, $iH, $aPhysicalData)
    ; Kleinere Schriftgrößen um Abschneidung zu vermeiden
    Local $hFontMedium = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 9, 1)  ; Bold für Haupttext
    Local $hFontSmall = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 8, 0)   ; Normal für Details
    
    ; Bessere Farben mit Schatten für bessere Lesbarkeit
    Local $hBrushShadow = _GDIPlus_BrushCreateSolid(0x80000000)    ; Schatten
    Local $hBrushMain = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)      ; Haupttext weiß
    Local $hBrushDetail = _GDIPlus_BrushCreateSolid(0xFFE0E0E0)    ; Detailtext heller
    
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1) ; Center

    ; Extrahiere Daten aus physicalData: [width, height, x, y, scaling, effective_index]
    Local $iPhysicalWidth = $aPhysicalData[0]
    Local $iPhysicalHeight = $aPhysicalData[1]
    Local $fScaling = $aPhysicalData[4]
    
    ; Effektive Auflösung (das was Windows sieht)
    Local $sEffective = $g_aMonitors[$iMonitor][0] & " × " & $g_aMonitors[$iMonitor][1]
    
    ; Skalierungsinfo
    Local $sScaling = Int($fScaling * 100) & "% Skalierung"
    
    ; Native/Physische Auflösung
    Local $sNative = ""
    If $fScaling > 1.0 Then
        $sNative = "Nativ: " & $iPhysicalWidth & " × " & $iPhysicalHeight
    Else
        $sScaling = "100% (keine Skalierung)"
    EndIf

    ; Zeichne die Informationen untereinander mit Schatten für bessere Lesbarkeit
    Local $iLineHeight = 12  ; Kompaktere Zeilenhöhe
    Local $iStartY = $iY + $iH - 40  ; Weniger Platz unten
    
    ; Zeile 1: Effektive Auflösung (prominenter) mit Schatten
    Local $tLayoutShadow = _GDIPlus_RectFCreate($iX + 1, $iStartY + 1, $iW, $iLineHeight)
    Local $tLayout = _GDIPlus_RectFCreate($iX, $iStartY, $iW, $iLineHeight)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sEffective, $hFontMedium, $tLayoutShadow, $hFormat, $hBrushShadow)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sEffective, $hFontMedium, $tLayout, $hFormat, $hBrushMain)
    
    ; Zeile 2: Skalierung mit Schatten
    $tLayoutShadow = _GDIPlus_RectFCreate($iX + 1, $iStartY + $iLineHeight + 1, $iW, $iLineHeight)
    $tLayout = _GDIPlus_RectFCreate($iX, $iStartY + $iLineHeight, $iW, $iLineHeight)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sScaling, $hFontSmall, $tLayoutShadow, $hFormat, $hBrushShadow)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sScaling, $hFontSmall, $tLayout, $hFormat, $hBrushDetail)
    
    ; Zeile 3: Native Auflösung (wenn skaliert) mit Schatten
    If $sNative <> "" Then
        $tLayoutShadow = _GDIPlus_RectFCreate($iX + 1, $iStartY + $iLineHeight * 2 + 1, $iW, $iLineHeight)
        $tLayout = _GDIPlus_RectFCreate($iX, $iStartY + $iLineHeight * 2, $iW, $iLineHeight)
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sNative, $hFontSmall, $tLayoutShadow, $hFormat, $hBrushShadow)
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sNative, $hFontSmall, $tLayout, $hFormat, $hBrushDetail)
    EndIf

    ; Cleanup
    _GDIPlus_FontDispose($hFontMedium)
    _GDIPlus_FontDispose($hFontSmall)
    _GDIPlus_BrushDispose($hBrushShadow)
    _GDIPlus_BrushDispose($hBrushMain)
    _GDIPlus_BrushDispose($hBrushDetail)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Zeichnet das GUI-Fenster
Func _DrawGUIWindow()
    If Not IsHWnd($g_hMainGUI) Then Return

    Local $aPos = WinGetPos($g_hMainGUI)
    If Not IsArray($aPos) Then Return

    ; Verwende gleiche Berechnung wie für Monitore
    Local $iMinX = 999999, $iMinY = 999999
    Local $iMaxX = -999999, $iMaxY = -999999

    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iMinX Then $iMinX = $g_aMonitors[$i][2]
        If $g_aMonitors[$i][3] < $iMinY Then $iMinY = $g_aMonitors[$i][3]
        If $g_aMonitors[$i][2] + $g_aMonitors[$i][0] > $iMaxX Then $iMaxX = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $g_aMonitors[$i][3] + $g_aMonitors[$i][1] > $iMaxY Then $iMaxY = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
    Next

    Local $iTotalWidth = $iMaxX - $iMinX
    Local $iTotalHeight = $iMaxY - $iMinY
    Local $iScaledWidth = $iTotalWidth * $g_fScale
    Local $iScaledHeight = $iTotalHeight * $g_fScale
    Local $iOffsetX = ($g_iVisWidth - $iScaledWidth) / 2
    Local $iOffsetY = 80 + (($g_iVisHeight - 160) - $iScaledHeight) / 2

    ; Skalierte GUI-Position
    Local $iX = $iOffsetX + (($aPos[0] - $iMinX) * $g_fScale)
    Local $iY = $iOffsetY + (($aPos[1] - $iMinY) * $g_fScale)
    Local $iW = $aPos[2] * $g_fScale
    Local $iH = $aPos[3] * $g_fScale

    ; Bestimme Farbe basierend auf Status
    Local $iColor = 0x8000FF00  ; Standard: Semi-transparent grün
    Local $iBorderColor = 0xFF00AA00  ; Dunkelgrün
    
    ; Wenn GUI ausgefahren ist, zeichne sie AUSSERHALB des Monitors
    If $g_bWindowIsOut Then
        $iColor = 0x80FFA500  ; Semi-transparent orange (ausgefahren)
        $iBorderColor = 0xFFFF6600  ; Orange Rand
        
        ; Berechne die Position der GUI außerhalb des Monitors
        ; mit nur 8 Pixel sichtbar (skaliert)
        Local $iVisiblePixels = 8 * $g_fScale
        
        ; Finde den aktuellen Monitor in der skalierten Darstellung
        Local $iMonX = $iOffsetX + (($g_aMonitors[$g_iCurrentScreenNumber][2] - $iMinX) * $g_fScale)
        Local $iMonY = $iOffsetY + (($g_aMonitors[$g_iCurrentScreenNumber][3] - $iMinY) * $g_fScale)
        Local $iMonW = $g_aMonitors[$g_iCurrentScreenNumber][0] * $g_fScale
        Local $iMonH = $g_aMonitors[$g_iCurrentScreenNumber][1] * $g_fScale
        
        ; Korrigiere die GUI-Position basierend auf Slide-Richtung
        Switch $g_sWindowIsAt
            Case $POS_LEFT, "Left"
                ; GUI ist links vom Monitor - nur 8 Pixel sichtbar am rechten Rand
                $iX = $iMonX - $iW + $iVisiblePixels
                
            Case $POS_RIGHT, "Right"
                ; GUI ist rechts vom Monitor - nur 8 Pixel sichtbar am linken Rand
                $iX = $iMonX + $iMonW - $iVisiblePixels
                
            Case $POS_TOP, "Top"
                ; GUI ist oberhalb vom Monitor - nur 8 Pixel sichtbar am unteren Rand
                $iY = $iMonY - $iH + $iVisiblePixels
                
            Case $POS_BOTTOM, "Bottom"
                ; GUI ist unterhalb vom Monitor - nur 8 Pixel sichtbar am oberen Rand
                $iY = $iMonY + $iMonH - $iVisiblePixels
        EndSwitch
        
        ; Optional: Zeichne den sichtbaren Teil auf dem Monitor hervorgehoben
        Local $hPenVisible = _GDIPlus_PenCreate(0xFFFFFF00, 2)  ; Gelber Rand für sichtbaren Teil
        Local $hBrushVisible = _GDIPlus_BrushCreateSolid(0x40FFFF00)  ; Semi-transparent gelb
        
        Switch $g_sWindowIsAt
            Case $POS_LEFT, "Left"
                ; Sichtbarer Teil ist am linken Rand des Monitors
                _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iMonX, $iY, $iVisiblePixels, $iH, $hBrushVisible)
                _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iMonX, $iY, $iVisiblePixels, $iH, $hPenVisible)
                
            Case $POS_RIGHT, "Right"
                ; Sichtbarer Teil ist am rechten Rand des Monitors
                _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iMonX + $iMonW - $iVisiblePixels, $iY, $iVisiblePixels, $iH, $hBrushVisible)
                _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iMonX + $iMonW - $iVisiblePixels, $iY, $iVisiblePixels, $iH, $hPenVisible)
                
            Case $POS_TOP, "Top"
                ; Sichtbarer Teil ist am oberen Rand des Monitors
                _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX, $iMonY, $iW, $iVisiblePixels, $hBrushVisible)
                _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iX, $iMonY, $iW, $iVisiblePixels, $hPenVisible)
                
            Case $POS_BOTTOM, "Bottom"
                ; Sichtbarer Teil ist am unteren Rand des Monitors
                _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX, $iMonY + $iMonH - $iVisiblePixels, $iW, $iVisiblePixels, $hBrushVisible)
                _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iX, $iMonY + $iMonH - $iVisiblePixels, $iW, $iVisiblePixels, $hPenVisible)
        EndSwitch
        
        _GDIPlus_PenDispose($hPenVisible)
        _GDIPlus_BrushDispose($hBrushVisible)
    EndIf

    ; Zeichne GUI als Rechteck
    Local $hBrush = _GDIPlus_BrushCreateSolid($iColor)
    _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hBrush)
    
    Local $hPen = _GDIPlus_PenCreate($iBorderColor, 2)
    _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hPen)
    
    ; Zeichne Status-Text in der GUI
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 8, 1)
    Local $hBrushText = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1)
    _GDIPlus_StringFormatSetLineAlign($hFormat, 1)
    
    Local $sStatusText = "GUI"
    If $g_bWindowIsOut Then
        $sStatusText = "OUT: " & $g_sWindowIsAt
    EndIf
    
    Local $tLayout = _GDIPlus_RectFCreate($iX, $iY, $iW, $iH)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sStatusText, $hFont, $tLayout, $hFormat, $hBrushText)
    
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_BrushDispose($hBrushText)
    _GDIPlus_StringFormatDispose($hFormat)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PenDispose($hPen)
EndFunc

; Zeichnet den Info-Button
Func _DrawInfoButton()
    Local $iButtonX = $g_iVisWidth - 140
    Local $iButtonY = $g_iVisHeight - 45
    Local $iButtonW = 100
    Local $iButtonH = 30

    ; Button-Hintergrund
    _DrawRoundedRectangle($iButtonX, $iButtonY, $iButtonW, $iButtonH, 4, 0xFFE5E5E5, 0xFFCCCCCC)

    ; Button-Text
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 10, 0)
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1)
    _GDIPlus_StringFormatSetLineAlign($hFormat, 1)

    Local $tLayout = _GDIPlus_RectFCreate($iButtonX, $iButtonY, $iButtonW, $iButtonH)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, "ℹ Info", $hFont, $tLayout, $hFormat, $hBrush)

    _GDIPlus_FontDispose($hFont)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Click-Handler für Visualizer
Func _OnVisualizerClick($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd <> $g_hVisualizerGUI Then Return $GUI_RUNDEFMSG

    Local $iX = BitAND($lParam, 0xFFFF)
    Local $iY = BitShift($lParam, 16)

    ; Prüfe ob Info-Button geklickt wurde
    If $iX >= $g_iVisWidth - 140 And $iX <= $g_iVisWidth - 40 And _
       $iY >= $g_iVisHeight - 45 And $iY <= $g_iVisHeight - 15 Then
        _ShowVisualizerInfo()
        Return 0
    EndIf

    ; Prüfe welcher Monitor geklickt wurde
    Local $iClickedMonitor = _GetMonitorAtVisualizerPoint($iX, $iY)
    If $iClickedMonitor > 0 Then
        $g_iCurrentScreenNumber = $iClickedMonitor
        _UpdateVisualization()
    EndIf

    Return 0
EndFunc

; MouseMove-Handler für Hover-Effekte
Func _OnVisualizerMouseMove($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd <> $g_hVisualizerGUI Then Return $GUI_RUNDEFMSG

    Local $iX = BitAND($lParam, 0xFFFF)
    Local $iY = BitShift($lParam, 16)

    ; Welcher Monitor wird gehovert?
    Local $iHoverMonitor = _GetMonitorAtVisualizerPoint($iX, $iY)
    
    If $iHoverMonitor <> $g_iLastHoveredMonitor Then
        $g_iHoveredMonitor = $iHoverMonitor
        $g_iLastHoveredMonitor = $iHoverMonitor
        
        ; Tooltips entfernt - störend und überflüssig
        ; Alle Informationen sind bereits auf den Monitoren sichtbar
        
        _UpdateVisualization()
    EndIf

    Return 0
EndFunc

; MouseLeave-Handler
Func _OnVisualizerMouseLeave($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd <> $g_hVisualizerGUI Then Return $GUI_RUNDEFMSG
    
    $g_iHoveredMonitor = 0
    $g_iLastHoveredMonitor = 0
    ToolTip("")
    _UpdateVisualization()
    
    Return $GUI_RUNDEFMSG
EndFunc

; Ermittelt welcher Monitor an einem Visualizer-Punkt ist
Func _GetMonitorAtVisualizerPoint($iClickX, $iClickY)
    If Not IsArray($g_aMonitors) Or $g_aMonitors[0][0] = 0 Then Return 0

    ; Berechne Layout-Parameter (gleich wie beim Zeichnen)
    Local $iMinX = 999999, $iMinY = 999999
    Local $iMaxX = -999999, $iMaxY = -999999

    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iMinX Then $iMinX = $g_aMonitors[$i][2]
        If $g_aMonitors[$i][3] < $iMinY Then $iMinY = $g_aMonitors[$i][3]
        If $g_aMonitors[$i][2] + $g_aMonitors[$i][0] > $iMaxX Then $iMaxX = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $g_aMonitors[$i][3] + $g_aMonitors[$i][1] > $iMaxY Then $iMaxY = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
    Next

    Local $iTotalWidth = $iMaxX - $iMinX
    Local $iTotalHeight = $iMaxY - $iMinY
    Local $iScaledWidth = $iTotalWidth * $g_fScale
    Local $iScaledHeight = $iTotalHeight * $g_fScale
    Local $iOffsetX = ($g_iVisWidth - $iScaledWidth) / 2
    Local $iOffsetY = 80 + (($g_iVisHeight - 160) - $iScaledHeight) / 2

    ; Prüfe jeden Monitor
    For $i = 1 To $g_aMonitors[0][0]
        Local $iX = $iOffsetX + (($g_aMonitors[$i][2] - $iMinX) * $g_fScale)
        Local $iY = $iOffsetY + (($g_aMonitors[$i][3] - $iMinY) * $g_fScale)
        Local $iW = $g_aMonitors[$i][0] * $g_fScale
        Local $iH = $g_aMonitors[$i][1] * $g_fScale

        If $iClickX >= $iX And $iClickX <= $iX + $iW And _
           $iClickY >= $iY And $iClickY <= $iY + $iH Then
            Return $i
        EndIf
    Next

    Return 0
EndFunc

; Zeigt große Nummern auf den echten Monitoren
Func _IdentifyMonitors()
    _LogInfo("Zeige Monitor-Identifikation...")
    
    Local $aIdentifyGUIs[$g_iMonitorCount + 1]
    
    For $i = 1 To $g_iMonitorCount
        ; Erstelle transparentes Fenster für jeden Monitor
        Local $hIdentifyGUI = GUICreate("", 250, 250, _
                                       $g_aMonitors[$i][2] + ($g_aMonitors[$i][0] - 250) / 2, _
                                       $g_aMonitors[$i][3] + ($g_aMonitors[$i][1] - 250) / 2, _
                                       $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TRANSPARENT, $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
        
        ; Setze Transparenz
        _WinAPI_SetLayeredWindowAttributes($hIdentifyGUI, 0x000000, 0, $LWA_COLORKEY)
        GUISetBkColor(0x000000, $hIdentifyGUI)
        
        ; Erstelle Graphics-Objekt
        Local $hGraphic = _GDIPlus_GraphicsCreateFromHWND($hIdentifyGUI)
        _GDIPlus_GraphicsSetSmoothingMode($hGraphic, 4)
        
        ; Zeichne weißen Kreis mit Schatten
        Local $hBrushShadow = _GDIPlus_BrushCreateSolid(0x80000000)
        _GDIPlus_GraphicsFillEllipse($hGraphic, 27, 27, 200, 200, $hBrushShadow)
        
        Local $hBrushBg = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
        _GDIPlus_GraphicsFillEllipse($hGraphic, 25, 25, 200, 200, $hBrushBg)
        
        ; Zeichne Monitor-Nummer
        Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 100, 0)
        Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
        Local $hFormat = _GDIPlus_StringFormatCreate()
        _GDIPlus_StringFormatSetAlign($hFormat, 1)
        _GDIPlus_StringFormatSetLineAlign($hFormat, 1)
        
        Local $tLayout = _GDIPlus_RectFCreate(25, 25, 200, 200)
        _GDIPlus_GraphicsDrawStringEx($hGraphic, String($i), $hFont, $tLayout, $hFormat, $hBrush)
        
        GUISetState(@SW_SHOWNOACTIVATE, $hIdentifyGUI)
        $aIdentifyGUIs[$i] = $hIdentifyGUI
        
        ; Cleanup
        _GDIPlus_GraphicsDispose($hGraphic)
        _GDIPlus_BrushDispose($hBrushShadow)
        _GDIPlus_BrushDispose($hBrushBg)
        _GDIPlus_BrushDispose($hBrush)
        _GDIPlus_FontDispose($hFont)
        _GDIPlus_StringFormatDispose($hFormat)
    Next
    
    ; Zeige für 2 Sekunden
    Sleep(2000)
    
    ; Schließe alle Identifikations-Fenster
    For $i = 1 To $g_iMonitorCount
        GUIDelete($aIdentifyGUIs[$i])
    Next
    
    _LogInfo("Monitor-Identifikation beendet")
EndFunc

; Zeigt System-Informationen im Visualizer an
Func _ShowVisualizerInfo()
    Local $aMonitors = _GetMonitors()
    Local $sInfo = "=== MONITOR-SYSTEM INFORMATIONEN ===" & @CRLF & @CRLF
    
    $sInfo &= "Anzahl Monitore: " & $aMonitors[0][0] & @CRLF
    $sInfo &= "Aktueller Monitor: " & $g_iCurrentScreenNumber & @CRLF
    $sInfo &= "GUI Status: " & ($g_bWindowIsOut ? "Ausgefahren (" & $g_sWindowIsAt & ")" : "Eingefahren") & @CRLF
    $sInfo &= "Slider Modus: " & (_GetCurrentSliderMode()) & @CRLF & @CRLF
    
    $sInfo &= "MONITOR DETAILS:" & @CRLF
    $sInfo &= "─────────────────────────────" & @CRLF
    
    For $i = 1 To $aMonitors[0][0]
        $sInfo &= "Monitor " & $i & ": " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1]
        $sInfo &= " @ Position " & $aMonitors[$i][2] & "," & $aMonitors[$i][3]
        If $i = $g_iCurrentScreenNumber Then $sInfo &= " (AKTUELL)"
        $sInfo &= @CRLF
    Next
    
    $sInfo &= @CRLF & "VISUALIZER STEUERUNG:" & @CRLF
    $sInfo &= "─────────────────────────────" & @CRLF
    $sInfo &= "• Klick auf Monitor: Zu diesem Monitor wechseln" & @CRLF
    $sInfo &= "• Orange GUI: Ausgefahren (mit Verbindungslinie)" & @CRLF
    $sInfo &= "• Grüne GUI: Eingefahren im Monitor" & @CRLF
    $sInfo &= "• Gelber Bereich: Sichtbarer Teil (8 Pixel)" & @CRLF
    
    MsgBox(64, "Monitor-Visualizer Info", $sInfo)
EndFunc

; Hilfsfunktion um aktuellen Slider-Modus zu ermitteln
Func _GetCurrentSliderMode()
    If $g_bContinuousSlideMode Then
        Return "Continuous (Empfohlen)"
    ElseIf $g_bClassicSliderMode Then
        Return "Classic (2-Klick)"
    ElseIf $g_bDirectSlideMode Then
        Return "Direct"
    Else
        Return "Standard"
    EndIf
EndFunc

; Aktualisiert die Windows 11 Visualisierung
Func _UpdateVisualization()
    If Not IsHWnd($g_hVisualizerGUI) Then Return

    ; Prüfe auf Monitor-Konfigurationsänderungen
    Static $iLastMonitorCount = 0
    Static $sLastMonitorConfig = ""

    ; Hole aktuelle Monitor-Konfiguration
    Local $aCurrentMonitors = _GetMonitors()
    Local $iCurrentCount = $aCurrentMonitors[0][0]
    Local $sCurrentConfig = ""

    ; Erstelle Config-String zur Änderungserkennung
    For $i = 1 To $iCurrentCount
        $sCurrentConfig &= $aCurrentMonitors[$i][0] & "x" & $aCurrentMonitors[$i][1] & "@" & $aCurrentMonitors[$i][2] & "," & $aCurrentMonitors[$i][3] & "|"
    Next

    ; Prüfe auf Änderungen
    If $iCurrentCount <> $iLastMonitorCount Or $sCurrentConfig <> $sLastMonitorConfig Then
        _LogInfo("Monitor-Konfiguration geändert! Anzahl: " & $iLastMonitorCount & " -> " & $iCurrentCount)

        ; Aktualisiere globale Monitor-Daten
        $g_aMonitors = $aCurrentMonitors
        $g_iMonitorCount = $iCurrentCount

        ; Berechne Skalierung neu
        _CalculateScale()

        ; Merke neue Konfiguration
        $iLastMonitorCount = $iCurrentCount
        $sLastMonitorConfig = $sCurrentConfig
    EndIf

    ; Aktualisiere aktuellen Monitor basierend auf GUI-Position
    If IsHWnd($g_hMainGUI) Then
        Local $aPos = WinGetPos($g_hMainGUI)
        If IsArray($aPos) Then
            Local $iDetectedMonitor = _GetMonitorAtPoint($aPos[0] + $aPos[2]/2, $aPos[1] + $aPos[3]/2)
            If $iDetectedMonitor <> $g_iCurrentScreenNumber Then
                _LogDebug("Monitor-Wechsel erkannt: " & $g_iCurrentScreenNumber & " -> " & $iDetectedMonitor)
                $g_iCurrentScreenNumber = $iDetectedMonitor
            EndIf
        EndIf
    EndIf

    _DrawVisualization()
EndFunc

; Schließt die Visualisierung
Func _CloseVisualization()
    _LogInfo("Schließe Windows 11 Monitor-Visualisierung...")

    If IsHWnd($g_hVisualizerGUI) Then
        GUIDelete($g_hVisualizerGUI)
        $g_hVisualizerGUI = 0
    EndIf

    ; GDI+ Objekte freigeben
    If $g_hBackBuffer Then _GDIPlus_GraphicsDispose($g_hBackBuffer)
    If $g_hBitmap Then _GDIPlus_BitmapDispose($g_hBitmap)
    If $g_hGraphics Then _GDIPlus_GraphicsDispose($g_hGraphics)

    _GDIPlus_Shutdown()
EndFunc