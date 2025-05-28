#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         GUI-Slider-MultiMonitor Team
 Script Function: Slider-Animations- und Bewegungsfunktionen
 
 Datei: slider_functions.au3
 Beschreibung: Funktionen für die GUI-Slider-Animation und -Bewegung
#ce ----------------------------------------------------------------------------

#include-once
#include "globals.au3"
#include "monitor_functions.au3"

; ===============================================
; Funktion: _SlideWindow
; Beschreibung: Animiert das GUI-Fenster ein/aus
; Parameter: $hWindow - GUI Handle
;           $sDirection - Richtung ("Left", "Right", "Top", "Bottom")
;           $sInOrOut - "In" oder "Out"
; ===============================================
Func _SlideWindow($hWindow, $sDirection, $sInOrOut)
    If $g_bAnimationInProgress Then Return False
    
    $g_bAnimationInProgress = True
    Local $aWindowPos = WinGetPos($hWindow)
    If Not IsArray($aWindowPos) Then
        $g_bAnimationInProgress = False
        Return False
    EndIf
    
    Local $iStartX = $aWindowPos[0]
    Local $iStartY = $aWindowPos[1]
    Local $iWidth = $aWindowPos[2]
    Local $iHeight = $aWindowPos[3]
    Local $iEndX = $iStartX
    Local $iEndY = $iStartY
    
    ; Zielposition berechnen
    Switch $sDirection
        Case "Left"
            If $sInOrOut = "Out" Then
                $iEndX = $g_iCurrentScreenX - $iWidth
            Else
                $iEndX = $g_iCurrentScreenX
            EndIf
            
        Case "Right"
            If $sInOrOut = "Out" Then
                $iEndX = $g_iCurrentScreenX + $g_iCurrentScreenWidth
            Else
                $iEndX = $g_iCurrentScreenX + $g_iCurrentScreenWidth - $iWidth
            EndIf
            
        Case "Top"
            If $sInOrOut = "Out" Then
                $iEndY = $g_iCurrentScreenY - $iHeight
            Else
                $iEndY = $g_iCurrentScreenY
            EndIf
            
        Case "Bottom"
            If $sInOrOut = "Out" Then
                $iEndY = $g_iCurrentScreenY + $g_iCurrentScreenHeight
            Else
                $iEndY = $g_iCurrentScreenY + $g_iCurrentScreenHeight - $iHeight
            EndIf
    EndSwitch
    
    ; Animation durchführen
    _AnimateWindowPosition($hWindow, $iStartX, $iStartY, $iEndX, $iEndY)
    
    ; Status aktualisieren
    If $sInOrOut = "Out" Then
        $g_bWindowIsOut = True
        $g_sWindowPosition = $sDirection
    Else
        $g_bWindowIsOut = False
    EndIf
    
    $g_bAnimationInProgress = False
    Return True
EndFunc

; ===============================================
; Funktion: _AnimateWindowPosition
; Beschreibung: Animiert Fenster von Start- zu Endposition
; ===============================================
Func _AnimateWindowPosition($hWindow, $iStartX, $iStartY, $iEndX, $iEndY)
    Local $iStepX = ($iEndX - $iStartX) / $g_iAnimationSteps
    Local $iStepY = ($iEndY - $iStartY) / $g_iAnimationSteps
    
    For $i = 1 To $g_iAnimationSteps
        Local $iNewX = Round($iStartX + ($iStepX * $i))
        Local $iNewY = Round($iStartY + ($iStepY * $i))
        
        WinMove($hWindow, "", $iNewX, $iNewY)
        Sleep($g_iAnimationDelay)
    Next
    
    ; Sicherstellen, dass Endposition exakt erreicht wird
    WinMove($hWindow, "", $iEndX, $iEndY)
EndFunc

; ===============================================
; Funktion: _ToggleSlider
; Beschreibung: Schaltet Slider-Status um
; ===============================================
Func _ToggleSlider($hWindow)
    If $g_bWindowIsOut Then
        _SlideWindow($hWindow, $g_sWindowPosition, "In")
    Else
        ; Standard: Nach oben ausfahren
        _SlideWindow($hWindow, "Top", "Out")
    EndIf
EndFunc

; ===============================================
; Funktion: _MoveToAdjacentMonitor
; Beschreibung: Bewegt GUI zu angrenzendem Monitor
; ===============================================
Func _MoveToAdjacentMonitor($hWindow, $sDirection)
    If $g_bAnimationInProgress Then Return False
    
    ; Angrenzenden Monitor finden
    Local $iTargetMonitor = _FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, $sDirection)
    
    If $iTargetMonitor = -1 Then
        ; Kein angrenzender Monitor - am Rand ausfahren
        If Not $g_bWindowIsOut Or $g_sWindowPosition <> $sDirection Then
            If $g_bWindowIsOut Then
                _SlideWindow($hWindow, $g_sWindowPosition, "In")
                Sleep(100) ; Kurze Pause zwischen Animationen
            EndIf
            _SlideWindow($hWindow, $sDirection, "Out")
        EndIf
    Else
        ; Zu angrenzendem Monitor wechseln
        _TransitionToMonitor($hWindow, $iTargetMonitor, $sDirection)
    EndIf
    
    Return True
EndFunc

; ===============================================
; Funktion: _TransitionToMonitor
; Beschreibung: Übergang zu anderem Monitor
; ===============================================
Func _TransitionToMonitor($hWindow, $iTargetMonitor, $sFromDirection)
    If $iTargetMonitor < 1 Or $iTargetMonitor > $g_aMonitorInfo[0][0] Then Return False
    
    $g_bAnimationInProgress = True
    
    ; Wenn GUI ausgefahren ist, erst einfahren
    If $g_bWindowIsOut Then
        _SlideWindow($hWindow, $g_sWindowPosition, "In")
        Sleep(50)
    EndIf
    
    ; Position auf neuem Monitor berechnen
    Local $aWindowPos = WinGetPos($hWindow)
    Local $iNewX, $iNewY
    
    ; Monitor-Informationen aktualisieren
    Local $iOldScreenX = $g_iCurrentScreenX
    Local $iOldScreenY = $g_iCurrentScreenY
    
    $g_iCurrentScreenNumber = $iTargetMonitor
    $g_iCurrentScreenX = $g_aMonitorInfo[$iTargetMonitor][2]
    $g_iCurrentScreenY = $g_aMonitorInfo[$iTargetMonitor][3]
    $g_iCurrentScreenWidth = $g_aMonitorInfo[$iTargetMonitor][0]
    $g_iCurrentScreenHeight = $g_aMonitorInfo[$iTargetMonitor][1]
    
    ; Position berechnen basierend auf Übergangsrichtung
    Switch $sFromDirection
        Case "Left"
            ; Von rechts kommend - am rechten Rand positionieren
            $iNewX = $g_iCurrentScreenX + $g_iCurrentScreenWidth - $aWindowPos[2]
            $iNewY = $g_iCurrentScreenY + ($g_iCurrentScreenHeight - $aWindowPos[3]) / 2
            
        Case "Right"
            ; Von links kommend - am linken Rand positionieren
            $iNewX = $g_iCurrentScreenX
            $iNewY = $g_iCurrentScreenY + ($g_iCurrentScreenHeight - $aWindowPos[3]) / 2
            
        Case "Top"
            ; Von unten kommend - am unteren Rand positionieren
            $iNewX = $g_iCurrentScreenX + ($g_iCurrentScreenWidth - $aWindowPos[2]) / 2
            $iNewY = $g_iCurrentScreenY + $g_iCurrentScreenHeight - $aWindowPos[3]
            
        Case "Bottom"
            ; Von oben kommend - am oberen Rand positionieren
            $iNewX = $g_iCurrentScreenX + ($g_iCurrentScreenWidth - $aWindowPos[2]) / 2
            $iNewY = $g_iCurrentScreenY
    EndSwitch
    
    ; Fenster auf neuen Monitor verschieben
    WinMove($hWindow, "", $iNewX, $iNewY)
    
    ; Am gegenüberliegenden Rand ausfahren
    Local $sOppositeDirection = _GetOppositeDirection($sFromDirection)
    _SlideWindow($hWindow, $sOppositeDirection, "Out")
    
    ; Bewegungsmöglichkeiten aktualisieren
    _UpdateMonitorInfo()
    
    $g_bAnimationInProgress = False
    Return True
EndFunc

; ===============================================
; Funktion: _GetOppositeDirection
; Beschreibung: Gibt entgegengesetzte Richtung zurück
; ===============================================
Func _GetOppositeDirection($sDirection)
    Switch $sDirection
        Case "Left"
            Return "Right"
        Case "Right"
            Return "Left"
        Case "Top"
            Return "Bottom"
        Case "Bottom"
            Return "Top"
    EndSwitch
    Return ""
EndFunc

; ===============================================
; Funktion: _CenterWindowOnMonitor
; Beschreibung: Zentriert Fenster auf aktuellem Monitor
; ===============================================
Func _CenterWindowOnMonitor($hWindow)
    Local $aWindowPos = WinGetPos($hWindow)
    If Not IsArray($aWindowPos) Then Return False
    
    Local $iNewX = $g_iCurrentScreenX + ($g_iCurrentScreenWidth - $aWindowPos[2]) / 2
    Local $iNewY = $g_iCurrentScreenY + ($g_iCurrentScreenHeight - $aWindowPos[3]) / 2
    
    WinMove($hWindow, "", $iNewX, $iNewY)
    Return True
EndFunc

; ===============================================
; Funktion: _SnapToEdge
; Beschreibung: Richtet Fenster an Monitor-Kante aus
; ===============================================
Func _SnapToEdge($hWindow, $sEdge)
    Local $aWindowPos = WinGetPos($hWindow)
    If Not IsArray($aWindowPos) Then Return False
    
    Local $iNewX = $aWindowPos[0]
    Local $iNewY = $aWindowPos[1]
    
    Switch $sEdge
        Case "Left"
            $iNewX = $g_iCurrentScreenX
            
        Case "Right"
            $iNewX = $g_iCurrentScreenX + $g_iCurrentScreenWidth - $aWindowPos[2]
            
        Case "Top"
            $iNewY = $g_iCurrentScreenY
            
        Case "Bottom"
            $iNewY = $g_iCurrentScreenY + $g_iCurrentScreenHeight - $aWindowPos[3]
            
        Case "TopLeft"
            $iNewX = $g_iCurrentScreenX
            $iNewY = $g_iCurrentScreenY
            
        Case "TopRight"
            $iNewX = $g_iCurrentScreenX + $g_iCurrentScreenWidth - $aWindowPos[2]
            $iNewY = $g_iCurrentScreenY
            
        Case "BottomLeft"
            $iNewX = $g_iCurrentScreenX
            $iNewY = $g_iCurrentScreenY + $g_iCurrentScreenHeight - $aWindowPos[3]
            
        Case "BottomRight"
            $iNewX = $g_iCurrentScreenX + $g_iCurrentScreenWidth - $aWindowPos[2]
            $iNewY = $g_iCurrentScreenY + $g_iCurrentScreenHeight - $aWindowPos[3]
    EndSwitch
    
    WinMove($hWindow, "", $iNewX, $iNewY)
    Return True
EndFunc

; ===============================================
; Funktion: _SaveWindowPosition
; Beschreibung: Speichert aktuelle Fensterposition
; ===============================================
Func _SaveWindowPosition($hWindow)
    Local $aPos = WinGetPos($hWindow)
    If Not IsArray($aPos) Then Return False
    
    IniWrite($g_sConfigFile, "Window", "X", $aPos[0])
    IniWrite($g_sConfigFile, "Window", "Y", $aPos[1])
    IniWrite($g_sConfigFile, "Window", "Width", $aPos[2])
    IniWrite($g_sConfigFile, "Window", "Height", $aPos[3])
    IniWrite($g_sConfigFile, "Window", "Monitor", $g_iCurrentScreenNumber)
    IniWrite($g_sConfigFile, "Window", "IsOut", $g_bWindowIsOut)
    IniWrite($g_sConfigFile, "Window", "Position", $g_sWindowPosition)
    
    Return True
EndFunc

; ===============================================
; Funktion: _RestoreWindowPosition
; Beschreibung: Stellt gespeicherte Fensterposition wieder her
; ===============================================
Func _RestoreWindowPosition($hWindow)
    Local $iX = IniRead($g_sConfigFile, "Window", "X", -1)
    Local $iY = IniRead($g_sConfigFile, "Window", "Y", -1)
    Local $iWidth = IniRead($g_sConfigFile, "Window", "Width", $GUI_DEFAULT_WIDTH)
    Local $iHeight = IniRead($g_sConfigFile, "Window", "Height", $GUI_DEFAULT_HEIGHT)
    Local $iMonitor = IniRead($g_sConfigFile, "Window", "Monitor", 1)
    Local $bIsOut = IniRead($g_sConfigFile, "Window", "IsOut", "False") = "True"
    Local $sPosition = IniRead($g_sConfigFile, "Window", "Position", "Top")
    
    ; Prüfen ob Monitor noch existiert
    If $iMonitor > $g_aMonitorInfo[0][0] Then $iMonitor = 1
    
    $g_iCurrentScreenNumber = $iMonitor
    _UpdateMonitorInfo()
    
    ; Fenster positionieren
    If $iX = -1 Or $iY = -1 Then
        _CenterWindowOnMonitor($hWindow)
    Else
        WinMove($hWindow, "", $iX, $iY, $iWidth, $iHeight)
    EndIf
    
    ; Status wiederherstellen
    If $bIsOut Then
        _SlideWindow($hWindow, $sPosition, "Out")
    EndIf
    
    Return True
EndFunc
