#include-once
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "SliderLogic.au3"
#include "Logging.au3"

; ==========================================
; Auto-Slide Mode Module
;
; Automatically slides GUI in/out based on mouse position
; - Slides out when mouse leaves visible area
; - Slides in when mouse hovers over visible edge (8 pixels)
; - Configurable delays before sliding
; - Handles all four slide positions
; ==========================================

#Region Auto-Slide Variables
Global $g_bAutoSlideActive = False               ; Auto-slide mode aktiv
Global $g_iAutoSlideDelayOut = 500               ; Verzögerung vor Slide-Out (ms)
Global $g_iAutoSlideDelayIn = 200                ; Verzögerung vor Slide-In (ms)
Global $g_bAutoSlideJustSlideIn = False          ; Verhindert sofortiges Ausfahren nach Einfahren
Global $g_iAutoSlideInTime = 0                    ; Zeitpunkt des letzten Slide-In
Global $g_bAutoSlideDesiredOut = False           ; Gewünschter Zustand: sollte GUI ausgefahren sein?
Global $g_hAutoSlideWindow = 0                    ; Handle des zu slidenden Fensters
Global $g_iAutoSlideTimer = 0                    ; Timer für Verzögerung
Global $g_sAutoSlideDirection = ""               ; Aktuelle Auto-Slide Richtung
Global $g_bAutoSlideMouseOver = False            ; Maus über visible edge
Global $g_bAutoSlidePending = False              ; Auto-slide operation anstehend
Global $g_sAutoSlidePendingAction = ""           ; "IN" oder "OUT"
Global $g_iVisibleEdgePixels = 8                 ; Breite des sichtbaren Randes in Pixel
Global $g_bAutoSlideInitialized = False          ; Auto-slide system initialisiert
#EndRegion Auto-Slide Variables

; Aktiviert/Deaktiviert Auto-Slide Mode
Func _SetAutoSlideMode($bEnable = True, $iDelayOut = 500, $iDelayIn = 200)
    $g_bAutoSlideMode = $bEnable
    $g_bAutoSlideActive = $bEnable
    $g_iAutoSlideDelayOut = $iDelayOut
    $g_iAutoSlideDelayIn = $iDelayIn

    If $bEnable Then
        _LogInfo("Auto-Slide Mode aktiviert - DelayOut: " & $iDelayOut & "ms, DelayIn: " & $iDelayIn & "ms")
        $g_bAutoSlideInitialized = True
    Else
        _LogInfo("Auto-Slide Mode deaktiviert")
        _ResetAutoSlideState()
        $g_bAutoSlideInitialized = False
    EndIf

    Return $g_bAutoSlideActive
EndFunc

; Hauptfunktion für Auto-Slide - wird kontinuierlich aufgerufen
Func _CheckAutoSlide($hWindow)
    If Not $g_bAutoSlideActive Or Not $g_bAutoSlideInitialized Then Return
    If $g_bIsAnimating Then Return  ; Keine Auto-Slide während manueller Animation

    ; Speichere Window Handle für späteren Gebrauch
    $g_hAutoSlideWindow = $hWindow

    ; Hole aktuelle Mausposition
    Local $aMousePos = MouseGetPos()
    If Not IsArray($aMousePos) Then Return

    ; Hole aktuelle Fensterposition
    Local $aWindowPos = WinGetPos($hWindow)
    If Not IsArray($aWindowPos) Then Return

    ; Bestimme ob Maus über GUI ist
    Local $bMouseOverGUI = _IsMouseOverWindow($aMousePos[0], $aMousePos[1], $aWindowPos)

    ; Debug: Status alle 2 Sekunden loggen
    Static $iLastDebugTime = 0
    If TimerDiff($iLastDebugTime) > 2000 Then
        _LogDebug("Auto-Slide Status: GUI=" & ($g_bWindowIsOut ? "OUT" : "IN") & ", Maus=(" & $aMousePos[0] & "," & $aMousePos[1] & "), MouseOverGUI=" & $bMouseOverGUI & ", DesiredOut=" & $g_bAutoSlideDesiredOut & ", JustSlideIn=" & $g_bAutoSlideJustSlideIn)
        $iLastDebugTime = TimerInit()
    EndIf

    ; Vereinfachte und robuste Auto-Slide Logik
    Local $bMouseOverVisibleEdge = False
    If $g_bWindowIsOut Then
        $bMouseOverVisibleEdge = _IsMouseOverVisibleEdge($aMousePos[0], $aMousePos[1], $aWindowPos)
    EndIf

    ; Bestimme gewünschten Zustand basierend auf Mausposition
    If $bMouseOverGUI Or $bMouseOverVisibleEdge Then
        ; Maus ist über GUI oder visible edge -> GUI soll INNEN sein
        $g_bAutoSlideDesiredOut = False

        If $g_bWindowIsOut Then
            ; GUI ist ausgefahren, aber soll innen sein -> Slide IN
            _LogDebug("Auto-Slide: Maus über GUI, starte Slide IN")
            _StartAutoSlideTimer("IN")
        Else
            ; GUI ist bereits innen -> bleibt innen, cancel pending actions
            _CancelAutoSlideTimer()
        EndIf
    Else
        ; Maus ist weg von GUI -> GUI soll AUSSEN sein (nach Delay)
        $g_bAutoSlideDesiredOut = True

        If Not $g_bWindowIsOut Then
            ; GUI ist innen, aber soll aussen sein -> Slide OUT (nur wenn nicht kürzlich eingefahren)
            If Not $g_bAutoSlideJustSlideIn Then
                _LogDebug("Auto-Slide: Maus weg von GUI, starte Slide OUT")
                _StartAutoSlideTimer("OUT")
            Else
                _LogDebug("Auto-Slide: Maus weg von GUI, aber kürzlich eingefahren - warte auf Timer")
                ; WICHTIG: Merke uns, dass wir ausfahren wollen, sobald die Schutzzeit vorbei ist
                ; Dies wird in _ResetJustSlideInFlag() abgearbeitet
            EndIf
        Else
            ; GUI ist bereits ausgefahren -> cancel pending slide-in
            _CancelAutoSlideTimer()
        EndIf
    EndIf

    ; Verarbeite Timer
    _ProcessAutoSlideTimer($hWindow)

    ; Failsafe: Prüfe ob Schutzzeit abgelaufen ist (falls Timer nicht funktioniert)
    If $g_bAutoSlideJustSlideIn And $g_iAutoSlideInTime > 0 Then
        If TimerDiff($g_iAutoSlideInTime) > 1200 Then ; 200ms Extra-Toleranz
            _LogWarning("Auto-Slide Failsafe: Schutzzeit abgelaufen, aber Timer wurde nicht ausgelöst!")
            _ResetJustSlideInFlag()
        EndIf
    EndIf
EndFunc

; Startet Auto-Slide Timer für bestimmte Aktion
Func _StartAutoSlideTimer($sAction)
    If $g_bAutoSlidePending And $g_sAutoSlidePendingAction = $sAction Then
        Return  ; Timer für diese Aktion läuft bereits
    EndIf

    $g_bAutoSlidePending = True
    $g_sAutoSlidePendingAction = $sAction
    $g_iAutoSlideTimer = TimerInit()

    Local $sDirection = $g_bWindowIsOut ? $g_sWindowIsAt : $g_sSwitchSide
    _LogDebug("Auto-Slide Timer gestartet: " & $sAction & " (Richtung: " & $sDirection & ")")
EndFunc

; Cancelt laufenden Auto-Slide Timer
Func _CancelAutoSlideTimer()
    If $g_bAutoSlidePending Then
        _LogDebug("Auto-Slide Timer abgebrochen: " & $g_sAutoSlidePendingAction)
        $g_bAutoSlidePending = False
        $g_sAutoSlidePendingAction = ""
        $g_iAutoSlideTimer = 0
    EndIf
EndFunc

; Verarbeitet Auto-Slide Timer und führt Aktionen aus
Func _ProcessAutoSlideTimer($hWindow)
    If Not $g_bAutoSlidePending Then Return

    Local $iElapsed = TimerDiff($g_iAutoSlideTimer)
    Local $iRequiredDelay = ($g_sAutoSlidePendingAction = "OUT") ? $g_iAutoSlideDelayOut : $g_iAutoSlideDelayIn

    If $iElapsed >= $iRequiredDelay Then
        ; Führe Auto-Slide Aktion aus
        _ExecuteAutoSlideAction($hWindow, $g_sAutoSlidePendingAction)
        _CancelAutoSlideTimer()
    EndIf
EndFunc

; Führt Auto-Slide Aktion aus
Func _ExecuteAutoSlideAction($hWindow, $sAction)
    Local $sDirection = ""

    Switch $sAction
        Case "OUT"
            If Not $g_bWindowIsOut Then
                ; NIEMALS eine manuell gesetzte Richtung überschreiben!
                If $g_sSwitchSide <> "" Then
                    ; Verwende die manuell gesetzte Richtung (z.B. von Button-Klick)
                    $sDirection = $g_sSwitchSide
                    _LogInfo("Auto-Slide OUT mit manuell gesetzter Richtung: " & $sDirection)
                Else
                    ; Nur wenn noch GAR KEINE Richtung gesetzt ist, bestimme eine temporäre
                    $sDirection = _GetAvailableSlideDirection($g_iCurrentScreenNumber)
                    _LogInfo("Auto-Slide OUT mit temporärer Richtung: " & $sDirection & " (überschreibt keine manuelle Richtung)")
                EndIf

                ; Setze Flag um zu verhindern, dass SliderLogic g_sSwitchSide überschreibt
                $g_bAutoSlideActive_Internal = True
                _SlideWindow($hWindow, $g_iCurrentScreenNumber, $sDirection, $ANIM_OUT)
                $g_bAutoSlideActive_Internal = False
                $g_bAutoSlideJustSlideIn = False  ; Reset bei Ausfahren
            EndIf

        Case "IN"
            If $g_bWindowIsOut Then
                ; Verwende die bereits gesetzte Richtung
                $sDirection = $g_sWindowIsAt
                _LogInfo("Auto-Slide IN (Richtung: " & $sDirection & ")")

                ; Setze Flag um zu verhindern, dass SliderLogic g_sSwitchSide überschreibt
                $g_bAutoSlideActive_Internal = True
                _SlideWindow($hWindow, $g_iCurrentScreenNumber, $sDirection, $ANIM_IN)
                $g_bAutoSlideActive_Internal = False
                $g_bAutoSlideJustSlideIn = True   ; Setze Flag nach Einfahren
                $g_iAutoSlideInTime = TimerInit() ; Merke Zeitpunkt des Einfahrens

                ; Starte Timer um "gerade eingefahren" Status nach kurzer Zeit zu löschen
                AdlibRegister("_ResetJustSlideInFlag", 1000)  ; Nach 1 Sekunde reset
            EndIf
    EndSwitch
EndFunc

; Reset des "gerade eingefahren" Status nach Timer
Func _ResetJustSlideInFlag()
    _LogInfo("=== _ResetJustSlideInFlag TIMER AUSGELÖST ===")
    _LogDebug("Vorher: g_bAutoSlideJustSlideIn=" & $g_bAutoSlideJustSlideIn)
    $g_bAutoSlideJustSlideIn = False
    AdlibUnRegister("_ResetJustSlideInFlag")
    _LogDebug("Auto-Slide 'gerade eingefahren' Status zurückgesetzt")
    _LogDebug("Nachher: g_bAutoSlideJustSlideIn=" & $g_bAutoSlideJustSlideIn)

    ; WICHTIG: Prüfe ob GUI ausfahren sollte - nutze aktuelle Mausposition
    _LogDebug("Prüfe ob Auto-Slide OUT nach Timer nötig ist:")
    _LogDebug("- g_bWindowIsOut=" & $g_bWindowIsOut)
    _LogDebug("- g_bAutoSlideActive=" & $g_bAutoSlideActive)
    _LogDebug("- IsHWnd(g_hAutoSlideWindow)=" & IsHWnd($g_hAutoSlideWindow))
    _LogDebug("- g_sSwitchSide=" & $g_sSwitchSide)

    If Not $g_bWindowIsOut And $g_bAutoSlideActive And IsHWnd($g_hAutoSlideWindow) Then
        Local $aMousePos = MouseGetPos()
        Local $aWindowPos = WinGetPos($g_hAutoSlideWindow)

        If IsArray($aMousePos) And IsArray($aWindowPos) Then
            Local $bMouseOverGUI = _IsMouseOverWindow($aMousePos[0], $aMousePos[1], $aWindowPos)

            _LogDebug("Mausposition: X=" & $aMousePos[0] & ", Y=" & $aMousePos[1])
            _LogDebug("GUI-Position: X=" & $aWindowPos[0] & ", Y=" & $aWindowPos[1] & ", W=" & $aWindowPos[2] & ", H=" & $aWindowPos[3])
            _LogDebug("Maus über GUI: " & $bMouseOverGUI)

            If Not $bMouseOverGUI Then
                _LogInfo("=== TIMER SLIDE-OUT AKTIVIERT ===")
                _LogInfo("Schutzzeit abgelaufen - Maus ist NICHT über GUI (Pos: " & $aMousePos[0] & "," & $aMousePos[1] & "), starte Slide-Out")
                _LogInfo("Verwende Slide-Richtung: " & $g_sSwitchSide)

                ; SICHERHEITSCHECK: Stelle sicher, dass g_sSwitchSide gesetzt ist
                If $g_sSwitchSide = "" Then
                    _LogWarning("g_sSwitchSide ist leer! Verwende Fallback-Richtung.")
                    $g_sSwitchSide = $POS_TOP  ; Fallback
                EndIf

                $g_bAutoSlideDesiredOut = True
                _StartAutoSlideTimer("OUT")
            Else
                _LogDebug("Schutzzeit abgelaufen - Maus ist noch über GUI, bleibe eingefahren")
            EndIf
        Else
            _LogWarning("Schutzzeit abgelaufen - konnte Maus/Fenster-Position nicht ermitteln")
        EndIf
    Else
        _LogDebug("Auto-Slide OUT nicht nötig - Bedingungen nicht erfüllt")
    EndIf
EndFunc

; Prüft ob Maus über einem Fenster ist
Func _IsMouseOverWindow($iMouseX, $iMouseY, $aWindowPos)
    Return ($iMouseX >= $aWindowPos[0] And $iMouseX <= $aWindowPos[0] + $aWindowPos[2] And _
            $iMouseY >= $aWindowPos[1] And $iMouseY <= $aWindowPos[1] + $aWindowPos[3])
EndFunc

; Prüft ob Maus über dem sichtbaren Rand eines ausgefahrenen Fensters ist
Func _IsMouseOverVisibleEdge($iMouseX, $iMouseY, $aWindowPos)
    If Not $g_bWindowIsOut Then Return False

    Local $sDirection = $g_sWindowIsAt
    Local $iEdgeThickness = $g_iVisibleEdgePixels

    Switch $sDirection
        Case $POS_LEFT, "Left"
            ; Visible edge ist rechts vom Fenster
            Local $iEdgeLeft = $aWindowPos[0] + $aWindowPos[2] - $iEdgeThickness
            Local $iEdgeRight = $aWindowPos[0] + $aWindowPos[2]
            Local $iEdgeTop = $aWindowPos[1]
            Local $iEdgeBottom = $aWindowPos[1] + $aWindowPos[3]

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)

        Case $POS_RIGHT, "Right"
            ; Visible edge ist links vom Fenster
            Local $iEdgeLeft = $aWindowPos[0]
            Local $iEdgeRight = $aWindowPos[0] + $iEdgeThickness
            Local $iEdgeTop = $aWindowPos[1]
            Local $iEdgeBottom = $aWindowPos[1] + $aWindowPos[3]

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)

        Case $POS_TOP, "Top"
            ; Visible edge ist unten vom Fenster
            Local $iEdgeLeft = $aWindowPos[0]
            Local $iEdgeRight = $aWindowPos[0] + $aWindowPos[2]
            Local $iEdgeTop = $aWindowPos[1] + $aWindowPos[3] - $iEdgeThickness
            Local $iEdgeBottom = $aWindowPos[1] + $aWindowPos[3]

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)

        Case $POS_BOTTOM, "Bottom"
            ; Visible edge ist oben vom Fenster
            Local $iEdgeLeft = $aWindowPos[0]
            Local $iEdgeRight = $aWindowPos[0] + $aWindowPos[2]
            Local $iEdgeTop = $aWindowPos[1]
            Local $iEdgeBottom = $aWindowPos[1] + $iEdgeThickness

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)
    EndSwitch

    Return False
EndFunc

; Erweiterte Visible Edge Detection mit Monitor-Berücksichtigung
Func _IsMouseOverVisibleEdgeExtended($iMouseX, $iMouseY, $aWindowPos, $iMonitor)
    If Not $g_bWindowIsOut Then Return False
    If $iMonitor < 1 Or $iMonitor > $g_aMonitors[0][0] Then Return False

    Local $sDirection = $g_sWindowIsAt
    Local $iEdgeThickness = $g_iVisibleEdgePixels

    ; Hole Monitor-Grenzen
    Local $iMonitorLeft = $g_aMonitors[$iMonitor][2]
    Local $iMonitorRight = $g_aMonitors[$iMonitor][2] + $g_aMonitors[$iMonitor][0]
    Local $iMonitorTop = $g_aMonitors[$iMonitor][3]
    Local $iMonitorBottom = $g_aMonitors[$iMonitor][3] + $g_aMonitors[$iMonitor][1]

    Switch $sDirection
        Case $POS_LEFT, "Left"
            ; Fenster ist links ausgefahren, visible edge am rechten Monitor-Rand
            Local $iEdgeLeft = $iMonitorLeft
            Local $iEdgeRight = $iMonitorLeft + $iEdgeThickness
            Local $iEdgeTop = _Max($aWindowPos[1], $iMonitorTop)
            Local $iEdgeBottom = _Min($aWindowPos[1] + $aWindowPos[3], $iMonitorBottom)

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)

        Case $POS_RIGHT, "Right"
            ; Fenster ist rechts ausgefahren, visible edge am linken Monitor-Rand
            Local $iEdgeLeft = $iMonitorRight - $iEdgeThickness
            Local $iEdgeRight = $iMonitorRight
            Local $iEdgeTop = _Max($aWindowPos[1], $iMonitorTop)
            Local $iEdgeBottom = _Min($aWindowPos[1] + $aWindowPos[3], $iMonitorBottom)

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)

        Case $POS_TOP, "Top"
            ; Fenster ist oben ausgefahren, visible edge am unteren Monitor-Rand
            Local $iEdgeLeft = _Max($aWindowPos[0], $iMonitorLeft)
            Local $iEdgeRight = _Min($aWindowPos[0] + $aWindowPos[2], $iMonitorRight)
            Local $iEdgeTop = $iMonitorTop
            Local $iEdgeBottom = $iMonitorTop + $iEdgeThickness

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)

        Case $POS_BOTTOM, "Bottom"
            ; Fenster ist unten ausgefahren, visible edge am oberen Monitor-Rand
            Local $iEdgeLeft = _Max($aWindowPos[0], $iMonitorLeft)
            Local $iEdgeRight = _Min($aWindowPos[0] + $aWindowPos[2], $iMonitorRight)
            Local $iEdgeTop = $iMonitorBottom - $iEdgeThickness
            Local $iEdgeBottom = $iMonitorBottom

            Return ($iMouseX >= $iEdgeLeft And $iMouseX <= $iEdgeRight And _
                    $iMouseY >= $iEdgeTop And $iMouseY <= $iEdgeBottom)
    EndSwitch

    Return False
EndFunc

; Konfiguriert Auto-Slide Parameter
Func _ConfigureAutoSlide($iDelayOut = Default, $iDelayIn = Default, $iVisiblePixels = Default)
    If $iDelayOut <> Default Then
        $g_iAutoSlideDelayOut = _Max(100, _Min(5000, $iDelayOut))  ; 100ms bis 5000ms
        _LogInfo("Auto-Slide DelayOut gesetzt auf: " & $g_iAutoSlideDelayOut & "ms")
    EndIf

    If $iDelayIn <> Default Then
        $g_iAutoSlideDelayIn = _Max(50, _Min(3000, $iDelayIn))     ; 50ms bis 3000ms
        _LogInfo("Auto-Slide DelayIn gesetzt auf: " & $g_iAutoSlideDelayIn & "ms")
    EndIf

    If $iVisiblePixels <> Default Then
        $g_iVisibleEdgePixels = _Max(4, _Min(20, $iVisiblePixels)) ; 4px bis 20px
        _LogInfo("Auto-Slide VisibleEdge gesetzt auf: " & $g_iVisibleEdgePixels & "px")
    EndIf

    Return True
EndFunc

; Gibt Auto-Slide Status zurück
Func _GetAutoSlideStatus()
    Local $aStatus[7]
    $aStatus[0] = $g_bAutoSlideActive
    $aStatus[1] = $g_iAutoSlideDelayOut
    $aStatus[2] = $g_iAutoSlideDelayIn
    $aStatus[3] = $g_iVisibleEdgePixels
    $aStatus[4] = $g_bAutoSlidePending
    $aStatus[5] = $g_sAutoSlidePendingAction
    $aStatus[6] = $g_bAutoSlideInitialized

    Return $aStatus
EndFunc

; Setzt Auto-Slide State zurück
Func _ResetAutoSlideState()
    $g_bAutoSlidePending = False
    $g_sAutoSlidePendingAction = ""
    $g_iAutoSlideTimer = 0
    $g_bAutoSlideMouseOver = False
    $g_sAutoSlideDirection = ""
    $g_bAutoSlideJustSlideIn = False
    $g_bAutoSlideDesiredOut = False       ; Reset des gewünschten Zustands
    $g_bAutoSlideActive_Internal = False  ; Reset der internen Flag
    $g_hAutoSlideWindow = 0               ; Reset des Window Handles

    ; Entferne auch den Timer falls aktiv
    AdlibUnRegister("_ResetJustSlideInFlag")

    _LogDebug("Auto-Slide State zurückgesetzt")
EndFunc

; Pausiert Auto-Slide temporär
Func _PauseAutoSlide($bPause = True)
    Static $bWasActive = False

    If $bPause Then
        $bWasActive = $g_bAutoSlideActive
        $g_bAutoSlideActive = False
        _CancelAutoSlideTimer()
        _LogDebug("Auto-Slide pausiert")
    Else
        $g_bAutoSlideActive = $bWasActive
        _LogDebug("Auto-Slide fortgesetzt")
    EndIf

    Return $g_bAutoSlideActive
EndFunc

; Bestimmt optimale Auto-Slide Richtung basierend auf Monitor-Layout
Func _DetermineAutoSlideDirection($iMonitor = Default)
    If $iMonitor = Default Then $iMonitor = $g_iCurrentScreenNumber

    ; NIEMALS eine bereits manuell gesetzte Richtung überschreiben!
    If $g_sSwitchSide <> "" Then
        _LogDebug("Auto-Slide verwendet manuell gesetzte Richtung: " & $g_sSwitchSide)
        Return $g_sSwitchSide
    EndIf

    ; Ermittle beste Richtung basierend auf Monitor-Layout, aber setze sie NICHT global
    Local $sDirection = _GetAvailableSlideDirection($iMonitor)

    _LogInfo("Auto-Slide temporäre Richtung bestimmt: " & $sDirection & " für Monitor " & $iMonitor & " (überschreibt NICHT manuell gesetzte Richtung)")

    ; WICHTIG: Überschreibe $g_sSwitchSide NICHT - das ist für manuelle Button-Klicks reserviert!
    Return $sDirection
EndFunc

; Debug-Funktion für Auto-Slide Status
Func _DebugAutoSlideState($hWindow)
    If Not $g_bAutoSlideActive Then Return "Auto-Slide deaktiviert"

    Local $aMousePos = MouseGetPos()
    Local $aWindowPos = WinGetPos($hWindow)
    Local $bMouseOverGUI = _IsMouseOverWindow($aMousePos[0], $aMousePos[1], $aWindowPos)
    Local $bMouseOverEdge = _IsMouseOverVisibleEdge($aMousePos[0], $aMousePos[1], $aWindowPos)

    Local $sDebugInfo = "Auto-Slide Debug:" & @CRLF
    $sDebugInfo &= "- Aktiv: " & $g_bAutoSlideActive & @CRLF
    $sDebugInfo &= "- WindowIsOut: " & $g_bWindowIsOut & @CRLF
    $sDebugInfo &= "- WindowIsAt: " & $g_sWindowIsAt & @CRLF
    $sDebugInfo &= "- Maus über GUI: " & $bMouseOverGUI & @CRLF
    $sDebugInfo &= "- Maus über Edge: " & $bMouseOverEdge & @CRLF
    $sDebugInfo &= "- Timer aktiv: " & $g_bAutoSlidePending & @CRLF
    $sDebugInfo &= "- Pending Action: " & $g_sAutoSlidePendingAction & @CRLF
    $sDebugInfo &= "- DelayOut: " & $g_iAutoSlideDelayOut & "ms" & @CRLF
    $sDebugInfo &= "- DelayIn: " & $g_iAutoSlideDelayIn & "ms" & @CRLF
    $sDebugInfo &= "- VisiblePixels: " & $g_iVisibleEdgePixels & "px" & @CRLF

    If $g_bAutoSlidePending Then
        Local $iElapsed = TimerDiff($g_iAutoSlideTimer)
        Local $iRequired = ($g_sAutoSlidePendingAction = "OUT") ? $g_iAutoSlideDelayOut : $g_iAutoSlideDelayIn
        $sDebugInfo &= "- Timer Elapsed: " & $iElapsed & "/" & $iRequired & "ms" & @CRLF
    EndIf

    Return $sDebugInfo
EndFunc

; Aktiviert Auto-Slide mit optimierten Standard-Einstellungen
Func _EnableAutoSlideOptimized($hWindow)
    ; Bestimme optimale Richtung
    _DetermineAutoSlideDirection()

    ; Aktiviere Auto-Slide mit optimierten Delays
    _SetAutoSlideMode(True, 750, 150)  ; Etwas längere Verzögerung für Slide-Out

    _LogInfo("Auto-Slide mit optimierten Einstellungen aktiviert")
    Return True
EndFunc

; Kompatibilitätsfunktionen für bestehenden Code
Func _SetAutoSlideDelay($iDelay)
    _ConfigureAutoSlide($iDelay, Default, Default)
    Return True
EndFunc

; Legacy-Funktion für Rückwärtskompatibilität
Func _SlideIn()
    If $g_bWindowIsOut Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $g_sWindowIsAt, $ANIM_IN)
    EndIf
EndFunc

; Legacy-Funktion für Rückwärtskompatibilität
Func _SlideDirection($sDirection)
    If Not $g_bWindowIsOut Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $sDirection, $ANIM_OUT)
    EndIf
EndFunc

; Prüft ob GUI vollständig sichtbar ist (Legacy-Funktion)
Func _IsGUIFullyVisible()
    If Not IsHWnd($g_hMainGUI) Then Return False

    Local $aPos = WinGetPos($g_hMainGUI)
    If Not IsArray($aPos) Then Return False

    ; Prüfe ob GUI vollständig im Monitor ist
    Local $iMonLeft = $g_aMonitors[$g_iCurrentScreenNumber][2]
    Local $iMonTop = $g_aMonitors[$g_iCurrentScreenNumber][3]
    Local $iMonRight = $iMonLeft + $g_aMonitors[$g_iCurrentScreenNumber][0]
    Local $iMonBottom = $iMonTop + $g_aMonitors[$g_iCurrentScreenNumber][1]

    Return ($aPos[0] >= $iMonLeft And _
            $aPos[1] >= $iMonTop And _
            $aPos[0] + $aPos[2] <= $iMonRight And _
            $aPos[1] + $aPos[3] <= $iMonBottom)
EndFunc