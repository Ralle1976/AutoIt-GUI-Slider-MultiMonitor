#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.16.1
 UDF Name: GUI-Slider-MultiMonitor
 Description: Multi-Monitor GUI Slider System UDF
 Author: Ralle1976
 Version: 2.0.0
 License: MIT
 
 Functions:
   _SliderSystem_Init($hGUI)
   _SliderSystem_SetMode($sMode)
   _SliderSystem_EnableAutoSlideIn($bEnable, $iDelay)
   _SliderSystem_EnableVisualizer($bEnable)
   _SliderSystem_SlideLeft(), _SlideRight(), _SlideUp(), _SlideDown()
   _SliderSystem_ShowConfig()
   _SliderSystem_GetCurrentMonitor(), _IsSlideOut(), _GetSlidePosition()
   _SliderSystem_Cleanup()
#ce ----------------------------------------------------------------------------

#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; Echte Includes aus dem funktionierenden System
#include "src\includes\GlobalVars.au3"
#include "src\includes\Constants.au3"
#include "src\modules\MonitorDetection.au3"
#include "src\modules\SliderLogic.au3"
#include "src\modules\Logging.au3"
#include "src\modules\Visualization.au3"
#include "src\modules\GUIControl.au3"

; ==========================================
; UDF Constants
; ==========================================
Global Const $SLIDER_MODE_STANDARD = "Standard"
Global Const $SLIDER_MODE_CLASSIC = "Classic"
Global Const $SLIDER_MODE_DIRECT = "Direct"
Global Const $SLIDER_MODE_CONTINUOUS = "Continuous"

; ==========================================
; UDF Globale Variablen
; ==========================================
Global $__SliderSystem_hTargetGUI = 0
Global $__SliderSystem_sMode = "Standard"
Global $__SliderSystem_bInitialized = False
Global $__SliderSystem_bAutoSlideIn = False
Global $__SliderSystem_bVisualizerEnabled = False

; ==========================================
; Öffentliche UDF-Funktionen
; ==========================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_Init
; Description ...: Initialisiert das Slider-System für ein GUI
; Syntax ........: _SliderSystem_Init($hGUI)
; Parameters ....: $hGUI - Handle des GUI-Fensters
; Return values .: Success - True, Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_Init($hGUI)
    If Not IsHWnd($hGUI) Then Return SetError(1, 0, False)
    
    ; Bereits initialisiert?
    If $__SliderSystem_bInitialized Then
        _SliderSystem_Cleanup()
    EndIf
    
    ; Logging initialisieren
    If Not _InitLogging() Then Return SetError(2, 0, False)
    
    ; Monitor-System initialisieren
    Local $aMonitors = _GetMonitors()
    If @error Or $aMonitors[0][0] = 0 Then Return SetError(3, 0, False)
    
    ; GUI-Handle speichern
    $__SliderSystem_hTargetGUI = $hGUI
    $g_hMainGUI = $hGUI
    
    ; Aktuelle Position ermitteln
    Local $aPos = WinGetPos($hGUI)
    If IsArray($aPos) Then
        $g_iCurrentScreenNumber = _GetMonitorAtPoint($aPos[0] + $aPos[2]/2, $aPos[1] + $aPos[3]/2)
    Else
        $g_iCurrentScreenNumber = 1
    EndIf
    
    ; Status initialisieren
    $g_bWindowIsOut = False
    $g_sWindowIsAt = $POS_CENTER
    $g_bIsAnimating = False
    
    ; Modus-Flags zurücksetzen
    $g_bClassicSliderMode = False
    $g_bDirectSlideMode = False
    $g_bContinuousSlideMode = False
    
    $__SliderSystem_bInitialized = True
    _LogInfo("SliderSystem initialisiert für GUI: " & $hGUI)
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_SetMode
; Description ...: Setzt den Slider-Modus
; Syntax ........: _SliderSystem_SetMode($sMode)
; Parameters ....: $sMode - "Standard", "Classic", "Direct", "Continuous"
; Return values .: Success - True, Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_SetMode($sMode)
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    ; Reset alle Modi
    $g_bClassicSliderMode = False
    $g_bDirectSlideMode = False
    $g_bContinuousSlideMode = False
    
    Switch $sMode
        Case "Classic"
            $g_bClassicSliderMode = True
        Case "Direct"
            $g_bDirectSlideMode = True
        Case "Continuous"
            $g_bContinuousSlideMode = True
        Case "Standard"
            ; Alle False = Standard
        Case Else
            Return SetError(2, 0, False) ; Ungültiger Modus
    EndSwitch
    
    $__SliderSystem_sMode = $sMode
    _LogInfo("Slider-Modus gesetzt: " & $sMode)
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_EnableAutoSlideIn
; Description ...: Aktiviert/Deaktiviert Auto-Slide-In
; Syntax ........: _SliderSystem_EnableAutoSlideIn([$bEnable = True[, $iDelay = 250]])
; Parameters ....: $bEnable - True/False, $iDelay - Verzögerung in ms (optional)
; Return values .: Success - True, Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_EnableAutoSlideIn($bEnable = True, $iDelay = 250)
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $__SliderSystem_bAutoSlideIn Then
        AdlibUnRegister("_CheckAutoSlideIn")
        $__SliderSystem_bAutoSlideIn = False
    EndIf
    
    If $bEnable Then
        AdlibRegister("_CheckAutoSlideIn", $iDelay)
        $__SliderSystem_bAutoSlideIn = True
        _LogInfo("Auto-Slide-In aktiviert (" & $iDelay & "ms)")
    Else
        _LogInfo("Auto-Slide-In deaktiviert")
    EndIf
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_EnableVisualizer
; Description ...: Aktiviert/Deaktiviert den Visualizer
; Syntax ........: _SliderSystem_EnableVisualizer([$bEnable = True])
; Parameters ....: $bEnable - True/False
; Return values .: Success - True, Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_EnableVisualizer($bEnable = True)
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $bEnable Then
        If _InitVisualization() Then
            $__SliderSystem_bVisualizerEnabled = True
            _LogInfo("Visualizer aktiviert")
            Return True
        Else
            Return SetError(2, 0, False)
        EndIf
    Else
        _CloseVisualization()
        $__SliderSystem_bVisualizerEnabled = False
        _LogInfo("Visualizer deaktiviert")
        Return True
    EndIf
EndFunc

; Slide-Funktionen
Func _SliderSystem_SlideLeft()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    Switch $__SliderSystem_sMode
        Case "Classic"
            _ClassicSlideLeft()
        Case "Direct"
            _DirectSlideLeft()
        Case "Continuous"
            _ContinuousSlideLeft()
        Case Else ; Standard
            _StandardSlideLeft()
    EndSwitch
    
    _SliderSystem_UpdateVisualizer()
    Return True
EndFunc

Func _SliderSystem_SlideRight()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    Switch $__SliderSystem_sMode
        Case "Classic"
            _ClassicSlideRight()
        Case "Direct"
            _DirectSlideRight()
        Case "Continuous"
            _ContinuousSlideRight()
        Case Else ; Standard
            _StandardSlideRight()
    EndSwitch
    
    _SliderSystem_UpdateVisualizer()
    Return True
EndFunc

Func _SliderSystem_SlideUp()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_TOP Then
        _SlideWindow($__SliderSystem_hTargetGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_IN)
    Else
        _SlideWindow($__SliderSystem_hTargetGUI, $g_iCurrentScreenNumber, $POS_TOP, $ANIM_OUT)
    EndIf
    
    _SliderSystem_UpdateVisualizer()
    Return True
EndFunc

Func _SliderSystem_SlideDown()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $g_bWindowIsOut And $g_sWindowIsAt = $POS_BOTTOM Then
        _SlideWindow($__SliderSystem_hTargetGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_IN)
    Else
        _SlideWindow($__SliderSystem_hTargetGUI, $g_iCurrentScreenNumber, $POS_BOTTOM, $ANIM_OUT)
    EndIf
    
    _SliderSystem_UpdateVisualizer()
    Return True
EndFunc

; Info-Funktionen
Func _SliderSystem_GetCurrentMonitor()
    Return $g_iCurrentScreenNumber
EndFunc

Func _SliderSystem_IsSlideOut()
    Return $g_bWindowIsOut
EndFunc

Func _SliderSystem_GetSlidePosition()
    Return $g_sWindowIsAt
EndFunc

Func _SliderSystem_GetMode()
    Return $__SliderSystem_sMode
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_ShowConfig
; Description ...: Zeigt eine Konfigurations-GUI
; Syntax ........: _SliderSystem_ShowConfig()
; Return values .: Success - True
; ===============================================================================================================================
Func _SliderSystem_ShowConfig()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    Local $hConfigGUI = GUICreate("Slider System Konfiguration", 450, 350, -1, -1, -1, $WS_EX_TOOLWINDOW)
    GUISetBkColor(0xF0F0F0, $hConfigGUI)
    
    ; Titel
    Local $lblTitle = GUICtrlCreateLabel("Slider System Konfiguration", 10, 10, 430, 25, 1)
    GUICtrlSetFont($lblTitle, 12, 800)
    
    ; Aktuelle Informationen
    GUICtrlCreateGroup("Aktuelle Informationen", 10, 50, 430, 100)
    GUICtrlCreateLabel("Monitor: " & _SliderSystem_GetCurrentMonitor(), 20, 75, 200, 20)
    GUICtrlCreateLabel("Status: " & (_SliderSystem_IsSlideOut() ? "OUT" : "IN"), 20, 95, 200, 20)
    GUICtrlCreateLabel("Position: " & _SliderSystem_GetSlidePosition(), 20, 115, 200, 20)
    GUICtrlCreateLabel("Modus: " & _SliderSystem_GetMode(), 20, 135, 200, 20)
    
    ; Monitor-Informationen
    Local $aMonitors = _GetMonitors()
    GUICtrlCreateGroup("Monitor-Setup", 10, 160, 430, 100)
    Local $sMonitorInfo = "Erkannte Monitore: " & $aMonitors[0][0] & @CRLF
    For $i = 1 To $aMonitors[0][0]
        $sMonitorInfo &= "Monitor " & $i & ": " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1] & " @ " & $aMonitors[$i][2] & "," & $aMonitors[$i][3] & @CRLF
    Next
    GUICtrlCreateEdit($sMonitorInfo, 20, 185, 410, 70, BitOR(0x0004, 0x0800))  ; ES_MULTILINE | ES_READONLY
    
    ; Funktionen
    GUICtrlCreateGroup("Funktionen", 10, 270, 430, 50)
    Local $btnVisualizer = GUICtrlCreateButton("Visualizer Ein/Aus", 20, 290, 120, 25)
    Local $btnClose = GUICtrlCreateButton("Schließen", 350, 290, 80, 25)
    
    GUISetState(@SW_SHOW, $hConfigGUI)
    
    ; Event-Loop für Config-GUI (funktioniert auch im OnEvent Mode)
    Local $iOldMode = Opt("GUIOnEventMode", 0)  ; Temporär auf Message Mode
    
    While 1
        Local $msg = GUIGetMsg()
        
        Switch $msg
            Case $GUI_EVENT_CLOSE, $btnClose
                ExitLoop
                
            Case $btnVisualizer
                $__SliderSystem_bVisualizerEnabled = Not $__SliderSystem_bVisualizerEnabled
                _SliderSystem_EnableVisualizer($__SliderSystem_bVisualizerEnabled)
        EndSwitch
        
        Sleep(20)
    WEnd
    
    Opt("GUIOnEventMode", $iOldMode)  ; Zurück zum vorherigen Mode
    
    GUIDelete($hConfigGUI)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_Cleanup
; Description ...: Bereinigt das Slider-System
; Syntax ........: _SliderSystem_Cleanup()
; ===============================================================================================================================
Func _SliderSystem_Cleanup()
    If $__SliderSystem_bAutoSlideIn Then
        AdlibUnRegister("_CheckAutoSlideIn")
        $__SliderSystem_bAutoSlideIn = False
    EndIf
    
    If $__SliderSystem_bVisualizerEnabled Then
        _CloseVisualization()
        $__SliderSystem_bVisualizerEnabled = False
    EndIf
    
    _CloseLogging()
    
    $__SliderSystem_bInitialized = False
    _LogInfo("SliderSystem cleanup abgeschlossen")
EndFunc

; ==========================================
; Interne Hilfsfunktionen
; ==========================================

; Visualizer aktualisieren
Func _SliderSystem_UpdateVisualizer()
    If $__SliderSystem_bVisualizerEnabled Then
        _UpdateVisualization()
    EndIf
EndFunc