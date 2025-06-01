#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.16.1
 Author:         Test Auto-Slide Feature

 Script Function:
    Testet das Auto-Slide Feature nach der Fehlerbehebung
#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "../src/includes/GlobalVars.au3"
#include "../src/includes/Constants.au3"
#include "../src/modules/MonitorDetection.au3"
#include "../src/modules/SliderLogic.au3"
#include "../src/modules/GUIControl.au3"
#include "../src/modules/AutoSlideMode.au3"
#include "../src/modules/Logging.au3"

; Initialisiere Logging
_InitLogging()
_LogInfo("=== Auto-Slide Test gestartet ===")

; Erkenne Monitore
Local $aMonitors = _GetMonitors()
If @error Or $aMonitors[0][0] = 0 Then
    MsgBox(16, "Fehler", "Keine Monitore erkannt!")
    Exit
EndIf

; Erstelle Test-GUI
$g_hMainGUI = GUICreate("Auto-Slide Test", 300, 200, -1, -1, BitOR($WS_POPUP, $WS_BORDER))
GUISetBkColor(0x2B2B2B)

Local $lblInfo = GUICtrlCreateLabel("Auto-Slide Test", 10, 10, 280, 30, 0x01)
GUICtrlSetFont($lblInfo, 14, 800)
GUICtrlSetColor($lblInfo, 0xFFFFFF)

Local $lblStatus = GUICtrlCreateLabel("Status: Bereit", 10, 50, 280, 60)
GUICtrlSetColor($lblStatus, 0x00FF00)

Local $btnSlideOut = GUICtrlCreateButton("Slide OUT (Links)", 10, 120, 130, 30)
Local $btnActivateAuto = GUICtrlCreateButton("Auto-Slide AN", 160, 120, 130, 30)
Local $btnDebug = GUICtrlCreateButton("Debug Status", 10, 160, 280, 30)

GUISetState(@SW_SHOW)

; Initialisiere auf Monitor 1
$g_iCurrentScreenNumber = 1
_CenterOnMonitor($g_hMainGUI, 1)

; Aktiviere Auto-Slide mit Test-Einstellungen
_SetAutoSlideMode(True, 800, 200)  ; 800ms delay out, 200ms delay in
_LogInfo("Auto-Slide aktiviert mit DelayOut=800ms, DelayIn=200ms")

Local $iUpdateTimer = TimerInit()
Local $sLastStatus = ""

While 1
    Local $msg = GUIGetMsg()
    
    Switch $msg
        Case $GUI_EVENT_CLOSE
            ExitLoop
            
        Case $btnSlideOut
            ; Manueller Slide OUT nach links
            $g_sSwitchSide = $POS_LEFT
            _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $POS_LEFT, $ANIM_OUT)
            GUICtrlSetData($lblStatus, "Status: Manuell nach LINKS ausgefahren" & @CRLF & _
                          "Bewege Maus über den sichtbaren Rand zum Einfahren" & @CRLF & _
                          "Nach Einfahren sollte GUI nach 1.5s wieder ausfahren")
            
        Case $btnActivateAuto
            Local $bCurrentState = $g_bAutoSlideActive
            _SetAutoSlideMode(Not $bCurrentState, 800, 200)
            GUICtrlSetData($btnActivateAuto, $g_bAutoSlideActive ? "Auto-Slide AUS" : "Auto-Slide AN")
            
        Case $btnDebug
            Local $sDebug = _DebugAutoSlideState($g_hMainGUI)
            MsgBox(64, "Auto-Slide Debug", $sDebug)
    EndSwitch
    
    ; Auto-Slide prüfen
    _CheckAutoSlide($g_hMainGUI)
    
    ; Update Status alle 500ms
    If TimerDiff($iUpdateTimer) > 500 Then
        Local $aMousePos = MouseGetPos()
        Local $aWindowPos = WinGetPos($g_hMainGUI)
        Local $bMouseOverGUI = False
        Local $bMouseOverEdge = False
        
        If IsArray($aMousePos) And IsArray($aWindowPos) Then
            $bMouseOverGUI = _IsMouseOverWindow($aMousePos[0], $aMousePos[1], $aWindowPos)
            $bMouseOverEdge = _IsMouseOverVisibleEdge($aMousePos[0], $aMousePos[1], $aWindowPos)
        EndIf
        
        Local $sStatus = "Auto-Slide: " & ($g_bAutoSlideActive ? "AKTIV" : "INAKTIV") & @CRLF
        $sStatus &= "GUI Status: " & ($g_bWindowIsOut ? "AUSGEFAHREN (" & $g_sWindowIsAt & ")" : "EINGEFAHREN") & @CRLF
        $sStatus &= "Maus über GUI: " & ($bMouseOverGUI ? "JA" : "NEIN") & @CRLF
        $sStatus &= "Maus über Rand: " & ($bMouseOverEdge ? "JA" : "NEIN") & @CRLF
        
        If $g_bAutoSlidePending Then
            $sStatus &= "Timer läuft: " & $g_sAutoSlidePendingAction & " in " & _
                       Int(($g_sAutoSlidePendingAction = "OUT" ? $g_iAutoSlideDelayOut : $g_iAutoSlideDelayIn) - TimerDiff($g_iAutoSlideTimer)) & "ms"
        EndIf
        
        If $sStatus <> $sLastStatus Then
            GUICtrlSetData($lblStatus, $sStatus)
            $sLastStatus = $sStatus
        EndIf
        
        $iUpdateTimer = TimerInit()
    EndIf
    
    Sleep(50)
WEnd

; Aufräumen
_SetAutoSlideMode(False)
GUIDelete($g_hMainGUI)
_LogInfo("=== Auto-Slide Test beendet ===")
_CloseLogging()