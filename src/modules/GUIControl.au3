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
    ; Zeige korrekte Display-Nummer wenn verfügbar
    Local $sDisplayText = "Monitor: " & $g_iCurrentScreenNumber
    If UBound($g_aMonitorDetails) > $g_iCurrentScreenNumber And UBound($g_aMonitorDetails, 2) >= 6 Then
        Local $iDisplayNum = _ExtractDisplayNumber($g_aMonitorDetails[$g_iCurrentScreenNumber][0])
        If $iDisplayNum <> 999 Then
            $sDisplayText = "Display: " & $iDisplayNum
        EndIf
    EndIf
    GUICtrlSetData($lblMonitorInfo, $sDisplayText & " | Position: " & $g_sWindowIsAt)

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
    If _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_LEFT) Then
        _MoveToNextMonitor($g_hMainGUI, $POS_LEFT)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
    EndIf
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonRight()
    _UpdateStatus("Slide nach rechts...")
    If _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_RIGHT) Then
        _MoveToNextMonitor($g_hMainGUI, $POS_RIGHT)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_RIGHT, $ANIM_OUT)
    EndIf
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonUp()
    _UpdateStatus("Slide nach oben...")
    If _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_TOP) Then
        _MoveToNextMonitor($g_hMainGUI, $POS_TOP)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_OUT)
    EndIf
    _UpdateMonitorInfo()
EndFunc

Func _OnButtonDown()
    _UpdateStatus("Slide nach unten...")
    If _HasAdjacentMonitor($g_iCurrentScreenNumber, $POS_BOTTOM) Then
        _MoveToNextMonitor($g_hMainGUI, $POS_BOTTOM)
    Else
        _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_OUT)
    EndIf
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

    ; Zeige korrekte Display-Nummer wenn verfügbar
    Local $sDisplayText = "Monitor: " & $g_iCurrentScreenNumber
    If UBound($g_aMonitorDetails) > $g_iCurrentScreenNumber And UBound($g_aMonitorDetails, 2) >= 6 Then
        Local $iDisplayNum = _ExtractDisplayNumber($g_aMonitorDetails[$g_iCurrentScreenNumber][0])
        If $iDisplayNum <> 999 Then
            $sDisplayText = "Display: " & $iDisplayNum
        EndIf
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
    $g_iCurrentScreenNumber = _GetMonitorAtPoint($aPos[0] + ($aPos[2] / 2), $aPos[1] + ($aPos[3] / 2))

    If $iOldMonitor <> $g_iCurrentScreenNumber Then
        _UpdateMonitorInfo()
        _UpdateStatus("Gewechselt zu Monitor " & $g_iCurrentScreenNumber, 0x0080FF)
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
; Auto-Slide-In Funktionalität
; ==========================================

; Prüft ob die Maus über der GUI ist und aktiviert Auto-Slide-In
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

; Deaktiviert Auto-Slide-In
Func _DisableAutoSlideIn()
    AdlibUnRegister("_CheckAutoSlideIn")
EndFunc

; Aktiviert Auto-Slide-In
Func _EnableAutoSlideIn()
    AdlibRegister("_CheckAutoSlideIn", 250)
EndFunc
