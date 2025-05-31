#include-once
#include <GDIPlus.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "MonitorDetection.au3"
#include "Logging.au3"

; ==========================================
; Monitor Visualisierung mit GDI+
; ==========================================

Global $g_hVisualizerGUI = 0
Global $g_hGraphics = 0
Global $g_hBitmap = 0
Global $g_hBackBuffer = 0
Global $g_iVisWidth = 600
Global $g_iVisHeight = 400
Global $g_fScale = 0.1  ; Skalierungsfaktor für die Darstellung

; Farben
;~ Global Const $COLOR_BACKGROUND = 0xFF1E1E1E
Global Const $COLOR_MONITOR = 0xFF2D2D30
Global Const $COLOR_MONITOR_ACTIVE = 0xFF007ACC
Global Const $COLOR_GUI_WINDOW = 0xFF00FF00
Global Const $COLOR_GUI_SLIDING = 0xFFFF0000
Global Const $COLOR_TEXT = 0xFFFFFFFF
Global Const $COLOR_GRID = 0xFF3E3E42

; Initialisiert die Visualisierung
Func _InitVisualization()
    _LogInfo("Initialisiere Monitor-Visualisierung...")

    ; GDI+ initialisieren
    _GDIPlus_Startup()

    ; Visualisierungs-GUI erstellen
    $g_hVisualizerGUI = GUICreate("Monitor Layout - GUI Slider", $g_iVisWidth, $g_iVisHeight, -1, -1, _
                                  BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOOLWINDOW)

    If Not IsHWnd($g_hVisualizerGUI) Then
        _LogError("Konnte Visualisierungs-GUI nicht erstellen")
        Return False
    EndIf

    ; GDI+ Objekte erstellen
    $g_hGraphics = _GDIPlus_GraphicsCreateFromHWND($g_hVisualizerGUI)
    $g_hBitmap = _GDIPlus_BitmapCreateFromGraphics($g_iVisWidth, $g_iVisHeight, $g_hGraphics)
    $g_hBackBuffer = _GDIPlus_ImageGetGraphicsContext($g_hBitmap)

    ; Anti-Aliasing aktivieren
    _GDIPlus_GraphicsSetSmoothingMode($g_hBackBuffer, 2)

    ; Skalierung berechnen
    _CalculateScale()

    ; GUI positionieren (rechts unten)
    Local $iX = @DesktopWidth - $g_iVisWidth - 20
    Local $iY = @DesktopHeight - $g_iVisHeight - 60
    WinMove($g_hVisualizerGUI, "", $iX, $iY)

    ; GUI anzeigen
    GUISetState(@SW_SHOW, $g_hVisualizerGUI)

    _LogInfo("Monitor-Visualisierung initialisiert")
    Return True
EndFunc

; Berechnet den optimalen Skalierungsfaktor
Func _CalculateScale()
    If Not IsArray($g_aMonitors) Or $g_aMonitors[0][0] = 0 Then
        _LogError("_CalculateScale: Keine Monitor-Daten verfügbar")
        Return
    EndIf

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

    ; Skalierung mit etwas Rand berechnen
    Local $iAvailableWidth = $g_iVisWidth - 20   ; Nur 10px Rand links und rechts
    Local $iAvailableHeight = $g_iVisHeight - 60  ; 30px oben für Titel, 30px unten für Status

    Local $fScaleX = ($iTotalWidth > 0) ? ($iAvailableWidth / $iTotalWidth) : 1.0
    Local $fScaleY = ($iTotalHeight > 0) ? ($iAvailableHeight / $iTotalHeight) : 1.0

    $g_fScale = ($fScaleX < $fScaleY) ? $fScaleX : $fScaleY

    _LogDebug("Visualisierungs-Skalierung: " & $g_fScale)
EndFunc

; Zeichnet die Visualisierung
Func _DrawVisualization()
    If Not IsHWnd($g_hVisualizerGUI) Then Return

    ; Clear background
    _GDIPlus_GraphicsClear($g_hBackBuffer, $COLOR_BACKGROUND)

    ; Zeichne Grid
    _DrawGrid()

    ; Zeichne Monitore
    _DrawMonitors()

    ; Zeichne GUI-Position
    _DrawGUIWindow()

    ; Zeichne Info-Text
    _DrawInfoText()

    ; Buffer auf Bildschirm kopieren
    _GDIPlus_GraphicsDrawImage($g_hGraphics, $g_hBitmap, 0, 0)
EndFunc

; Zeichnet das Hintergrund-Grid
Func _DrawGrid()
    Local $hPen = _GDIPlus_PenCreate($COLOR_GRID, 1)

    ; Vertikale Linien
    For $i = 0 To $g_iVisWidth Step 50
        _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $i, 0, $i, $g_iVisHeight, $hPen)
    Next

    ; Horizontale Linien
    For $i = 0 To $g_iVisHeight Step 50
        _GDIPlus_GraphicsDrawLine($g_hBackBuffer, 0, $i, $g_iVisWidth, $i, $hPen)
    Next

    _GDIPlus_PenDispose($hPen)
EndFunc

; Zeichnet alle Monitore
Func _DrawMonitors()
    If Not IsArray($g_aMonitors) Then
        _LogError("g_aMonitors ist kein Array!")
        Return
    EndIf

    If $g_aMonitors[0][0] = 0 Then
        _LogWarning("Keine Monitore zum Zeichnen vorhanden")
        Return
    EndIf

    _LogDebug("Zeichne " & $g_aMonitors[0][0] & " Monitore")
    _LogDebug("g_aMonitors Array-Dimensionen: " & UBound($g_aMonitors, 1) & "x" & UBound($g_aMonitors, 2))

    ; Debug: Zeige alle Monitor-Daten
    For $i = 1 To $g_aMonitors[0][0]
        _LogDebug("Monitor " & $i & ": " & $g_aMonitors[$i][0] & "x" & $g_aMonitors[$i][1] & _
                 " @ " & $g_aMonitors[$i][2] & "," & $g_aMonitors[$i][3])
    Next

    ; Berechne Grenzen aller Monitore für optimale Skalierung
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

    ; Berechne optimale Skalierung und Offset
    Local $iAvailableWidth = $g_iVisWidth - 20   ; Nur 10px Rand links und rechts
    Local $iAvailableHeight = $g_iVisHeight - 60  ; 30px oben für Titel, 30px unten für Status

    Local $fScaleX = ($iTotalWidth > 0) ? ($iAvailableWidth / $iTotalWidth) : 1.0
    Local $fScaleY = ($iTotalHeight > 0) ? ($iAvailableHeight / $iTotalHeight) : 1.0
    Local $fScale = ($fScaleX < $fScaleY) ? $fScaleX : $fScaleY
    If $fScale < 0.05 Then $fScale = 0.05  ; Mindestgröße für Lesbarkeit
    If $fScale > 3.0 Then $fScale = 3.0   ; Maximalgröße

    _LogDebug("Optimierte Skalierung - TotalSize: " & $iTotalWidth & "x" & $iTotalHeight & " Available: " & $iAvailableWidth & "x" & $iAvailableHeight)
    _LogDebug("ScaleX: " & $fScaleX & " ScaleY: " & $fScaleY & " Final: " & $fScale)

    ; Zentriere das Layout optimal
    Local $iScaledWidth = $iTotalWidth * $fScale
    Local $iScaledHeight = $iTotalHeight * $fScale
    Local $iOffsetX = ($g_iVisWidth - $iScaledWidth) / 2
    Local $iOffsetY = 30 + ($iAvailableHeight - $iScaledHeight) / 2  ; 30px für Titel + zentriert im Rest

    ; Brushes und Pens
    Local $hBrushInactive = _GDIPlus_BrushCreateSolid($COLOR_MONITOR)
    Local $hBrushActive = _GDIPlus_BrushCreateSolid($COLOR_MONITOR_ACTIVE)
    Local $hPenBorder = _GDIPlus_PenCreate(0xFF808080, 2)
    Local $hBrushText = _GDIPlus_BrushCreateSolid($COLOR_TEXT)
    ; Größere Schrift basierend auf Monitor-Größe
    Local $iFontSize = Int($fScale * 12)
    If $iFontSize < 10 Then $iFontSize = 10  ; Minimum für Lesbarkeit
    If $iFontSize > 20 Then $iFontSize = 20  ; Maximum
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Arial"), $iFontSize, 1)
    Local $hStringFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hStringFormat, 1)  ; Center align

    For $i = 1 To $g_aMonitors[0][0]
        ; Skalierte Koordinaten (mit Offset für negative Koordinaten)
        Local $iX = $iOffsetX + (($g_aMonitors[$i][2] - $iMinX) * $fScale)
        Local $iY = $iOffsetY + (($g_aMonitors[$i][3] - $iMinY) * $fScale)
        Local $iW = $g_aMonitors[$i][0] * $fScale
        Local $iH = $g_aMonitors[$i][1] * $fScale

        _LogDebug("Monitor " & $i & " - Zeichne bei X=" & $iX & ", Y=" & $iY & ", W=" & $iW & ", H=" & $iH)

        ; Monitor-Rechteck zeichnen
        Local $hBrush = ($i = $g_iCurrentScreenNumber) ? $hBrushActive : $hBrushInactive
        _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hBrush)
        _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hPenBorder)

        ; Monitor-Nummer zeichnen (mit Device-Name wenn verfügbar)
        Local $sMonitorText = "Monitor " & $i
        If UBound($g_aMonitorDetails) > $i And UBound($g_aMonitorDetails, 2) >= 6 Then
            Local $iDisplayNum = _ExtractDisplayNumber($g_aMonitorDetails[$i][0])
            If $iDisplayNum <> 999 Then
                $sMonitorText = "Display " & $iDisplayNum
            EndIf
        EndIf

        Local $tLayout = _GDIPlus_RectFCreate($iX, $iY + $iH/2 - 10, $iW, 20)
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sMonitorText, $hFont, $tLayout, $hStringFormat, $hBrushText)

        ; Auflösung zeichnen
        $tLayout = _GDIPlus_RectFCreate($iX, $iY + $iH/2 + 10, $iW, 20)
        Local $sFontFamily = _GDIPlus_FontFamilyCreate("Arial")
        Local $iFontSizeSmall = Int($iFontSize * 0.8)
        If $iFontSizeSmall < 8 Then $iFontSizeSmall = 8
        Local $hFontSmall = _GDIPlus_FontCreate($sFontFamily, $iFontSizeSmall)
        _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $g_aMonitors[$i][0] & "x" & $g_aMonitors[$i][1], _
                                     $hFontSmall, $tLayout, $hStringFormat, $hBrushText)
        _GDIPlus_FontDispose($hFontSmall)
        _GDIPlus_FontFamilyDispose($sFontFamily)
    Next

    ; Aufräumen
    _GDIPlus_BrushDispose($hBrushInactive)
    _GDIPlus_BrushDispose($hBrushActive)
    _GDIPlus_BrushDispose($hBrushText)
    _GDIPlus_PenDispose($hPenBorder)
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_StringFormatDispose($hStringFormat)
EndFunc

; Zeichnet das GUI-Fenster
Func _DrawGUIWindow()
    If Not IsHWnd($g_hMainGUI) Then Return

    Local $aPos = WinGetPos($g_hMainGUI)
    If Not IsArray($aPos) Then Return

    ; Berechne die gleichen Grenzen und Skalierung wie in _DrawMonitors()
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

    ; Berechne optimale Skalierung und Offset (identisch mit _DrawMonitors)
    Local $iAvailableWidth = $g_iVisWidth - 20   ; Nur 10px Rand links und rechts
    Local $iAvailableHeight = $g_iVisHeight - 60  ; 30px oben für Titel, 30px unten für Status

    Local $fScaleX = ($iTotalWidth > 0) ? ($iAvailableWidth / $iTotalWidth) : 1.0
    Local $fScaleY = ($iTotalHeight > 0) ? ($iAvailableHeight / $iTotalHeight) : 1.0
    Local $fScale = ($fScaleX < $fScaleY) ? $fScaleX : $fScaleY

    ; Sicherstellen, dass Skalierung sinnvoll ist
    If $fScale < 0.05 Then $fScale = 0.05
    If $fScale > 3.0 Then $fScale = 3.0

    ; Zentriere das Layout optimal (identisch mit _DrawMonitors)
    Local $iScaledWidth = $iTotalWidth * $fScale
    Local $iScaledHeight = $iTotalHeight * $fScale
    Local $iOffsetX = ($g_iVisWidth - $iScaledWidth) / 2
    Local $iOffsetY = 30 + ($iAvailableHeight - $iScaledHeight) / 2  ; 30px für Titel + zentriert im Rest

    ; Skalierte Koordinaten (mit Offset für negative Koordinaten)
    Local $iX = $iOffsetX + (($aPos[0] - $iMinX) * $fScale)
    Local $iY = $iOffsetY + (($aPos[1] - $iMinY) * $fScale)
    Local $iW = $aPos[2] * $fScale
    Local $iH = $aPos[3] * $fScale

    ; Farbe basierend auf Status
    Local $iColor = $g_bIsAnimating ? $COLOR_GUI_SLIDING : $COLOR_GUI_WINDOW
    Local $hBrush = _GDIPlus_BrushCreateSolid(BitOR(0x80000000, BitAND($iColor, 0x00FFFFFF)))  ; Semi-transparent
    Local $hPen = _GDIPlus_PenCreate($iColor, 3)

    ; GUI-Rechteck zeichnen
    _GDIPlus_GraphicsFillRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hBrush)
    _GDIPlus_GraphicsDrawRect($g_hBackBuffer, $iX, $iY, $iW, $iH, $hPen)

    ; Bewegungsrichtung anzeigen wenn sliding
    If $g_bIsAnimating Then
        _DrawArrow($iX + $iW/2, $iY + $iH/2, $g_sSwitchSide)
    EndIf

    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PenDispose($hPen)
EndFunc

; Zeichnet einen Pfeil für die Bewegungsrichtung
Func _DrawArrow($iCenterX, $iCenterY, $sDirection)
    Local $hPen = _GDIPlus_PenCreate($COLOR_GUI_SLIDING, 3)
    Local $iLen = 20

    Switch $sDirection
        Case $POS_LEFT
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY, $iCenterX - $iLen, $iCenterY, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX - $iLen, $iCenterY, $iCenterX - $iLen + 5, $iCenterY - 5, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX - $iLen, $iCenterY, $iCenterX - $iLen + 5, $iCenterY + 5, $hPen)

        Case $POS_RIGHT
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY, $iCenterX + $iLen, $iCenterY, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX + $iLen, $iCenterY, $iCenterX + $iLen - 5, $iCenterY - 5, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX + $iLen, $iCenterY, $iCenterX + $iLen - 5, $iCenterY + 5, $hPen)

        Case $POS_TOP
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY, $iCenterX, $iCenterY - $iLen, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY - $iLen, $iCenterX - 5, $iCenterY - $iLen + 5, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY - $iLen, $iCenterX + 5, $iCenterY - $iLen + 5, $hPen)

        Case $POS_BOTTOM
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY, $iCenterX, $iCenterY + $iLen, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY + $iLen, $iCenterX - 5, $iCenterY + $iLen - 5, $hPen)
            _GDIPlus_GraphicsDrawLine($g_hBackBuffer, $iCenterX, $iCenterY + $iLen, $iCenterX + 5, $iCenterY + $iLen - 5, $hPen)
    EndSwitch

    _GDIPlus_PenDispose($hPen)
EndFunc

; Zeichnet Info-Text
Func _DrawInfoText()
    Local $hBrush = _GDIPlus_BrushCreateSolid($COLOR_TEXT)
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Arial"), 12, 1)
    Local $hStringFormat = _GDIPlus_StringFormatCreate()

    ; Titel
    Local $tLayout = _GDIPlus_RectFCreate(5, 5, $g_iVisWidth - 10, 20)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, "Monitor Layout Visualisierung", $hFont, $tLayout, $hStringFormat, $hBrush)

    ; Status-Info
    Local $hFontSmall = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Arial"), 9)
    Local $sStatus = "GUI Status: " & ($g_bWindowIsOut ? "Ausgefahren" : "Normal")
    $sStatus &= " | Position: " & $g_sWindowIsAt
    $sStatus &= " | Monitor: " & $g_iCurrentScreenNumber

    $tLayout = _GDIPlus_RectFCreate(5, $g_iVisHeight - 25, $g_iVisWidth - 10, 20)
    _GDIPlus_GraphicsDrawStringEx($g_hBackBuffer, $sStatus, $hFontSmall, $tLayout, $hStringFormat, $hBrush)

    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_FontDispose($hFontSmall)
    _GDIPlus_StringFormatDispose($hStringFormat)
EndFunc

; Aktualisiert die Visualisierung
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
        _LogInfo("Neue Konfiguration: " & $sCurrentConfig)

        ; WICHTIG: Visualizer komplett leeren vor Neuzeichnung
        _ClearVisualization()

        ; Aktualisiere globale Monitor-Daten
        $g_aMonitors = $aCurrentMonitors
        $g_iMonitorCount = $iCurrentCount

        ; Berechne Skalierung neu
        _CalculateScale()

        ; Merke neue Konfiguration
        $iLastMonitorCount = $iCurrentCount
        $sLastMonitorConfig = $sCurrentConfig

        _LogInfo("Visualisierung gesäubert und automatisch aktualisiert")
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

; Säubert die Visualisierung (leert den Bildschirm)
Func _ClearVisualization()
    If Not IsHWnd($g_hVisualizerGUI) Then Return

    _LogDebug("Säubere Visualizer-Bildschirm...")

    ; Leere den Back-Buffer komplett
    If $g_hBackBuffer Then
        _GDIPlus_GraphicsClear($g_hBackBuffer, $COLOR_BACKGROUND)
    EndIf

    ; Leere auch den Haupt-Graphics-Kontext
    If $g_hGraphics Then
        _GDIPlus_GraphicsClear($g_hGraphics, $COLOR_BACKGROUND)
    EndIf

    ; Sofortige Bildschirm-Aktualisierung
    If $g_hGraphics And $g_hBitmap Then
        _GDIPlus_GraphicsDrawImage($g_hGraphics, $g_hBitmap, 0, 0)
    EndIf

    _LogDebug("Visualizer-Bildschirm gesäubert")
EndFunc

; Schließt die Visualisierung
Func _CloseVisualization()
    _LogInfo("Schließe Monitor-Visualisierung...")

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

; Hilfsfunktion für Rechteck-Struktur
;~ Func _GDIPlus_RectFCreate($iX, $iY, $iWidth, $iHeight)
;~     Local $tRectF = DllStructCreate("float X;float Y;float Width;float Height")
;~     DllStructSetData($tRectF, "X", $iX)
;~     DllStructSetData($tRectF, "Y", $iY)
;~     DllStructSetData($tRectF, "Width", $iWidth)
;~     DllStructSetData($tRectF, "Height", $iHeight)
;~     Return $tRectF
;~ EndFunc
