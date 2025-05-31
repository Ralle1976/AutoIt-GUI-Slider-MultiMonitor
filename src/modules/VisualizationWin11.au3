#include-once
#include <GDIPlus.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
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
Func _InitVisualizationWin11()
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
    _CalculateScaleWin11()

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

    _LogInfo("Windows 11 Style Monitor-Visualisierung initialisiert")
    Return True
EndFunc

; Berechnet den optimalen Skalierungsfaktor
Func _CalculateScaleWin11()
    If Not IsArray($g_aMonitors) Or $g_aMonitors[0][0] = 0 Then
        _LogError("_CalculateScaleWin11: Keine Monitor-Daten verfügbar")
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
        
        ; Erkenne typische DPI-Skalierungen
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
                EndIf
                
                _LogDebug("Monitor " & $i & " DPI-Skalierung: " & Int($g_aMonitorScaling[$i] * 100) & "%")
            EndIf
        EndIf
    Next
EndFunc

; Zeichnet die Windows 11 Style Visualisierung
Func _DrawVisualizationWin11()
    If Not IsHWnd($g_hVisualizerGUI) Then Return

    ; Clear background mit Windows 11 Farbe
    _GDIPlus_GraphicsClear($g_hBackBuffer, $COLOR_WIN11_BG)

    ; Zeichne Titel
    _DrawTitleWin11()

    ; Zeichne Monitore
    _DrawMonitorsWin11()

    ; Zeichne GUI-Position
    _DrawGUIWindowWin11()

    ; Zeichne Identifizieren-Button
    _DrawIdentifyButton()

    ; Buffer auf Bildschirm kopieren
    _GDIPlus_GraphicsDrawImage($g_hGraphics, $g_hBitmap, 0, 0)
EndFunc

; Zeichnet den Titel im Windows 11 Style
Func _DrawTitleWin11()
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

; Zeichnet alle Monitore im Windows 11 Style
Func _DrawMonitorsWin11()
    If Not IsArray($g_aMonitors) Or $g_aMonitors[0][0] = 0 Then Return

    ; Berechne Grenzen für Zentrierung
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

    ; Zentriere das Layout
    Local $iScaledWidth = $iTotalWidth * $g_fScale
    Local $iScaledHeight = $iTotalHeight * $g_fScale
    Local $iOffsetX = ($g_iVisWidth - $iScaledWidth) / 2
    Local $iOffsetY = 80 + (($g_iVisHeight - 160) - $iScaledHeight) / 2

    ; Zeichne jeden Monitor
    For $i = 1 To $g_aMonitors[0][0]
        Local $iX = $iOffsetX + (($g_aMonitors[$i][2] - $iMinX) * $g_fScale)
        Local $iY = $iOffsetY + (($g_aMonitors[$i][3] - $iMinY) * $g_fScale)
        Local $iW = $g_aMonitors[$i][0] * $g_fScale
        Local $iH = $g_aMonitors[$i][1] * $g_fScale

        ; Zeichne Monitor-Schatten
        Local $hBrushShadow = _GDIPlus_BrushCreateSolid($COLOR_WIN11_SHADOW)
        _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX + 2, $iY + 2, $iW, $iH, $hBrushShadow)
        _GDIPlus_BrushDispose($hBrushShadow)

        ; Monitor-Farbe basierend auf Status
        Local $iMonitorColor = $COLOR_WIN11_MONITOR
        If $i = $g_iCurrentScreenNumber Then
            $iMonitorColor = $COLOR_WIN11_SELECTED
        ElseIf $i = $g_iHoveredMonitor Then
            ; Etwas heller bei Hover
            $iMonitorColor = 0xFF1A86D8
        EndIf

        ; Zeichne Monitor-Rechteck mit abgerundeten Ecken
        _DrawRoundedRectangle($iX, $iY, $iW, $iH, 6, $iMonitorColor, $COLOR_WIN11_BORDER)

        ; Zeichne große Monitor-Nummer
        _DrawMonitorNumber($i, $iX, $iY, $iW, $iH)

        ; Zeichne Auflösung
        _DrawMonitorResolution($i, $iX, $iY, $iW, $iH)
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

; Zeichnet die große Monitor-Nummer
Func _DrawMonitorNumber($iMonitor, $iX, $iY, $iW, $iH)
    ; Berechne Schriftgröße basierend auf Monitor-Größe
    Local $iFontSize = Int(Min($iW, $iH) * 0.4)
    If $iFontSize < 24 Then $iFontSize = 24
    If $iFontSize > 72 Then $iFontSize = 72

    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), $iFontSize, 0)
    Local $hBrush = _GDIPlus_BrushCreateSolid($COLOR_WIN11_TEXT)
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1) ; Center horizontal
    _GDIPlus_StringFormatSetLineAlign($hFormat, 1) ; Center vertical

    Local $tLayout = _GDIPlus_RectFCreate($iX, $iY, $iW, $iH)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, String($iMonitor), $hFont, $tLayout, $hFormat, $hBrush)

    _GDIPlus_FontDispose($hFont)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Zeichnet die Monitor-Auflösung
Func _DrawMonitorResolution($iMonitor, $iX, $iY, $iW, $iH)
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Segoe UI"), 9, 0)
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xCCFFFFFF) ; Leicht transparent
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1) ; Center

    ; Text mit × statt x
    Local $sResolution = $g_aMonitors[$iMonitor][0] & " × " & $g_aMonitors[$iMonitor][1]
    
    ; DPI-Info anhängen wenn verfügbar
    If $g_aMonitorScaling[$iMonitor] > 1.0 Then
        $sResolution &= " (" & Int($g_aMonitorScaling[$iMonitor] * 100) & "%)"
    EndIf

    Local $tLayout = _GDIPlus_RectFCreate($iX, $iY + $iH - 25, $iW, 20)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sResolution, $hFont, $tLayout, $hFormat, $hBrush)

    _GDIPlus_FontDispose($hFont)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Zeichnet das GUI-Fenster
Func _DrawGUIWindowWin11()
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

    ; Zeichne GUI als grünes Rechteck mit Transparenz
    Local $hBrush = _GDIPlus_BrushCreateSolid(0x8000FF00) ; Semi-transparent grün
    _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hBrush)
    
    Local $hPen = _GDIPlus_PenCreate(0xFF00AA00, 2)
    _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hPen)
    
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PenDispose($hPen)
EndFunc

; Zeichnet den Identifizieren-Button
Func _DrawIdentifyButton()
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
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, "Identifizieren", $hFont, $tLayout, $hFormat, $hBrush)

    _GDIPlus_FontDispose($hFont)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_StringFormatDispose($hFormat)
EndFunc

; Click-Handler für Visualizer
Func _OnVisualizerClick($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd <> $g_hVisualizerGUI Then Return $GUI_RUNDEFMSG

    Local $iX = BitAND($lParam, 0xFFFF)
    Local $iY = BitShift($lParam, 16)

    ; Prüfe ob Identifizieren-Button geklickt wurde
    If $iX >= $g_iVisWidth - 140 And $iX <= $g_iVisWidth - 40 And _
       $iY >= $g_iVisHeight - 45 And $iY <= $g_iVisHeight - 15 Then
        _IdentifyMonitors()
        Return 0
    EndIf

    ; Prüfe welcher Monitor geklickt wurde
    Local $iClickedMonitor = _GetMonitorAtVisualizerPoint($iX, $iY)
    If $iClickedMonitor > 0 Then
        $g_iCurrentScreenNumber = $iClickedMonitor
        _UpdateVisualizationWin11()
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
        
        If $iHoverMonitor > 0 Then
            ; Zeige Tooltip
            Local $sInfo = "Monitor " & $iHoverMonitor & @CRLF
            $sInfo &= "Auflösung: " & $g_aMonitors[$iHoverMonitor][0] & " × " & $g_aMonitors[$iHoverMonitor][1] & @CRLF
            $sInfo &= "Position: " & $g_aMonitors[$iHoverMonitor][2] & ", " & $g_aMonitors[$iHoverMonitor][3]
            
            If $g_aMonitorScaling[$iHoverMonitor] > 1.0 Then
                $sInfo &= @CRLF & "Skalierung: " & Int($g_aMonitorScaling[$iHoverMonitor] * 100) & "%"
            EndIf
            
            ToolTip($sInfo, MouseGetPos(0) + 15, MouseGetPos(1) + 15)
        Else
            ToolTip("")
        EndIf
        
        _UpdateVisualizationWin11()
    EndIf

    Return 0
EndFunc

; MouseLeave-Handler
Func _OnVisualizerMouseLeave($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd <> $g_hVisualizerGUI Then Return $GUI_RUNDEFMSG
    
    $g_iHoveredMonitor = 0
    $g_iLastHoveredMonitor = 0
    ToolTip("")
    _UpdateVisualizationWin11()
    
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

; Aktualisiert die Windows 11 Visualisierung
Func _UpdateVisualizationWin11()
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
        _CalculateScaleWin11()

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

    _DrawVisualizationWin11()
EndFunc

; Schließt die Visualisierung
Func _CloseVisualizationWin11()
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