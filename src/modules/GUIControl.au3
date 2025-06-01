#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "SliderLogic.au3"
#include "ConfigManager.au3"
#include "MonitorDetection.au3"

; Konstante für Drag-Operation
;~ Global Const $HTCAPTION = 2

; ==========================================
; GUI Control Module
; ==========================================

; Erstellt das Haupt-GUI
Func _CreateMainGUI()
    ; GUI erstellen
    $g_hMainGUI = GUICreate("Multi-Monitor Slider", $g_iGUIWidth, $g_iGUIHeight, -1, -1, _
                            BitOR($WS_POPUP, $WS_BORDER), BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST))

    If Not IsHWnd($g_hMainGUI) Then
        MsgBox(16, "Fehler", "GUI konnte nicht erstellt werden!")
        Return False
    EndIf

    ; GUI-Hintergrund
    GUISetBkColor(0x2B2B2B, $g_hMainGUI)

    ; Titel-Label
    Local $lblTitle = GUICtrlCreateLabel("Multi-Monitor Slider", 10, 10, $g_iGUIWidth - 20, 30, $SS_CENTER)
    GUICtrlSetFont($lblTitle, 16, 800, 0, "Arial")
    GUICtrlSetColor($lblTitle, 0xFFFFFF)

    ; Monitor-Info Label
    Local $lblMonitorInfo = GUICtrlCreateLabel("Monitor: " & $g_iCurrentScreenNumber, 10, 50, $g_iGUIWidth - 20, 20, $SS_CENTER)
    GUICtrlSetFont($lblMonitorInfo, 10, 400, 0, "Arial")
    GUICtrlSetColor($lblMonitorInfo, 0xAAAAAA)

    ; Kontroll-Buttons
    Local $btnLeft = GUICtrlCreateButton("◄", 10, 80, 60, 40)
    Local $btnRight = GUICtrlCreateButton("►", $g_iGUIWidth - 70, 80, 60, 40)
    Local $btnUp = GUICtrlCreateButton("▲", ($g_iGUIWidth - 60) / 2, 80, 60, 40)
    Local $btnDown = GUICtrlCreateButton("▼", ($g_iGUIWidth - 60) / 2, 130, 60, 40)

    ; Center Button
    Local $btnCenter = GUICtrlCreateButton("Center", ($g_iGUIWidth - 100) / 2, 190, 100, 30)

    ; Status-Label
    Local $lblStatus = GUICtrlCreateLabel("Bereit", 10, $g_iGUIHeight - 30, $g_iGUIWidth - 20, 20, $SS_CENTER)
    GUICtrlSetFont($lblStatus, 9, 400, 0, "Arial")
    GUICtrlSetColor($lblStatus, 0x00FF00)

    ; Speichere Control-IDs global für späteren Zugriff
    $g_idLblMonitorInfo = $lblMonitorInfo
    $g_idLblStatus = $lblStatus
    $g_idBtnLeft = $btnLeft
    $g_idBtnRight = $btnRight
    $g_idBtnUp = $btnUp
    $g_idBtnDown = $btnDown
    $g_idBtnCenter = $btnCenter

    ; Event-Handler registrieren
    GUISetOnEvent($GUI_EVENT_CLOSE, "_OnClose", $g_hMainGUI)
    GUISetOnEvent($GUI_EVENT_PRIMARYDOWN, "_OnPrimaryDown", $g_hMainGUI)

    ; Button Events
    GUICtrlSetOnEvent($btnLeft, "_OnButtonLeft")
    GUICtrlSetOnEvent($btnRight, "_OnButtonRight")
    GUICtrlSetOnEvent($btnUp, "_OnButtonUp")
    GUICtrlSetOnEvent($btnDown, "_OnButtonDown")
    GUICtrlSetOnEvent($btnCenter, "_OnButtonCenter")

    Return True
EndFunc

; Event: GUI schließen
Func _OnClose()
    ; Speichere Position wenn aktiviert
    Local $aBehavior = _GetBehaviorSettings()
    For $i = 0 To UBound($aBehavior) - 1
        If $aBehavior[$i][0] = "SavePositionOnExit" And $aBehavior[$i][1] Then
            _SaveConfig()
            ExitLoop
        EndIf
    Next

    GUIDelete($g_hMainGUI)
    Exit
EndFunc

; Event: Primäre Maustaste gedrückt (für Drag)
Func _OnPrimaryDown()
    ; Implementierung für GUI-Dragging
    Local $aCursorInfo = GUIGetCursorInfo($g_hMainGUI)
    If Not IsArray($aCursorInfo) Then Return

    ; Nur wenn nicht auf einem Control geklickt wurde
    If $aCursorInfo[4] = 0 Then
        ; Beginne Drag-Operation
        DllCall("user32.dll", "int", "SendMessage", "hWnd", $g_hMainGUI, "int", $WM_NCLBUTTONDOWN, "int", $HTCAPTION, "int", 0)

        ; Nach dem Drag Monitor aktualisieren
        _UpdateCurrentMonitor()
    EndIf
EndFunc

; Button Events
Func _OnButtonLeft()
    _UpdateStatus("Slide nach links...")
    _LogDebug("=== BUTTON LEFT PRESSED ===")
    _LogDebug("Current Monitor: " & $g_iCurrentScreenNumber)
    _LogDebug("Window Status: " & ($g_bWindowIsOut ? "OUT" : "IN") & " at " & $g_sWindowIsAt)

    If $g_bClassicSliderMode Then
        ; Klassischer Modus: 1. Klick = Monitor wechseln, 2. Klick = Slide Out
        _ClassicSlideLeft()
    ElseIf $g_bDirectSlideMode Then
        ; Direct Modus: Sofort Slide (ignoriert Nachbarn)
        _DirectSlideLeft()
    ElseIf $g_bContinuousSlideMode Then
        ; Continuous Modus: Kontinuierliche Fahrt bis zum Rand
        _LogDebug("Using Continuous Mode - fahre kontinuierlich nach links")
        _ContinuousSlideLeft()
    Else
        ; Standard-Modus: Bei angrenzendem Monitor -> zum nächsten Monitor
        _StandardSlideLeft()
    EndIf
    _LogDebug("=== BUTTON LEFT ENDE ===")
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonRight()
    _UpdateStatus("Slide nach rechts...")

    If $g_bClassicSliderMode Then
        ; Klassischer Modus: 1. Klick = Monitor wechseln, 2. Klick = Slide Out
        _ClassicSlideRight()
    ElseIf $g_bDirectSlideMode Then
        ; Direct Modus: Sofort Slide (ignoriert Nachbarn)
        _DirectSlideRight()
    ElseIf $g_bContinuousSlideMode Then
        ; Continuous Modus: Kontinuierliche Fahrt bis zum Rand
        _ContinuousSlideRight()
    Else
        ; Standard-Modus: Bei angrenzendem Monitor -> zum nächsten Monitor
        _StandardSlideRight()
    EndIf
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonUp()
    _UpdateStatus("Slide nach oben...")
    _LogDebug("=== BUTTON UP PRESSED ===")
    _LogDebug("Current Monitor: " & $g_iCurrentScreenNumber)
    _LogDebug("Window Status: " & ($g_bWindowIsOut ? "OUT" : "IN") & " at " & $g_sWindowIsAt)

    If $g_bClassicSliderMode Then
        ; Klassischer Modus: 1. Klick = Monitor wechseln, 2. Klick = Slide Out
        _ClassicSlideUp()
    ElseIf $g_bDirectSlideMode Then
        ; Direct Modus: Sofort Slide (ignoriert Nachbarn)
        _DirectSlideUp()
    ElseIf $g_bContinuousSlideMode Then
        ; Continuous Modus: Kontinuierliche Fahrt bis zum Rand
        _LogDebug("Using Continuous Mode - fahre kontinuierlich nach oben")
        _ContinuousSlideUp()
    Else
        ; Standard-Modus: Bei angrenzendem Monitor -> zum nächsten Monitor
        _StandardSlideUp()
    EndIf
    _LogDebug("=== BUTTON UP ENDE ===")
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonDown()
    _UpdateStatus("Slide nach unten...")
    _LogDebug("=== BUTTON DOWN PRESSED ===")
    _LogDebug("Current Monitor: " & $g_iCurrentScreenNumber)
    _LogDebug("Window Status: " & ($g_bWindowIsOut ? "OUT" : "IN") & " at " & $g_sWindowIsAt)

    If $g_bClassicSliderMode Then
        ; Klassischer Modus: 1. Klick = Monitor wechseln, 2. Klick = Slide Out
        _ClassicSlideDown()
    ElseIf $g_bDirectSlideMode Then
        ; Direct Modus: Sofort Slide (ignoriert Nachbarn)
        _DirectSlideDown()
    ElseIf $g_bContinuousSlideMode Then
        ; Continuous Modus: Kontinuierliche Fahrt bis zum Rand
        _LogDebug("Using Continuous Mode - fahre kontinuierlich nach unten")
        _ContinuousSlideDown()
    Else
        ; Standard-Modus: Bei angrenzendem Monitor -> zum nächsten Monitor
        _StandardSlideDown()
    EndIf
    _LogDebug("=== BUTTON DOWN ENDE ===")
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonCenter()
    _UpdateStatus("Zentriere Fenster...")
    _CenterOnMonitor($g_hMainGUI)
    _UpdateMonitorInfo()
EndFunc

; Aktualisiert die Monitor-Informationen in der GUI
Func _UpdateMonitorInfo()
    If Not IsDeclared("g_idLblMonitorInfo") Then Return

    ; Stelle sicher, dass wir einen gültigen Monitor-Index haben
    If $g_iCurrentScreenNumber < 1 Or $g_iCurrentScreenNumber > $g_iMonitorCount Then
        _LogWarning("Ungültiger Monitor-Index in _UpdateMonitorInfo: " & $g_iCurrentScreenNumber)
        $g_iCurrentScreenNumber = _GetPrimaryMonitor()
        If $g_iCurrentScreenNumber < 1 Then $g_iCurrentScreenNumber = 1
    EndIf

    ; Zeige visuelle Position und Windows Display-Nummer
    Local $iVisualIndex = _GetVisualMonitorIndex($g_iCurrentScreenNumber)
    Local $iActualDisplay = _GetActualDisplayNumber($g_iCurrentScreenNumber)

    Local $sDisplayText = "Monitor " & $iVisualIndex
    If $iActualDisplay <> $g_iCurrentScreenNumber Then
        $sDisplayText &= " (Display " & $iActualDisplay & ")"
    EndIf

    Local $sInfo = $sDisplayText
    $sInfo &= " | Position: " & $g_sWindowIsAt
    If $g_bWindowIsOut Then $sInfo &= " (Out)"

    GUICtrlSetData($g_idLblMonitorInfo, $sInfo)
EndFunc

; Aktualisiert den Status-Text
Func _UpdateStatus($sText, $iColor = 0x00FF00)
    If Not IsDeclared("g_idLblStatus") Then Return

    GUICtrlSetData($g_idLblStatus, $sText)
    GUICtrlSetColor($g_idLblStatus, $iColor)
EndFunc

; Aktualisiert den aktuellen Monitor nach GUI-Bewegung
Func _UpdateCurrentMonitor()
    Local $aPos = WinGetPos($g_hMainGUI)
    If Not IsArray($aPos) Then Return

    Local $iOldMonitor = $g_iCurrentScreenNumber
    Local $iNewMonitor = _GetMonitorAtPoint($aPos[0] + ($aPos[2] / 2), $aPos[1] + ($aPos[3] / 2))

    ; Nur aktualisieren wenn sich der Monitor wirklich geändert hat
    If $iNewMonitor <> $iOldMonitor And $iNewMonitor > 0 Then
        $g_iCurrentScreenNumber = $iNewMonitor
        _UpdateMonitorInfo()

        ; Zeige visuelle Position und Windows Display-Nummer in der Statusmeldung
        Local $iVisualIndex = _GetVisualMonitorIndex($g_iCurrentScreenNumber)
        Local $iActualDisplay = _GetActualDisplayNumber($g_iCurrentScreenNumber)

        Local $sMonitorText = "Monitor " & $iVisualIndex
        If $iActualDisplay <> $g_iCurrentScreenNumber Then
            $sMonitorText &= " (Display " & $iActualDisplay & ")"
        EndIf

        _UpdateStatus("Gewechselt zu " & $sMonitorText, 0x0080FF)
    EndIf
EndFunc

; Registriert globale Hotkeys
Func _RegisterHotkeys()
    Local $aHotkeys = _GetHotkeys()

    For $i = 0 To UBound($aHotkeys) - 1
        Local $sAction = $aHotkeys[$i][0]
        Local $sHotkey = $aHotkeys[$i][1]

        ; Registriere Hotkey
        Switch $sAction
            Case "SlideLeft"
                HotKeySet($sHotkey, "_HotkeySlideLeft")
            Case "SlideRight"
                HotKeySet($sHotkey, "_HotkeySlideRight")
            Case "SlideUp"
                HotKeySet($sHotkey, "_HotkeySlideUp")
            Case "SlideDown"
                HotKeySet($sHotkey, "_HotkeySlideDown")
            Case "ToggleSlide"
                HotKeySet($sHotkey, "_HotkeyToggleSlide")
            Case "CenterWindow"
                HotKeySet($sHotkey, "_HotkeyCenterWindow")
            Case "RecoverWindow"
                HotKeySet($sHotkey, "_HotkeyRecoverWindow")
        EndSwitch
    Next

    Return True
EndFunc

; Hotkey-Funktionen
Func _HotkeySlideLeft()
    _OnButtonLeft()
EndFunc

Func _HotkeySlideRight()
    _OnButtonRight()
EndFunc

Func _HotkeySlideUp()
    _OnButtonUp()
EndFunc

Func _HotkeySlideDown()
    _OnButtonDown()
EndFunc

Func _HotkeyToggleSlide()
    _ToggleSlide($g_hMainGUI, $g_sSwitchSide)
    _UpdateMonitorInfo()
EndFunc

Func _HotkeyCenterWindow()
    _OnButtonCenter()
EndFunc

Func _HotkeyRecoverWindow()
    _UpdateStatus("Stelle GUI wieder her...", 0xFFFF00)
    _RecoverLostWindow($g_hMainGUI)
    _UpdateMonitorInfo()
    _UpdateStatus("GUI wiederhergestellt", 0x00FF00)
EndFunc

; Schneller Monitor-Wechsel ohne Animation (für Classic Mode)
Func _FastMoveToMonitor($hWindow, $iTargetMonitor)
    If $iTargetMonitor < 1 Or $iTargetMonitor > $g_aMonitors[0][0] Then
        _LogWarning("Ungültiger Ziel-Monitor in _FastMoveToMonitor: " & $iTargetMonitor)
        Return False
    EndIf

    Local $aWindowPos = WinGetPos($hWindow)
    If Not IsArray($aWindowPos) Then Return False

    ; Zentriere auf Ziel-Monitor
    Local $iCenterX = $g_aMonitors[$iTargetMonitor][2] + ($g_aMonitors[$iTargetMonitor][0] - $aWindowPos[2]) / 2
    Local $iCenterY = $g_aMonitors[$iTargetMonitor][3] + ($g_aMonitors[$iTargetMonitor][1] - $aWindowPos[3]) / 2

    WinMove($hWindow, "", $iCenterX, $iCenterY)

    $g_iCurrentScreenNumber = $iTargetMonitor
    $g_bWindowIsOut = False
    $g_sWindowIsAt = $POS_CENTER

    _UpdateStatus("Schneller Wechsel zu Monitor " & $iTargetMonitor, 0x0080FF)
    Return True
EndFunc

; Zeigt die GUI an
Func _ShowGUI()
    ; Positioniere GUI basierend auf Konfiguration
    Local $aBehavior = _GetBehaviorSettings()
    Local $bCenterOnStart = False
    Local $bAnimateOnStart = False

    For $i = 0 To UBound($aBehavior) - 1
        Switch $aBehavior[$i][0]
            Case "CenterOnStart"
                $bCenterOnStart = $aBehavior[$i][1]
            Case "AnimateOnStart"
                $bAnimateOnStart = $aBehavior[$i][1]
        EndSwitch
    Next

    ; Initiale Positionierung
    If $bCenterOnStart Then
        _CenterOnMonitor($g_hMainGUI, $g_iLastMonitor)
    Else
        ; Positioniere basierend auf letzter Position
        Switch $g_sLastPosition
            Case $POS_LEFT, $POS_RIGHT, $POS_TOP, $POS_BOTTOM
                ; Positioniere am Rand
                _PositionAtEdge($g_hMainGUI, $g_iLastMonitor, $g_sLastPosition)
        EndSwitch
    EndIf

    ; Zeige GUI
    GUISetState(@SW_SHOW, $g_hMainGUI)

    ; Animiere wenn gewünscht
    If $bAnimateOnStart And $g_sLastPosition <> $POS_CENTER Then
        _SlideWindow($g_hMainGUI, $g_iLastMonitor, $g_sLastPosition, $ANIM_IN)
    EndIf

    _UpdateMonitorInfo()
    _UpdateStatus("Bereit", 0x00FF00)

    Return True
EndFunc

; Positioniert GUI am Rand eines Monitors
Func _PositionAtEdge($hWindow, $iMonitor, $sEdge)
    Local $aPos = WinGetPos($hWindow)
    If Not IsArray($aPos) Then Return False

    Local $iX, $iY

    Switch $sEdge
        Case $POS_LEFT
            $iX = $g_aMonitors[$iMonitor][2] - $aPos[2] + 50
            $iY = $g_aMonitors[$iMonitor][3] + ($g_aMonitors[$iMonitor][1] - $aPos[3]) / 2

        Case $POS_RIGHT
            $iX = $g_aMonitors[$iMonitor][2] + $g_aMonitors[$iMonitor][0] - 50
            $iY = $g_aMonitors[$iMonitor][3] + ($g_aMonitors[$iMonitor][1] - $aPos[3]) / 2

        Case $POS_TOP
            $iX = $g_aMonitors[$iMonitor][2] + ($g_aMonitors[$iMonitor][0] - $aPos[2]) / 2
            $iY = $g_aMonitors[$iMonitor][3] - $aPos[3] + 50

        Case $POS_BOTTOM
            $iX = $g_aMonitors[$iMonitor][2] + ($g_aMonitors[$iMonitor][0] - $aPos[2]) / 2
            $iY = $g_aMonitors[$iMonitor][3] + $g_aMonitors[$iMonitor][1] - 50
    EndSwitch

    WinMove($hWindow, "", $iX, $iY)
    Return True
EndFunc

; Versteckt die GUI
Func _HideGUI()
    If IsHWnd($g_hMainGUI) Then
        GUISetState(@SW_HIDE, $g_hMainGUI)
    EndIf
EndFunc

; Gibt GUI-Ressourcen frei
Func _DestroyGUI()
    If IsHWnd($g_hMainGUI) Then
        GUIDelete($g_hMainGUI)
        $g_hMainGUI = 0
    EndIf
EndFunc

; ==========================================
; Auto-Slide Funktionalität (Legacy)
; ==========================================

; Prüft ob die Maus über der GUI ist und aktiviert Auto-Slide
Func _CheckAutoSlideIn()
    ; Nur prüfen wenn GUI ausgefahren ist und nicht animiert
    If Not $g_bWindowIsOut Or $g_bIsAnimating Then Return

    ; Hole Mausposition
    Local $aMousePos = MouseGetPos()
    If Not IsArray($aMousePos) Then Return

    ; Hole GUI-Position
    Local $aGUIPos = WinGetPos($g_hMainGUI)
    If Not IsArray($aGUIPos) Then Return

    ; Prüfe ob Maus über der GUI ist (erhöhte Toleranz für 8-Pixel-Bereich)
    Local $iTolerance = 30  ; Erhöhte Toleranz für bessere Erkennung

    ; Prüfe speziell für jede Seite mit erweiterten Bereichen
    Local $bMouseOverGUI = False

    Switch $g_sWindowIsAt
        Case $POS_LEFT
            ; GUI ist links ausgefahren - prüfe rechten Rand
            $bMouseOverGUI = ($aMousePos[0] >= $aGUIPos[0] + $aGUIPos[2] - $iTolerance And _
                             $aMousePos[0] <= $aGUIPos[0] + $aGUIPos[2] + $iTolerance And _
                             $aMousePos[1] >= $aGUIPos[1] - $iTolerance And _
                             $aMousePos[1] <= $aGUIPos[1] + $aGUIPos[3] + $iTolerance)

        Case $POS_RIGHT
            ; GUI ist rechts ausgefahren - prüfe linken Rand
            $bMouseOverGUI = ($aMousePos[0] >= $aGUIPos[0] - $iTolerance And _
                             $aMousePos[0] <= $aGUIPos[0] + $iTolerance And _
                             $aMousePos[1] >= $aGUIPos[1] - $iTolerance And _
                             $aMousePos[1] <= $aGUIPos[1] + $aGUIPos[3] + $iTolerance)

        Case $POS_TOP
            ; GUI ist oben ausgefahren - prüfe unteren Rand
            $bMouseOverGUI = ($aMousePos[0] >= $aGUIPos[0] - $iTolerance And _
                             $aMousePos[0] <= $aGUIPos[0] + $aGUIPos[2] + $iTolerance And _
                             $aMousePos[1] >= $aGUIPos[1] + $aGUIPos[3] - $iTolerance And _
                             $aMousePos[1] <= $aGUIPos[1] + $aGUIPos[3] + $iTolerance)

        Case $POS_BOTTOM
            ; GUI ist unten ausgefahren - prüfe oberen Rand
            $bMouseOverGUI = ($aMousePos[0] >= $aGUIPos[0] - $iTolerance And _
                             $aMousePos[0] <= $aGUIPos[0] + $aGUIPos[2] + $iTolerance And _
                             $aMousePos[1] >= $aGUIPos[1] - $iTolerance And _
                             $aMousePos[1] <= $aGUIPos[1] + $iTolerance)

        Case Else
            ; Standard-Prüfung für den ganzen GUI-Bereich
            $bMouseOverGUI = ($aMousePos[0] >= $aGUIPos[0] - $iTolerance And _
                             $aMousePos[0] <= $aGUIPos[0] + $aGUIPos[2] + $iTolerance And _
                             $aMousePos[1] >= $aGUIPos[1] - $iTolerance And _
                             $aMousePos[1] <= $aGUIPos[1] + $aGUIPos[3] + $iTolerance)
    EndSwitch

    If $bMouseOverGUI Then
        _LogDebug("Maus über GUI erkannt - Slide In")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $g_sWindowIsAt, $ANIM_IN)
        _UpdateMonitorInfo()
    EndIf
EndFunc

; Deaktiviert Auto-Slide (Legacy)
Func _DisableAutoSlideIn()
    AdlibUnRegister("_CheckAutoSlideIn")
EndFunc

; Aktiviert Auto-Slide (Legacy)
Func _EnableAutoSlideIn()
    AdlibRegister("_CheckAutoSlideIn", 250)
EndFunc

; ==========================================
; Neue Slider-Modi Implementierung
; ==========================================

; Standard Slide Mode (Original-Verhalten)
Func _StandardSlideLeft()
    Local $iNextMonitor = _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_LEFT)
    If $iNextMonitor > 0 Then
        _MoveToNextMonitor($g_hMainGUI, $POS_LEFT)
    Else
        ; WICHTIG: Auch wenn GUI zentriert ist, prüfe ob die letzte manuelle Richtung LEFT war
        If $g_bWindowIsOut And $g_sWindowIsAt = $POS_LEFT Then
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_IN)
        ElseIf Not $g_bWindowIsOut And $g_sSwitchSide = $POS_LEFT Then
            ; GUI ist zentriert, aber letzte manuelle Richtung war LEFT -> Slide OUT
            _LogDebug("GUI zentriert, aber g_sSwitchSide='LEFT' -> Slide OUT")
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
        Else
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
        EndIf
    EndIf
EndFunc

Func _StandardSlideRight()
    Local $iNextMonitor = _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_RIGHT)
    If $iNextMonitor > 0 Then
        _MoveToNextMonitor($g_hMainGUI, $POS_RIGHT)
    Else
        ; WICHTIG: Auch wenn GUI zentriert ist, prüfe ob die letzte manuelle Richtung RIGHT war
        If $g_bWindowIsOut And $g_sWindowIsAt = $POS_RIGHT Then
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_IN)
        ElseIf Not $g_bWindowIsOut And $g_sSwitchSide = $POS_RIGHT Then
            ; GUI ist zentriert, aber letzte manuelle Richtung war RIGHT -> Slide OUT
            _LogDebug("GUI zentriert, aber g_sSwitchSide='RIGHT' -> Slide OUT")
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
        Else
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
        EndIf
    EndIf
EndFunc

; Classic Slide Mode (2-Klick System)
Func _ClassicSlideLeft()
    ; 1. Prüfe ob bereits links ausgefahren
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_LEFT Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_IN)
        Return
    EndIf

    ; 2. Prüfe ob linker Monitor existiert (physisch)
    Local $iLeftMonitor = _GetPhysicalLeftMonitor($g_iCurrentScreenNumber)

    If $iLeftMonitor > 0 Then
        ; Wechsle zum linken Monitor (ohne Animation)
        _FastMoveToMonitor($g_hMainGUI, $iLeftMonitor)
    Else
        ; Kein linker Monitor -> Slide Out
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
    EndIf
EndFunc

Func _ClassicSlideRight()
    ; 1. Prüfe ob bereits rechts ausgefahren
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_RIGHT Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_IN)
        Return
    EndIf

    ; 2. Prüfe ob rechter Monitor existiert (physisch)
    Local $iRightMonitor = _GetPhysicalRightMonitor($g_iCurrentScreenNumber)

    If $iRightMonitor > 0 Then
        ; Wechsle zum rechten Monitor (ohne Animation)
        _FastMoveToMonitor($g_hMainGUI, $iRightMonitor)
    Else
        ; Kein rechter Monitor -> Slide Out
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
    EndIf
EndFunc

; Direct Slide Mode (Ignoriert Nachbarn)
Func _DirectSlideLeft()
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_LEFT Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_IN)
    ElseIf Not $g_bWindowIsOut And $g_sSwitchSide = $POS_LEFT Then
        ; GUI ist zentriert nach Auto-Slide, aber letzte Richtung war LEFT
        _LogDebug("Direct Mode: GUI zentriert, aber g_sSwitchSide='LEFT' -> Slide OUT")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
    EndIf
EndFunc

Func _DirectSlideRight()
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_RIGHT Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_IN)
    ElseIf Not $g_bWindowIsOut And $g_sSwitchSide = $POS_RIGHT Then
        ; GUI ist zentriert nach Auto-Slide, aber letzte Richtung war RIGHT
        _LogDebug("Direct Mode: GUI zentriert, aber g_sSwitchSide='RIGHT' -> Slide OUT")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
    EndIf
EndFunc

; Continuous Slide Mode (Kontinuierliche Fahrt bis zum Rand)
Func _ContinuousSlideLeft()
    _LogDebug("_ContinuousSlideLeft: Start von Monitor " & $g_iCurrentScreenNumber)

    ; Wenn bereits ausgefahren → Slide IN
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_LEFT Then
        _LogDebug("GUI bereits links ausgefahren -> Slide IN")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_IN)
        Return
    EndIf

    ; Finde den linkesten Monitor (physisch gesehen)
    Local $iLeftMostMonitor = 1
    Local $iLeftMostX = $g_aMonitors[1][2]

    For $i = 2 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] < $iLeftMostX Then
            $iLeftMostX = $g_aMonitors[$i][2]
            $iLeftMostMonitor = $i
        EndIf
    Next

    _LogDebug("Linkester Monitor gefunden: " & $iLeftMostMonitor & " (X=" & $iLeftMostX & ")")

    ; Sind wir bereits am linkesten Monitor?
    If $g_iCurrentScreenNumber = $iLeftMostMonitor Then
        ; Ja → Slide OUT am linken Rand
        _LogDebug("Bereits am linkesten Monitor -> Slide OUT")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
    Else
        ; Nein → Fahre zum linkesten Monitor
        _LogDebug("Fahre zum linkesten Monitor: " & $iLeftMostMonitor)

        ; WICHTIG: Intelligente Navigation mit Versatz-Berücksichtigung
        _SmartMoveToMonitor($g_hMainGUI, $iLeftMostMonitor, $POS_LEFT)
    EndIf
EndFunc

Func _ContinuousSlideRight()
    _LogDebug("_ContinuousSlideRight: Start von Monitor " & $g_iCurrentScreenNumber)

    ; Wenn bereits ausgefahren → Slide IN
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_RIGHT Then
        _LogDebug("GUI bereits rechts ausgefahren -> Slide IN")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_IN)
        Return
    EndIf

    ; Finde den rechtesten Monitor
    Local $iRightMostMonitor = 1
    Local $iRightMostX = $g_aMonitors[1][2] + $g_aMonitors[1][0]

    For $i = 2 To $g_aMonitors[0][0]
        Local $iRightEdge = $g_aMonitors[$i][2] + $g_aMonitors[$i][0]
        If $iRightEdge > $iRightMostX Then
            $iRightMostX = $iRightEdge
            $iRightMostMonitor = $i
        EndIf
    Next

    _LogDebug("Rechtester Monitor gefunden: " & $iRightMostMonitor & " (RightEdge=" & $iRightMostX & ")")

    ; Sind wir bereits am rechtesten Monitor?
    If $g_iCurrentScreenNumber = $iRightMostMonitor Then
        ; Ja → Slide OUT am rechten Rand
        _LogDebug("Bereits am rechtesten Monitor -> Slide OUT")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
    Else
        ; Nein → Fahre zum rechtesten Monitor
        _LogDebug("Fahre zum rechtesten Monitor: " & $iRightMostMonitor)

        ; WICHTIG: Intelligente Navigation mit Versatz-Berücksichtigung
        _SmartMoveToMonitor($g_hMainGUI, $iRightMostMonitor, $POS_RIGHT)
    EndIf
EndFunc

; Intelligente Navigation zu einem Monitor mit perfektem Verfahrweg
Func _SmartMoveToMonitor($hWindow, $iTargetMonitor, $sDirection)
    Local $aStartPos = WinGetPos($hWindow)
    If Not IsArray($aStartPos) Then Return

    _LogDebug("SmartMove: Von Monitor " & $g_iCurrentScreenNumber & " zu Monitor " & $iTargetMonitor & " (Ziel-Richtung: " & $sDirection & ")")

    ; Schritt 1: Falls GUI ausgefahren ist, erst einfahren
    If $g_bWindowIsOut Then
        _LogDebug("GUI ist ausgefahren, fahre erst ein...")
        _SlideWindow($hWindow, $g_iCurrentScreenNumber, $g_sWindowIsAt, $ANIM_IN)
        ; Hole neue Position nach dem Einfahren
        $aStartPos = WinGetPos($hWindow)
        If Not IsArray($aStartPos) Then Return
    EndIf

    ; Schritt 2: Berechne optimalen Zielpunkt am Zielmonitor
    ; Der Zielpunkt sollte nahe der Slide-Out Position sein
    Local $iTargetX, $iTargetY
    Local $iMonitorX = $g_aMonitors[$iTargetMonitor][2]
    Local $iMonitorY = $g_aMonitors[$iTargetMonitor][3]
    Local $iMonitorW = $g_aMonitors[$iTargetMonitor][0]
    Local $iMonitorH = $g_aMonitors[$iTargetMonitor][1]
    Local $iGUIW = $aStartPos[2]
    Local $iGUIH = $aStartPos[3]

    ; Berechne relative Y-Position für vertikale Kontinuität
    Local $iCurrentRelativeY = ($aStartPos[1] + $iGUIH/2 - $g_aMonitors[$g_iCurrentScreenNumber][3]) / $g_aMonitors[$g_iCurrentScreenNumber][1]
    Local $iTargetRelativeY = $iMonitorY + ($iCurrentRelativeY * $iMonitorH) - $iGUIH/2

    ; Berechne relative X-Position für horizontale Kontinuität
    Local $iCurrentRelativeX = ($aStartPos[0] + $iGUIW/2 - $g_aMonitors[$g_iCurrentScreenNumber][2]) / $g_aMonitors[$g_iCurrentScreenNumber][0]
    Local $iTargetRelativeX = $iMonitorX + ($iCurrentRelativeX * $iMonitorW) - $iGUIW/2

    ; Bestimme Zielposition basierend auf Slide-Richtung
    Switch $sDirection
        Case $POS_LEFT
            ; Ziel: Nahe dem linken Rand für Slide-Out nach links
            $iTargetX = $iMonitorX + 50
            $iTargetY = $iTargetRelativeY

        Case $POS_RIGHT
            ; Ziel: Nahe dem rechten Rand für Slide-Out nach rechts
            $iTargetX = $iMonitorX + $iMonitorW - $iGUIW - 50
            $iTargetY = $iTargetRelativeY

        Case $POS_TOP
            ; Ziel: Nahe dem oberen Rand für Slide-Out nach oben
            $iTargetX = $iTargetRelativeX
            $iTargetY = $iMonitorY + 50

        Case $POS_BOTTOM
            ; Ziel: Nahe dem unteren Rand für Slide-Out nach unten
            $iTargetX = $iTargetRelativeX
            $iTargetY = $iMonitorY + $iMonitorH - $iGUIH - 50
    EndSwitch

    ; Stelle sicher, dass die GUI komplett im Zielmonitor bleibt
    $iTargetX = _Max($iMonitorX, _Min($iTargetX, $iMonitorX + $iMonitorW - $iGUIW))
    $iTargetY = _Max($iMonitorY, _Min($iTargetY, $iMonitorY + $iMonitorH - $iGUIH))

    _LogDebug("Berechne direkten Weg von (" & $aStartPos[0] & "," & $aStartPos[1] & ") nach (" & $iTargetX & "," & $iTargetY & ")")

    ; Schritt 3: Animiere auf direktem Weg zum Ziel
    Local $iSteps = 40  ; Mehr Schritte für flüssigere Animation
    Local $fProgress

    For $i = 1 To $iSteps
        ; Verwende Ease-In-Out für natürlichere Bewegung
        $fProgress = _EaseInOutQuad($i / $iSteps)

        Local $iCurrentX = $aStartPos[0] + (($iTargetX - $aStartPos[0]) * $fProgress)
        Local $iCurrentY = $aStartPos[1] + (($iTargetY - $aStartPos[1]) * $fProgress)

        WinMove($hWindow, "", $iCurrentX, $iCurrentY)

        ; Visualisierung aktualisieren
        _UpdateVisualization()

        Sleep(15) ; Schnellere, flüssigere Animation
    Next

    ; Update Status
    $g_iCurrentScreenNumber = $iTargetMonitor
    $g_bWindowIsOut = False
    $g_sWindowIsAt = $POS_CENTER
    _UpdateMonitorInfo()

    ; Schritt 4: Slide OUT in die gewünschte Richtung
    _LogDebug("Am Zielmonitor angekommen, fahre aus in Richtung: " & $sDirection)
    _SlideWindow($hWindow, $iTargetMonitor, $sDirection, $ANIM_OUT)
EndFunc

; Hilfsfunktion für Ease-In-Out Animation
Func _EaseInOutQuad($t)
    If $t < 0.5 Then
        Return 2 * $t * $t
    Else
        Return -1 + (4 - 2 * $t) * $t
    EndIf
EndFunc



; Animierte Fahrt zwischen Monitoren
Func _AnimatedMoveToMonitor($hWindow, $iTargetMonitor, $sDirection)
    Local $aStartPos = WinGetPos($hWindow)
    If Not IsArray($aStartPos) Then Return

    ; Ziel-Position berechnen
    Local $iTargetX = $g_aMonitors[$iTargetMonitor][2] + ($g_aMonitors[$iTargetMonitor][0] - $aStartPos[2]) / 2
    Local $iTargetY = $g_aMonitors[$iTargetMonitor][3] + ($g_aMonitors[$iTargetMonitor][1] - $aStartPos[3]) / 2

    ; Animation (20 Schritte)
    Local $iSteps = 20
    Local $iStepX = ($iTargetX - $aStartPos[0]) / $iSteps
    Local $iStepY = ($iTargetY - $aStartPos[1]) / $iSteps

    For $i = 1 To $iSteps
        Local $iCurrentX = $aStartPos[0] + ($iStepX * $i)
        Local $iCurrentY = $aStartPos[1] + ($iStepY * $i)
        WinMove($hWindow, "", $iCurrentX, $iCurrentY)

        ; Monitor-Update während Fahrt
        Local $iCurrentMonitor = _GetMonitorAtPoint($iCurrentX + $aStartPos[2]/2, $iCurrentY + $aStartPos[3]/2)
        If $iCurrentMonitor <> $g_iCurrentScreenNumber And $iCurrentMonitor > 0 Then
            $g_iCurrentScreenNumber = $iCurrentMonitor
        EndIf

        Sleep(30) ; Animationsgeschwindigkeit
    Next

    ; Finale Position und Status-Update
    $g_iCurrentScreenNumber = $iTargetMonitor
    $g_bWindowIsOut = False
    $g_sWindowIsAt = $POS_CENTER
EndFunc

; ==========================================
; Zusätzliche Standard-Modi für Vertical
; ==========================================

; Standard Slide Up
Func _StandardSlideUp()
    Local $iNextMonitor = _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_TOP)
    If $iNextMonitor > 0 Then
        _MoveToNextMonitor($g_hMainGUI, $POS_TOP)
    Else
        If $g_bWindowIsOut And $g_sWindowIsAt = $POS_TOP Then
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_IN)
        Else
            $g_sSwitchSide = $POS_TOP
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_OUT)
        EndIf
    EndIf
EndFunc

; Standard Slide Down
Func _StandardSlideDown()
    Local $iNextMonitor = _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_BOTTOM)
    If $iNextMonitor > 0 Then
        _MoveToNextMonitor($g_hMainGUI, $POS_BOTTOM)
    Else
        If $g_bWindowIsOut And $g_sWindowIsAt = $POS_BOTTOM Then
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_IN)
        Else
            $g_sSwitchSide = $POS_BOTTOM
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_OUT)
        EndIf
    EndIf
EndFunc

; Classic Slide Up
Func _ClassicSlideUp()
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_TOP Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_IN)
        Return
    EndIf

    ; Finde obersten Monitor
    Local $iTopMonitor = 1
    Local $iTopY = $g_aMonitors[1][3]

    For $i = 2 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][3] < $iTopY Then
            $iTopY = $g_aMonitors[$i][3]
            $iTopMonitor = $i
        EndIf
    Next

    If $iTopMonitor <> $g_iCurrentScreenNumber Then
        _FastMoveToMonitor($g_hMainGUI, $iTopMonitor)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_OUT)
    EndIf
EndFunc

; Classic Slide Down
Func _ClassicSlideDown()
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_BOTTOM Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_IN)
        Return
    EndIf

    ; Finde untersten Monitor
    Local $iBottomMonitor = 1
    Local $iBottomY = $g_aMonitors[1][3] + $g_aMonitors[1][1]

    For $i = 2 To $g_aMonitors[0][0]
        Local $iBottom = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
        If $iBottom > $iBottomY Then
            $iBottomY = $iBottom
            $iBottomMonitor = $i
        EndIf
    Next

    If $iBottomMonitor <> $g_iCurrentScreenNumber Then
        _FastMoveToMonitor($g_hMainGUI, $iBottomMonitor)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_OUT)
    EndIf
EndFunc

; Direct Slide Up
Func _DirectSlideUp()
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_TOP Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_IN)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_OUT)
    EndIf
EndFunc

; Direct Slide Down
Func _DirectSlideDown()
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_BOTTOM Then
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_IN)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_OUT)
    EndIf
EndFunc

; Continuous Slide Up
Func _ContinuousSlideUp()
    _LogDebug("_ContinuousSlideUp: Start von Monitor " & $g_iCurrentScreenNumber)

    ; Wenn bereits ausgefahren → Slide IN
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_TOP Then
        _LogDebug("GUI bereits oben ausgefahren -> Slide IN")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_IN)
        Return
    EndIf

    ; Finde den obersten Monitor
    Local $iTopMostMonitor = 1
    Local $iTopMostY = $g_aMonitors[1][3]

    For $i = 2 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][3] < $iTopMostY Then
            $iTopMostY = $g_aMonitors[$i][3]
            $iTopMostMonitor = $i
        EndIf
    Next

    _LogDebug("Oberster Monitor gefunden: " & $iTopMostMonitor & " (Y=" & $iTopMostY & ")")

    ; Sind wir bereits am obersten Monitor?
    If $g_iCurrentScreenNumber = $iTopMostMonitor Then
        ; Ja → Slide OUT am oberen Rand
        _LogDebug("Bereits am obersten Monitor -> Slide OUT")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_OUT)
    Else
        ; Nein → Fahre zum obersten Monitor
        _LogDebug("Fahre zum obersten Monitor: " & $iTopMostMonitor)

        ; WICHTIG: Intelligente Navigation mit Versatz-Berücksichtigung
        _SmartMoveToMonitor($g_hMainGUI, $iTopMostMonitor, $POS_TOP)
    EndIf
EndFunc

; Continuous Slide Down
Func _ContinuousSlideDown()
    _LogDebug("_ContinuousSlideDown: Start von Monitor " & $g_iCurrentScreenNumber)

    ; Wenn bereits ausgefahren → Slide IN
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_BOTTOM Then
        _LogDebug("GUI bereits unten ausgefahren -> Slide IN")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_IN)
        Return
    EndIf

    ; Finde den untersten Monitor
    Local $iBottomMostMonitor = 1
    Local $iBottomMostY = $g_aMonitors[1][3] + $g_aMonitors[1][1]

    For $i = 2 To $g_aMonitors[0][0]
        Local $iBottom = $g_aMonitors[$i][3] + $g_aMonitors[$i][1]
        If $iBottom > $iBottomMostY Then
            $iBottomMostY = $iBottom
            $iBottomMostMonitor = $i
        EndIf
    Next

    _LogDebug("Unterster Monitor gefunden: " & $iBottomMostMonitor & " (BottomEdge=" & $iBottomMostY & ")")

    ; Sind wir bereits am untersten Monitor?
    If $g_iCurrentScreenNumber = $iBottomMostMonitor Then
        ; Ja → Slide OUT am unteren Rand
        _LogDebug("Bereits am untersten Monitor -> Slide OUT")
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_OUT)
    Else
        ; Nein → Fahre zum untersten Monitor
        _LogDebug("Fahre zum untersten Monitor: " & $iBottomMostMonitor)

        ; WICHTIG: Intelligente Navigation mit Versatz-Berücksichtigung
        _SmartMoveToMonitor($g_hMainGUI, $iBottomMostMonitor, $POS_BOTTOM)
    EndIf
EndFunc
