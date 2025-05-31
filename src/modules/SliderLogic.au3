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
        If $sInOrOut = $ANIM_OUT Then
            $g_sWindowIsAt = $sSide
        Else
            $g_sWindowIsAt = $POS_CENTER  ; Nach Slide IN ist das Fenster zentriert
        EndIf
        
        _LogInfo("Status aktualisiert: WindowIsOut=" & $g_bWindowIsOut & ", WindowIsAt=" & $g_sWindowIsAt)
    EndIf
    
    Return $bResult
EndFunc

; Interne Funktion für die Animation (basierend auf Original-Code)
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
    
    ; Monitor-Koordinaten für Logging
    _LogDebug("Monitor " & $iScreenNum & " - Position: X=" & $g_aMonitors[$iScreenNum][2] & ", Y=" & $g_aMonitors[$iScreenNum][3] & _
             ", Breite=" & $g_aMonitors[$iScreenNum][0] & ", Höhe=" & $g_aMonitors[$iScreenNum][1])
    _LogDebug("Fenster - Position: X=" & $aWindowPos[0] & ", Y=" & $aWindowPos[1] & _
             ", Breite=" & $aWindowPos[2] & ", Höhe=" & $aWindowPos[3])
    
    ; Berechne wie viel vom Fenster sichtbar bleiben soll (8 Pixel)
    Local $iVisiblePixels = 8
    
    ; Animation in 10 Schritten
    Switch $sSide
        Case $POS_LEFT, "Left"
            If $sInOrOut = $ANIM_OUT Or $sInOrOut = "Out" Then
                ; SLIDE OUT: Fenster fährt nach links heraus (8 Pixel bleiben sichtbar)
                Local $iFinalX = $g_aMonitors[$iScreenNum][2] - $aWindowPos[2] + $iVisiblePixels
                Local $iStepSize = ($aWindowPos[0] - $iFinalX) / 10
                
                For $i = 0 To 10
                    Local $iNewX = $aWindowPos[0] - ($iStepSize * $i)
                    WinMove($hWindow, "", $iNewX, $aWindowPos[1])
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            Else
                ; SLIDE IN: Fenster fährt von ausgefahrener Position zurück in den Monitor
                Local $iFinalX = $g_aMonitors[$iScreenNum][2] + 50  ; 50 Pixel vom linken Rand
                Local $iStepSize = ($iFinalX - $aWindowPos[0]) / 10
                
                For $i = 0 To 10
                    Local $iNewX = $aWindowPos[0] + ($iStepSize * $i)
                    WinMove($hWindow, "", $iNewX, $aWindowPos[1])
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            EndIf
            
        Case $POS_RIGHT, "Right"
            If $sInOrOut = $ANIM_OUT Or $sInOrOut = "Out" Then
                ; SLIDE OUT: Fenster fährt nach rechts heraus (8 Pixel bleiben sichtbar)
                Local $iFinalX = $g_aMonitors[$iScreenNum][2] + $g_aMonitors[$iScreenNum][0] - $iVisiblePixels
                Local $iStepSize = ($iFinalX - $aWindowPos[0]) / 10
                
                For $i = 0 To 10
                    Local $iNewX = $aWindowPos[0] + ($iStepSize * $i)
                    WinMove($hWindow, "", $iNewX, $aWindowPos[1])
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            Else
                ; SLIDE IN: Fenster fährt von ausgefahrener Position zurück in den Monitor
                Local $iFinalX = $g_aMonitors[$iScreenNum][2] + $g_aMonitors[$iScreenNum][0] - $aWindowPos[2] - 50  ; 50 Pixel vom rechten Rand
                Local $iStepSize = ($aWindowPos[0] - $iFinalX) / 10
                
                For $i = 0 To 10
                    Local $iNewX = $aWindowPos[0] - ($iStepSize * $i)
                    WinMove($hWindow, "", $iNewX, $aWindowPos[1])
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            EndIf
            
        Case $POS_TOP, "Top"
            If $sInOrOut = $ANIM_OUT Or $sInOrOut = "Out" Then
                ; SLIDE OUT: Fenster fährt nach oben heraus (8 Pixel bleiben sichtbar)
                Local $iFinalY = $g_aMonitors[$iScreenNum][3] - $aWindowPos[3] + $iVisiblePixels
                Local $iStepSize = ($aWindowPos[1] - $iFinalY) / 10
                
                For $i = 0 To 10
                    Local $iNewY = $aWindowPos[1] - ($iStepSize * $i)
                    WinMove($hWindow, "", $aWindowPos[0], $iNewY)
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            Else
                ; SLIDE IN: Fenster fährt von ausgefahrener Position zurück in den Monitor
                Local $iFinalY = $g_aMonitors[$iScreenNum][3] + 50  ; 50 Pixel vom oberen Rand
                Local $iStepSize = ($iFinalY - $aWindowPos[1]) / 10
                
                For $i = 0 To 10
                    Local $iNewY = $aWindowPos[1] + ($iStepSize * $i)
                    WinMove($hWindow, "", $aWindowPos[0], $iNewY)
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            EndIf
            
        Case $POS_BOTTOM, "Bottom"
            If $sInOrOut = $ANIM_OUT Or $sInOrOut = "Out" Then
                ; SLIDE OUT: Fenster fährt nach unten heraus (8 Pixel bleiben sichtbar)
                Local $iFinalY = $g_aMonitors[$iScreenNum][3] + $g_aMonitors[$iScreenNum][1] - $iVisiblePixels
                Local $iStepSize = ($iFinalY - $aWindowPos[1]) / 10
                
                For $i = 0 To 10
                    Local $iNewY = $aWindowPos[1] + ($iStepSize * $i)
                    WinMove($hWindow, "", $aWindowPos[0], $iNewY)
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            Else
                ; SLIDE IN: Fenster fährt von ausgefahrener Position zurück in den Monitor
                Local $iFinalY = $g_aMonitors[$iScreenNum][3] + $g_aMonitors[$iScreenNum][1] - $aWindowPos[3] - 50  ; 50 Pixel vom unteren Rand
                Local $iStepSize = ($aWindowPos[1] - $iFinalY) / 10
                
                For $i = 0 To 10
                    Local $iNewY = $aWindowPos[1] - ($iStepSize * $i)
                    WinMove($hWindow, "", $aWindowPos[0], $iNewY)
                    _UpdateVisualizationWin11()
                    Sleep(20)
                Next
            EndIf
    EndSwitch
    
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
    
    Local $iCurrentMonitor = $g_iCurrentScreenNumber
    Local $iNextMonitor = 0
    
    ; Verwende physisches Mapping für Links/Rechts-Navigation
    Switch $sDirection
        Case $POS_LEFT
            $iNextMonitor = _GetPhysicalLeftMonitor($iCurrentMonitor)
        Case $POS_RIGHT
            $iNextMonitor = _GetPhysicalRightMonitor($iCurrentMonitor)
        Case Else
            ; Für Top/Bottom verwende die alte Methode
            $iNextMonitor = _HasAdjacentMonitor($iCurrentMonitor, $sDirection)
    EndSwitch
    
    If $iNextMonitor > 0 Then
        _LogInfo("Wechsle von Monitor " & $iCurrentMonitor & " zu Monitor " & $iNextMonitor)
        
        ; Positioniere GUI auf dem neuen Monitor am gegenüberliegenden Rand
        Local $iNewX = $aPos[0]
        Local $iNewY = $aPos[1]
        
        Switch $sDirection
            Case $POS_LEFT
                ; Vom linken Rand des aktuellen zum rechten Rand des nächsten Monitors
                $iNewX = $g_aMonitors[$iNextMonitor][2] + $g_aMonitors[$iNextMonitor][0] - $aPos[2]
                
            Case $POS_RIGHT  
                ; Vom rechten Rand des aktuellen zum linken Rand des nächsten Monitors
                $iNewX = $g_aMonitors[$iNextMonitor][2]
                
            Case $POS_TOP
                ; Vom oberen Rand des aktuellen zum unteren Rand des nächsten Monitors
                $iNewY = $g_aMonitors[$iNextMonitor][3] + $g_aMonitors[$iNextMonitor][1] - $aPos[3]
                
            Case $POS_BOTTOM
                ; Vom unteren Rand des aktuellen zum oberen Rand des nächsten Monitors
                $iNewY = $g_aMonitors[$iNextMonitor][3]
        EndSwitch
        
        ; Y-Position an neuen Monitor anpassen wenn nötig
        ; Behalte relative Position innerhalb des Monitor-Bereichs bei
        Local $iCurrentMonitorHeight = $g_aMonitors[$iCurrentMonitor][1]
        Local $iNextMonitorHeight = $g_aMonitors[$iNextMonitor][1]
        Local $iCurrentRelativeY = ($aPos[1] - $g_aMonitors[$iCurrentMonitor][3]) / $iCurrentMonitorHeight
        
        ; Setze Y-Position relativ zum neuen Monitor (aber nur wenn horizontal gewechselt wird)
        If $sDirection = $POS_LEFT Or $sDirection = $POS_RIGHT Then
            $iNewY = $g_aMonitors[$iNextMonitor][3] + ($iCurrentRelativeY * $iNextMonitorHeight)
            ; Stelle sicher, dass GUI vollständig auf dem Monitor ist
            If $iNewY + $aPos[3] > $g_aMonitors[$iNextMonitor][3] + $iNextMonitorHeight Then
                $iNewY = $g_aMonitors[$iNextMonitor][3] + $iNextMonitorHeight - $aPos[3]
            EndIf
            If $iNewY < $g_aMonitors[$iNextMonitor][3] Then
                $iNewY = $g_aMonitors[$iNextMonitor][3]
            EndIf
        EndIf
        
        _LogInfo("Bewege GUI von (" & $aPos[0] & "," & $aPos[1] & ") zu (" & $iNewX & "," & $iNewY & ")")
        
        ; Bewege GUI zum neuen Monitor
        WinMove($hWindow, "", $iNewX, $iNewY)
        
        ; Update globale Variablen
        $g_iCurrentScreenNumber = $iNextMonitor
        $g_bWindowIsOut = False
        $g_sWindowIsAt = $POS_CENTER
        
        ; Optional: Slide-In Animation auf dem neuen Monitor
        ; Kommentar entfernen für automatisches herausfahren auf dem neuen Monitor
        ; _SlideWindow($hWindow, $iNextMonitor, $sDirection, $ANIM_OUT)
        
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
        If $iMonitor < 1 Then $iMonitor = 1  ; Letzter Fallback
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
            If $iTargetMonitor < 1 Then
                ; Fallback auf primären Monitor
                $iTargetMonitor = _GetPrimaryMonitor()
                If $iTargetMonitor < 1 Then
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
