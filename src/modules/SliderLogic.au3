#include-once
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "MonitorDetection.au3"
#include "Logging.au3"
#include "Visualization.au3"

; ==========================================
; Slider Logic Module
; ==========================================

; Hauptfunktion für Fenster-Sliding
Func _SlideWindow($hWindow, $iScreenNum = Default, $sSide = Default, $sInOrOut = Default)
    ; Parameter-Validierung
    If $g_bIsAnimating Then Return SetError($ERR_ANIMATION_ACTIVE, 0, False)
    If Not IsHWnd($hWindow) Then $hWindow = GUICtrlGetHandle($hWindow)
    If $iScreenNum = Default Then $iScreenNum = $g_iCurrentScreenNumber
    If $sSide = Default Then $sSide = $g_sSwitchSide
    If $sInOrOut = Default Then $sInOrOut = $ANIM_OUT
    
    ; Monitor-Validierung
    If $iScreenNum < 1 Or $iScreenNum > $g_aMonitors[0][0] Then
        Return SetError($ERR_INVALID_MONITOR, 0, False)
    EndIf
    
    $g_bIsAnimating = True
    Local $bResult = __PerformSlideAnimation($hWindow, $iScreenNum, $sSide, $sInOrOut)
    $g_bIsAnimating = False
    
    ; Update globale Variablen
    If $bResult Then
        $g_iCurrentScreenNumber = $iScreenNum
        $g_sSwitchSide = $sSide
        $g_bWindowIsOut = ($sInOrOut = $ANIM_OUT)
        $g_sWindowIsAt = $sSide
    EndIf
    
    Return $bResult
EndFunc

; Interne Funktion für die Animation
Func __PerformSlideAnimation($hWindow, $iScreenNum, $sSide, $sInOrOut)
    Local $aWindowPos = WinGetPos($hWindow)
    If Not IsArray($aWindowPos) Then
        _LogError("Konnte Fensterposition nicht ermitteln")
        Return False
    EndIf
    
    _LogWindowPosition($hWindow, "Vor Animation")
    _LogSlideOperation($sSide, $sInOrOut, $iScreenNum)
    
    ; Sicherstellen, dass wir gültige Monitor-Daten haben
    If $iScreenNum < 1 Or $iScreenNum > $g_aMonitors[0][0] Then
        _LogError("Ungültiger Monitor-Index: " & $iScreenNum)
        Return False
    EndIf
    
    Local $iMovePixelPerStep = Round($aWindowPos[2] / $g_iSlideSteps, 0)
    Local $iStartX, $iStartY, $iEndX, $iEndY
    
    ; Monitor-Koordinaten für Logging
    _LogDebug("Monitor " & $iScreenNum & " - Position: X=" & $g_aMonitors[$iScreenNum][2] & ", Y=" & $g_aMonitors[$iScreenNum][3] & _
             ", Breite=" & $g_aMonitors[$iScreenNum][0] & ", Höhe=" & $g_aMonitors[$iScreenNum][1])
    
    ; Berechne Start- und Endposition basierend auf Richtung
    Switch $sSide
        Case $POS_LEFT
            $iStartY = $aWindowPos[1]
            If $sInOrOut = $ANIM_OUT Then
                $iStartX = $aWindowPos[0]
                $iEndX = $g_aMonitors[$iScreenNum][2] - $aWindowPos[2] + 8  ; 8 Pixel sichtbar
            Else
                $iStartX = $g_aMonitors[$iScreenNum][2] - $aWindowPos[2] + 8
                $iEndX = $g_aMonitors[$iScreenNum][2] + 10  ; Etwas innerhalb des Monitors
            EndIf
            
        Case $POS_RIGHT
            $iStartY = $aWindowPos[1]
            If $sInOrOut = $ANIM_OUT Then
                $iStartX = $aWindowPos[0]
                $iEndX = $g_aMonitors[$iScreenNum][2] + $g_aMonitors[$iScreenNum][0] - 8
            Else
                $iStartX = $g_aMonitors[$iScreenNum][2] + $g_aMonitors[$iScreenNum][0] - 8
                $iEndX = $g_aMonitors[$iScreenNum][2] + $g_aMonitors[$iScreenNum][0] - $aWindowPos[2] - 10
            EndIf
            
        Case $POS_TOP
            $iStartX = $aWindowPos[0]
            If $sInOrOut = $ANIM_OUT Then
                $iStartY = $aWindowPos[1]
                $iEndY = $g_aMonitors[$iScreenNum][3] - $aWindowPos[3] + 8
            Else
                $iStartY = $g_aMonitors[$iScreenNum][3] - $aWindowPos[3] + 8
                $iEndY = $g_aMonitors[$iScreenNum][3] + 10
            EndIf
            
        Case $POS_BOTTOM
            $iStartX = $aWindowPos[0]
            If $sInOrOut = $ANIM_OUT Then
                $iStartY = $aWindowPos[1]
                $iEndY = $g_aMonitors[$iScreenNum][3] + $g_aMonitors[$iScreenNum][1] - 8
            Else
                $iStartY = $g_aMonitors[$iScreenNum][3] + $g_aMonitors[$iScreenNum][1] - 8
                $iEndY = $g_aMonitors[$iScreenNum][3] + $g_aMonitors[$iScreenNum][1] - $aWindowPos[3] - 10
            EndIf
    EndSwitch
    
    _LogDebug("Animation: Start (" & $iStartX & ", " & $iStartY & ") -> Ende (" & $iEndX & ", " & $iEndY & ")")
    
    ; Sicherheitsprüfung: Verhindere, dass Fenster komplett außerhalb des sichtbaren Bereichs landet
    Local $iMinVisible = 8  ; Mindestens 8 Pixel müssen sichtbar bleiben
    
    ; Berechne die Grenzen des virtuellen Desktops (alle Monitore)
    Local $iVirtualLeft = 999999, $iVirtualTop = 999999
    Local $iVirtualRight = -999999, $iVirtualBottom = -999999
    
    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iVirtualLeft Then $iVirtualLeft = $g_aMonitors[$i][2]
        If $g_aMonitors[$i][3] < $iVirtualTop Then $iVirtualTop = $g_aMonitors[$i][3]
        If $g_aMonitors[$i][2] + $g_aMonitors[$i][0] > $iVirtualRight Then $iVirtualRight = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $g_aMonitors[$i][3] + $g_aMonitors[$i][1] > $iVirtualBottom Then $iVirtualBottom = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
    Next
    
    ; Prüfe ob Endposition gültig ist (berücksichtige alle Monitore)
    If $iEndX + $aWindowPos[2] < $iVirtualLeft + $iMinVisible Then
        _LogWarning("Endposition X zu weit links korrigiert")
        $iEndX = $iVirtualLeft + $iMinVisible - $aWindowPos[2]
    ElseIf $iEndX > $iVirtualRight - $iMinVisible Then
        _LogWarning("Endposition X zu weit rechts korrigiert")
        $iEndX = $iVirtualRight - $iMinVisible
    EndIf
    
    If $iEndY + $aWindowPos[3] < $iVirtualTop + $iMinVisible Then
        _LogWarning("Endposition Y zu weit oben korrigiert")
        $iEndY = $iVirtualTop + $iMinVisible - $aWindowPos[3]
    ElseIf $iEndY > $iVirtualBottom - $iMinVisible Then
        _LogWarning("Endposition Y zu weit unten korrigiert")
        $iEndY = $iVirtualBottom - $iMinVisible
    EndIf
    
    _LogDebug("Virtuelle Desktop-Grenzen: " & $iVirtualLeft & "," & $iVirtualTop & " bis " & $iVirtualRight & "," & $iVirtualBottom)
    
    ; Führe Animation aus
    Local $iStepX = ($iEndX - $iStartX) / $g_iSlideSteps
    Local $iStepY = ($iEndY - $iStartY) / $g_iSlideSteps
    
    For $i = 0 To $g_iSlideSteps
        Local $iCurrentX = Round($iStartX + ($iStepX * $i))
        Local $iCurrentY = Round($iStartY + ($iStepY * $i))
        WinMove($hWindow, "", $iCurrentX, $iCurrentY)
        _UpdateVisualization()  ; Visualisierung aktualisieren
        Sleep($g_iAnimationSpeed)
    Next
    
    _LogWindowPosition($hWindow, "Nach Animation")
    
    Return True
EndFunc

; Bestimmt die beste Slide-Richtung basierend auf Monitor-Layout
Func _DetermineSlideDirection($iFromMonitor, $iToMonitor = 0)
    If $iToMonitor = 0 Then
        ; Automatische Richtungsbestimmung
        Return _GetAvailableSlideDirection($iFromMonitor)
    EndIf
    
    ; Bestimme Richtung zwischen zwei Monitoren
    Local $iFromX = $g_aMonitors[$iFromMonitor][2] + ($g_aMonitors[$iFromMonitor][0] / 2)
    Local $iFromY = $g_aMonitors[$iFromMonitor][3] + ($g_aMonitors[$iFromMonitor][1] / 2)
    Local $iToX = $g_aMonitors[$iToMonitor][2] + ($g_aMonitors[$iToMonitor][0] / 2)
    Local $iToY = $g_aMonitors[$iToMonitor][3] + ($g_aMonitors[$iToMonitor][1] / 2)
    
    Local $iDeltaX = $iToX - $iFromX
    Local $iDeltaY = $iToY - $iFromY
    
    If Abs($iDeltaX) > Abs($iDeltaY) Then
        If $iDeltaX > 0 Then
            Return $POS_RIGHT
        Else
            Return $POS_LEFT
        EndIf
    Else
        If $iDeltaY > 0 Then
            Return $POS_BOTTOM
        Else
            Return $POS_TOP
        EndIf
    EndIf
EndFunc

; Ermittelt verfügbare Slide-Richtungen
Func _GetAvailableSlideDirection($iMonitor)
    ; Prüfe alle Richtungen und gib die erste verfügbare zurück
    Local $aDirections[4] = [$POS_TOP, $POS_RIGHT, $POS_BOTTOM, $POS_LEFT]
    
    For $i = 0 To 3
        If Not _HasAdjacentMonitor($iMonitor, $aDirections[$i]) Then
            Return $aDirections[$i]
        EndIf
    Next
    
    ; Wenn alle Richtungen belegt sind, Standard zurückgeben
    Return $POS_TOP
EndFunc

; Bewegt GUI zum nächsten Monitor
Func _MoveToNextMonitor($hWindow, $sDirection)
    Local $aPos = WinGetPos($hWindow)
    If Not IsArray($aPos) Then Return False
    
    Local $iCurrentMonitor = _GetMonitorAtPoint($aPos[0], $aPos[1])
    Local $iNextMonitor = _HasAdjacentMonitor($iCurrentMonitor, $sDirection)
    
    If $iNextMonitor > 0 Then
        ; Slide out vom aktuellen Monitor
        _SlideWindow($hWindow, $iCurrentMonitor, $sDirection, $ANIM_OUT)
        
        ; Positioniere auf dem neuen Monitor
        Local $aPos = WinGetPos($hWindow)
        Local $iNewX = $g_aMonitors[$iNextMonitor][2] + ($g_aMonitors[$iNextMonitor][0] - $aPos[2]) / 2
        Local $iNewY = $g_aMonitors[$iNextMonitor][3] + ($g_aMonitors[$iNextMonitor][1] - $aPos[3]) / 2
        WinMove($hWindow, "", $iNewX, $iNewY)
        
        ; Update globale Variablen
        $g_iCurrentScreenNumber = $iNextMonitor
        
        Return True
    EndIf
    
    Return False
EndFunc

; Zentriert GUI auf einem bestimmten Monitor
Func _CenterOnMonitor($hWindow, $iMonitor = Default)
    If $iMonitor = Default Then $iMonitor = $g_iCurrentScreenNumber
    
    ; Stelle sicher, dass Monitor-Index gültig ist
    If $iMonitor < 1 Or $iMonitor > $g_aMonitors[0][0] Then
        _LogWarning("Ungültiger Monitor-Index in _CenterOnMonitor: " & $iMonitor)
        ; Fallback auf primären Monitor
        $iMonitor = _GetPrimaryMonitor()
        If $iMonitor = 0 Then $iMonitor = 1  ; Letzter Fallback
        _LogInfo("Verwende Monitor " & $iMonitor & " als Fallback")
    EndIf
    
    Local $aPos = WinGetPos($hWindow)
    If Not IsArray($aPos) Then Return False
    
    Local $iX = $g_aMonitors[$iMonitor][2] + ($g_aMonitors[$iMonitor][0] - $aPos[2]) / 2
    Local $iY = $g_aMonitors[$iMonitor][3] + ($g_aMonitors[$iMonitor][1] - $aPos[3]) / 2
    
    WinMove($hWindow, "", $iX, $iY)
    $g_iCurrentScreenNumber = $iMonitor
    $g_bWindowIsOut = False
    $g_sWindowIsAt = $POS_CENTER
    
    Return True
EndFunc

; Toggle Slide In/Out
Func _ToggleSlide($hWindow, $sDirection = Default)
    If $sDirection = Default Then $sDirection = $g_sSwitchSide
    
    If $g_bWindowIsOut Then
        Return _SlideWindow($hWindow, $g_iCurrentScreenNumber, $sDirection, $ANIM_IN)
    Else
        Return _SlideWindow($hWindow, $g_iCurrentScreenNumber, $sDirection, $ANIM_OUT)
    EndIf
EndFunc

; Prüft ob ein Fenster außerhalb des sichtbaren Bereichs ist
Func _IsWindowOutOfBounds($iX, $iY, $iW, $iH)
    ; Berechne die Grenzen des virtuellen Desktops
    Local $iVirtualLeft = 999999, $iVirtualTop = 999999
    Local $iVirtualRight = -999999, $iVirtualBottom = -999999
    
    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iVirtualLeft Then $iVirtualLeft = $g_aMonitors[$i][2]
        If $g_aMonitors[$i][3] < $iVirtualTop Then $iVirtualTop = $g_aMonitors[$i][3]
        If $g_aMonitors[$i][2] + $g_aMonitors[$i][0] > $iVirtualRight Then $iVirtualRight = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $g_aMonitors[$i][3] + $g_aMonitors[$i][1] > $iVirtualBottom Then $iVirtualBottom = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
    Next
    
    ; Mindestens 100 Pixel müssen sichtbar sein
    Local $iMinVisible = 100
    
    ; Prüfe ob Fenster außerhalb ist
    If $iX + $iW < $iVirtualLeft + $iMinVisible Then Return True  ; Zu weit links
    If $iX > $iVirtualRight - $iMinVisible Then Return True        ; Zu weit rechts
    If $iY + $iH < $iVirtualTop + $iMinVisible Then Return True    ; Zu weit oben
    If $iY > $iVirtualBottom - $iMinVisible Then Return True       ; Zu weit unten
    
    Return False
EndFunc

; Bringt die GUI zurück in den sichtbaren Bereich
Func _RecoverLostWindow($hWindow)
    _LogWarning("Führe GUI-Wiederherstellung aus...")
    
    Local $aPos = WinGetPos($hWindow)
    If Not IsArray($aPos) Then
        _LogError("Konnte Fensterposition nicht ermitteln")
        Return False
    EndIf
    
    _LogDebug("Aktuelle Position: X=" & $aPos[0] & ", Y=" & $aPos[1])
    
    ; Berechne die Grenzen des virtuellen Desktops
    Local $iVirtualLeft = 999999, $iVirtualTop = 999999
    Local $iVirtualRight = -999999, $iVirtualBottom = -999999
    
    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iVirtualLeft Then $iVirtualLeft = $g_aMonitors[$i][2]
        If $g_aMonitors[$i][3] < $iVirtualTop Then $iVirtualTop = $g_aMonitors[$i][3]
        If $g_aMonitors[$i][2] + $g_aMonitors[$i][0] > $iVirtualRight Then $iVirtualRight = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $g_aMonitors[$i][3] + $g_aMonitors[$i][1] > $iVirtualBottom Then $iVirtualBottom = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
    Next
    
    ; Prüfe ob Fenster außerhalb ist
    Local $bNeedRecovery = False
    Local $iNewX = $aPos[0], $iNewY = $aPos[1]
    
    ; Mindestens 100 Pixel müssen sichtbar sein
    Local $iMinVisible = 100
    
    If $aPos[0] + $aPos[2] < $iVirtualLeft + $iMinVisible Then
        $iNewX = $iVirtualLeft
        $bNeedRecovery = True
        _LogInfo("Fenster zu weit links")
    ElseIf $aPos[0] > $iVirtualRight - $iMinVisible Then
        $iNewX = $iVirtualRight - $aPos[2]
        $bNeedRecovery = True
        _LogInfo("Fenster zu weit rechts")
    EndIf
    
    If $aPos[1] + $aPos[3] < $iVirtualTop + $iMinVisible Then
        $iNewY = $iVirtualTop
        $bNeedRecovery = True
        _LogInfo("Fenster zu weit oben")
    ElseIf $aPos[1] > $iVirtualBottom - $iMinVisible Then
        $iNewY = $iVirtualBottom - $aPos[3]
        $bNeedRecovery = True
        _LogInfo("Fenster zu weit unten")
    EndIf
    
    ; Wenn Wiederherstellung nötig, zentriere auf aktuellem Monitor
    If $bNeedRecovery Then
        ; Stelle sicher, dass wir einen gültigen Monitor-Index haben
        Local $iTargetMonitor = $g_iCurrentScreenNumber
        If $iTargetMonitor < 1 Or $iTargetMonitor > $g_aMonitors[0][0] Then
            ; Finde den Monitor, auf dem das Fenster aktuell ist
            $iTargetMonitor = _GetMonitorAtPoint($aPos[0] + $aPos[2]/2, $aPos[1] + $aPos[3]/2)
            If $iTargetMonitor = 0 Then
                ; Fallback auf primären Monitor
                $iTargetMonitor = _GetPrimaryMonitor()
                If $iTargetMonitor = 0 Then
                    ; Letzter Fallback auf Monitor 1
                    $iTargetMonitor = 1
                EndIf
            EndIf
            _LogWarning("Korrigiere ungültigen Monitor-Index von " & $g_iCurrentScreenNumber & " auf " & $iTargetMonitor)
            $g_iCurrentScreenNumber = $iTargetMonitor
        EndIf
        
        _LogInfo("Zentriere GUI auf Monitor " & $iTargetMonitor)
        Return _CenterOnMonitor($hWindow, $iTargetMonitor)
    EndIf
    
    _LogInfo("GUI ist im sichtbaren Bereich")
    Return True
EndFunc
