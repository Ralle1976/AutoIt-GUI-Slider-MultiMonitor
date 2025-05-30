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

; ==========================================
; UDF Constants
; ==========================================
Global Const $SLIDER_MODE_STANDARD = "Standard"
Global Const $SLIDER_MODE_CLASSIC = "Classic"
Global Const $SLIDER_MODE_DIRECT = "Direct"
Global Const $SLIDER_MODE_CONTINUOUS = "Continuous"

Global Const $SLIDER_POS_TOP = "Top"
Global Const $SLIDER_POS_BOTTOM = "Bottom"
Global Const $SLIDER_POS_LEFT = "Left"
Global Const $SLIDER_POS_RIGHT = "Right"
Global Const $SLIDER_POS_CENTER = "Center"

Global Const $SLIDER_ANIM_IN = "In"
Global Const $SLIDER_ANIM_OUT = "Out"

; ==========================================
; UDF Internal Variables
; ==========================================
Global $__SliderSystem_hTargetGUI = 0
Global $__SliderSystem_sMode = $SLIDER_MODE_STANDARD
Global $__SliderSystem_bInitialized = False
Global $__SliderSystem_bAutoSlideIn = False
Global $__SliderSystem_iAutoSlideDelay = 250
Global $__SliderSystem_bVisualizerEnabled = False
Global $__SliderSystem_hConfigGUI = 0

; Monitor-System Variablen
Global $__SliderSystem_aMonitors[1][4]
Global $__SliderSystem_iMonitorCount = 0
Global $__SliderSystem_iCurrentMonitor = 1
Global $__SliderSystem_bIsSlideOut = False
Global $__SliderSystem_sSlidePosition = $SLIDER_POS_CENTER
Global $__SliderSystem_bIsAnimating = False

; Physisches Mapping
Global $__SliderSystem_aPhysicalMapping[1][3]
Global $__SliderSystem_iPhysicalMappingCount = 0

; ==========================================
; Public UDF Functions
; ==========================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_Init
; Description ...: Initialisiert das Slider-System für ein GUI
; Syntax ........: _SliderSystem_Init($hGUI)
; Parameters ....: $hGUI - Handle des GUI-Fensters
; Return values .: Success - True
;                  Failure - False und setzt @error
; Author ........: Ralle1976
; ===============================================================================================================================
Func _SliderSystem_Init($hGUI)
    If Not IsHWnd($hGUI) Then Return SetError(1, 0, False)
    
    ; Bereits initialisiert?
    If $__SliderSystem_bInitialized Then
        _SliderSystem_Cleanup()
    EndIf
    
    ; Monitor-System initialisieren
    If Not __SliderSystem_InitMonitors() Then Return SetError(2, 0, False)
    
    ; GUI-Handle speichern
    $__SliderSystem_hTargetGUI = $hGUI
    
    ; Aktuelle Position ermitteln
    Local $aPos = WinGetPos($hGUI)
    If IsArray($aPos) Then
        $__SliderSystem_iCurrentMonitor = __SliderSystem_GetMonitorAtPoint($aPos[0] + $aPos[2]/2, $aPos[1] + $aPos[3]/2)
    Else
        $__SliderSystem_iCurrentMonitor = 1
    EndIf
    
    ; Status initialisieren
    $__SliderSystem_bIsSlideOut = False
    $__SliderSystem_sSlidePosition = $SLIDER_POS_CENTER
    $__SliderSystem_bIsAnimating = False
    
    $__SliderSystem_bInitialized = True
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_SetMode
; Description ...: Setzt den Slider-Modus
; Syntax ........: _SliderSystem_SetMode($sMode)
; Parameters ....: $sMode - "Standard", "Classic", "Direct", "Continuous"
; Return values .: Success - True
;                  Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_SetMode($sMode)
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    Switch $sMode
        Case $SLIDER_MODE_STANDARD, $SLIDER_MODE_CLASSIC, $SLIDER_MODE_DIRECT, $SLIDER_MODE_CONTINUOUS
            $__SliderSystem_sMode = $sMode
            Return True
        Case Else
            Return SetError(2, 0, False) ; Ungültiger Modus
    EndSwitch
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_EnableAutoSlideIn
; Description ...: Aktiviert/Deaktiviert Auto-Slide-In
; Syntax ........: _SliderSystem_EnableAutoSlideIn([$bEnable = True[, $iDelay = 250]])
; Parameters ....: $bEnable - True/False
;                  $iDelay - Verzögerung in ms (optional)
; Return values .: Success - True
;                  Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_EnableAutoSlideIn($bEnable = True, $iDelay = 250)
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $__SliderSystem_bAutoSlideIn Then
        AdlibUnRegister("__SliderSystem_AutoSlideIn")
        $__SliderSystem_bAutoSlideIn = False
    EndIf
    
    If $bEnable Then
        $__SliderSystem_iAutoSlideDelay = $iDelay
        AdlibRegister("__SliderSystem_AutoSlideIn", $iDelay)
        $__SliderSystem_bAutoSlideIn = True
    EndIf
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_SlideLeft
; Description ...: Führt Slide nach links aus (je nach Modus)
; Syntax ........: _SliderSystem_SlideLeft()
; Return values .: Success - True
;                  Failure - False und setzt @error
; ===============================================================================================================================
Func _SliderSystem_SlideLeft()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    Switch $__SliderSystem_sMode
        Case $SLIDER_MODE_CLASSIC
            __SliderSystem_ClassicSlideLeft()
        Case $SLIDER_MODE_DIRECT
            __SliderSystem_DirectSlideLeft()
        Case $SLIDER_MODE_CONTINUOUS
            __SliderSystem_ContinuousSlideLeft()
        Case Else ; Standard
            __SliderSystem_StandardSlideLeft()
    EndSwitch
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_SlideRight
; Description ...: Führt Slide nach rechts aus (je nach Modus)
; ===============================================================================================================================
Func _SliderSystem_SlideRight()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    Switch $__SliderSystem_sMode
        Case $SLIDER_MODE_CLASSIC
            __SliderSystem_ClassicSlideRight()
        Case $SLIDER_MODE_DIRECT
            __SliderSystem_DirectSlideRight()
        Case $SLIDER_MODE_CONTINUOUS
            __SliderSystem_ContinuousSlideRight()
        Case Else ; Standard
            __SliderSystem_StandardSlideRight()
    EndSwitch
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_SlideUp
; Description ...: Führt Slide nach oben aus
; ===============================================================================================================================
Func _SliderSystem_SlideUp()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_TOP Then
        __SliderSystem_SlideWindow($SLIDER_POS_TOP, $SLIDER_ANIM_IN)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_TOP, $SLIDER_ANIM_OUT)
    EndIf
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_SlideDown
; Description ...: Führt Slide nach unten aus
; ===============================================================================================================================
Func _SliderSystem_SlideDown()
    If Not $__SliderSystem_bInitialized Then Return SetError(1, 0, False)
    
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_BOTTOM Then
        __SliderSystem_SlideWindow($SLIDER_POS_BOTTOM, $SLIDER_ANIM_IN)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_BOTTOM, $SLIDER_ANIM_OUT)
    EndIf
    
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_GetCurrentMonitor
; Description ...: Gibt die aktuelle Monitor-Nummer zurück
; Return values .: Monitor-Nummer (1-basiert)
; ===============================================================================================================================
Func _SliderSystem_GetCurrentMonitor()
    Return $__SliderSystem_iCurrentMonitor
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_IsSlideOut
; Description ...: Prüft ob GUI ausgefahren ist
; Return values .: True wenn ausgefahren, False wenn nicht
; ===============================================================================================================================
Func _SliderSystem_IsSlideOut()
    Return $__SliderSystem_bIsSlideOut
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_GetSlidePosition
; Description ...: Gibt die aktuelle Slide-Position zurück
; Return values .: "Top", "Bottom", "Left", "Right", "Center"
; ===============================================================================================================================
Func _SliderSystem_GetSlidePosition()
    Return $__SliderSystem_sSlidePosition
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_GetMode
; Description ...: Gibt den aktuellen Modus zurück
; Return values .: "Standard", "Classic", "Direct", "Continuous"
; ===============================================================================================================================
Func _SliderSystem_GetMode()
    Return $__SliderSystem_sMode
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SliderSystem_Cleanup
; Description ...: Bereinigt das Slider-System
; ===============================================================================================================================
Func _SliderSystem_Cleanup()
    If $__SliderSystem_bAutoSlideIn Then
        AdlibUnRegister("__SliderSystem_AutoSlideIn")
        $__SliderSystem_bAutoSlideIn = False
    EndIf
    
    If $__SliderSystem_hConfigGUI <> 0 Then
        GUIDelete($__SliderSystem_hConfigGUI)
        $__SliderSystem_hConfigGUI = 0
    EndIf
    
    $__SliderSystem_bInitialized = False
EndFunc

; ==========================================
; Internal Helper Functions
; ==========================================

; Monitor-System initialisieren
Func __SliderSystem_InitMonitors()
    ; Vereinfachte Monitor-Erkennung für UDF
    Local $iMonitorCount = @DesktopWidth / 1920 ; Grobe Schätzung
    If $iMonitorCount < 1 Then $iMonitorCount = 1
    If $iMonitorCount > 8 Then $iMonitorCount = 8
    
    ReDim $__SliderSystem_aMonitors[$iMonitorCount + 1][4]
    $__SliderSystem_aMonitors[0][0] = $iMonitorCount
    
    ; Standard-Monitor-Layout (vereinfacht)
    For $i = 1 To $iMonitorCount
        $__SliderSystem_aMonitors[$i][0] = 1920  ; Breite
        $__SliderSystem_aMonitors[$i][1] = 1080  ; Höhe
        $__SliderSystem_aMonitors[$i][2] = ($i - 1) * 1920  ; X-Position
        $__SliderSystem_aMonitors[$i][3] = 0     ; Y-Position
    Next
    
    $__SliderSystem_iMonitorCount = $iMonitorCount
    
    ; Physisches Mapping erstellen
    __SliderSystem_CreatePhysicalMapping()
    
    Return True
EndFunc

; Physisches Mapping erstellen
Func __SliderSystem_CreatePhysicalMapping()
    $__SliderSystem_iPhysicalMappingCount = $__SliderSystem_iMonitorCount
    ReDim $__SliderSystem_aPhysicalMapping[$__SliderSystem_iPhysicalMappingCount + 1][3]
    
    For $i = 1 To $__SliderSystem_iPhysicalMappingCount
        $__SliderSystem_aPhysicalMapping[$i][0] = $i  ; Windows Monitor
        $__SliderSystem_aPhysicalMapping[$i][1] = ($i - 1) * 1920  ; X-Position
        
        ; Beschreibung
        If $__SliderSystem_iMonitorCount = 1 Then
            $__SliderSystem_aPhysicalMapping[$i][2] = "Einziger"
        ElseIf $i = 1 Then
            $__SliderSystem_aPhysicalMapping[$i][2] = "Links"
        ElseIf $i = $__SliderSystem_iMonitorCount Then
            $__SliderSystem_aPhysicalMapping[$i][2] = "Rechts"
        Else
            $__SliderSystem_aPhysicalMapping[$i][2] = "Mitte"
        EndIf
    Next
EndFunc

; Monitor an Punkt ermitteln
Func __SliderSystem_GetMonitorAtPoint($iX, $iY)
    For $i = 1 To $__SliderSystem_iMonitorCount
        If $iX >= $__SliderSystem_aMonitors[$i][2] And $iX < $__SliderSystem_aMonitors[$i][2] + $__SliderSystem_aMonitors[$i][0] Then
            If $iY >= $__SliderSystem_aMonitors[$i][3] And $iY < $__SliderSystem_aMonitors[$i][3] + $__SliderSystem_aMonitors[$i][1] Then
                Return $i
            EndIf
        EndIf
    Next
    Return 1 ; Fallback
EndFunc

; Slide-Animation ausführen
Func __SliderSystem_SlideWindow($sDirection, $sAnimation)
    If $__SliderSystem_bIsAnimating Then Return False
    
    $__SliderSystem_bIsAnimating = True
    
    Local $aWindowPos = WinGetPos($__SliderSystem_hTargetGUI)
    If Not IsArray($aWindowPos) Then 
        $__SliderSystem_bIsAnimating = False
        Return False
    EndIf
    
    Local $iMonitor = $__SliderSystem_iCurrentMonitor
    Local $iStartX = $aWindowPos[0]
    Local $iStartY = $aWindowPos[1]
    Local $iFinalX = $iStartX
    Local $iFinalY = $iStartY
    
    ; Ziel-Position berechnen
    Local $iVisiblePixels = 8
    Switch $sDirection
        Case $SLIDER_POS_LEFT
            If $sAnimation = $SLIDER_ANIM_OUT Then
                $iFinalX = $__SliderSystem_aMonitors[$iMonitor][2] - $aWindowPos[2] + $iVisiblePixels
            Else
                $iFinalX = $__SliderSystem_aMonitors[$iMonitor][2] + ($__SliderSystem_aMonitors[$iMonitor][0] - $aWindowPos[2]) / 2
            EndIf
            
        Case $SLIDER_POS_RIGHT
            If $sAnimation = $SLIDER_ANIM_OUT Then
                $iFinalX = $__SliderSystem_aMonitors[$iMonitor][2] + $__SliderSystem_aMonitors[$iMonitor][0] - $iVisiblePixels
            Else
                $iFinalX = $__SliderSystem_aMonitors[$iMonitor][2] + ($__SliderSystem_aMonitors[$iMonitor][0] - $aWindowPos[2]) / 2
            EndIf
            
        Case $SLIDER_POS_TOP
            If $sAnimation = $SLIDER_ANIM_OUT Then
                $iFinalY = $__SliderSystem_aMonitors[$iMonitor][3] - $aWindowPos[3] + $iVisiblePixels
            Else
                $iFinalY = $__SliderSystem_aMonitors[$iMonitor][3] + ($__SliderSystem_aMonitors[$iMonitor][1] - $aWindowPos[3]) / 2
            EndIf
            
        Case $SLIDER_POS_BOTTOM
            If $sAnimation = $SLIDER_ANIM_OUT Then
                $iFinalY = $__SliderSystem_aMonitors[$iMonitor][3] + $__SliderSystem_aMonitors[$iMonitor][1] - $iVisiblePixels
            Else
                $iFinalY = $__SliderSystem_aMonitors[$iMonitor][3] + ($__SliderSystem_aMonitors[$iMonitor][1] - $aWindowPos[3]) / 2
            EndIf
    EndSwitch
    
    ; Animation ausführen (10 Schritte)
    Local $iSteps = 10
    Local $iStepX = ($iFinalX - $iStartX) / $iSteps
    Local $iStepY = ($iFinalY - $iStartY) / $iSteps
    
    For $i = 1 To $iSteps
        Local $iCurrentX = $iStartX + ($iStepX * $i)
        Local $iCurrentY = $iStartY + ($iStepY * $i)
        WinMove($__SliderSystem_hTargetGUI, "", $iCurrentX, $iCurrentY)
        Sleep(20)
    Next
    
    ; Status aktualisieren
    If $sAnimation = $SLIDER_ANIM_OUT Then
        $__SliderSystem_bIsSlideOut = True
        $__SliderSystem_sSlidePosition = $sDirection
    Else
        $__SliderSystem_bIsSlideOut = False
        $__SliderSystem_sSlidePosition = $SLIDER_POS_CENTER
    EndIf
    
    $__SliderSystem_bIsAnimating = False
    Return True
EndFunc

; Auto-Slide-In Funktion
Func __SliderSystem_AutoSlideIn()
    If Not $__SliderSystem_bIsSlideOut Or $__SliderSystem_bIsAnimating Then Return
    
    Local $aMousePos = MouseGetPos()
    Local $aGuiPos = WinGetPos($__SliderSystem_hTargetGUI)
    If Not IsArray($aGuiPos) Then Return
    
    Local $iTolerance = 30
    Local $bMouseOverGUI = ($aMousePos[0] >= $aGuiPos[0] - $iTolerance And _
                           $aMousePos[0] <= $aGuiPos[0] + $aGuiPos[2] + $iTolerance And _
                           $aMousePos[1] >= $aGuiPos[1] - $iTolerance And _
                           $aMousePos[1] <= $aGuiPos[1] + $aGuiPos[3] + $iTolerance)
    
    If $bMouseOverGUI Then
        __SliderSystem_SlideWindow($__SliderSystem_sSlidePosition, $SLIDER_ANIM_IN)
    EndIf
EndFunc

; Physisch linker Monitor
Func __SliderSystem_GetPhysicalLeftMonitor($iMonitor)
    For $i = 1 To $__SliderSystem_iPhysicalMappingCount
        If $__SliderSystem_aPhysicalMapping[$i][0] = $iMonitor Then
            If $i > 1 And $i - 1 >= 1 Then
                Return $__SliderSystem_aPhysicalMapping[$i - 1][0]
            EndIf
            ExitLoop
        EndIf
    Next
    Return 0
EndFunc

; Physisch rechter Monitor
Func __SliderSystem_GetPhysicalRightMonitor($iMonitor)
    For $i = 1 To $__SliderSystem_iPhysicalMappingCount
        If $__SliderSystem_aPhysicalMapping[$i][0] = $iMonitor Then
            If $i < $__SliderSystem_iPhysicalMappingCount And $i + 1 <= $__SliderSystem_iPhysicalMappingCount Then
                Return $__SliderSystem_aPhysicalMapping[$i + 1][0]
            EndIf
            ExitLoop
        EndIf
    Next
    Return 0
EndFunc

; Slider-Modi Implementation

; Standard Slide Mode
Func __SliderSystem_StandardSlideLeft()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_LEFT Then
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_IN)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_OUT)
    EndIf
EndFunc

Func __SliderSystem_StandardSlideRight()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_RIGHT Then
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_IN)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_OUT)
    EndIf
EndFunc

; Classic Slide Mode
Func __SliderSystem_ClassicSlideLeft()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_LEFT Then
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_IN)
        Return
    EndIf
    
    Local $iLeftMonitor = __SliderSystem_GetPhysicalLeftMonitor($__SliderSystem_iCurrentMonitor)
    If $iLeftMonitor > 0 Then
        __SliderSystem_FastMoveToMonitor($iLeftMonitor)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_OUT)
    EndIf
EndFunc

Func __SliderSystem_ClassicSlideRight()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_RIGHT Then
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_IN)
        Return
    EndIf
    
    Local $iRightMonitor = __SliderSystem_GetPhysicalRightMonitor($__SliderSystem_iCurrentMonitor)
    If $iRightMonitor > 0 Then
        __SliderSystem_FastMoveToMonitor($iRightMonitor)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_OUT)
    EndIf
EndFunc

; Direct Slide Mode
Func __SliderSystem_DirectSlideLeft()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_LEFT Then
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_IN)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_OUT)
    EndIf
EndFunc

Func __SliderSystem_DirectSlideRight()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_RIGHT Then
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_IN)
    Else
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_OUT)
    EndIf
EndFunc

; Continuous Slide Mode
Func __SliderSystem_ContinuousSlideLeft()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_LEFT Then
        __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_IN)
        Return
    EndIf
    
    ; Finde äußersten linken Monitor
    Local $iTargetMonitor = $__SliderSystem_iCurrentMonitor
    Local $iSteps = 0
    
    While $iSteps < 10
        Local $iLeftMonitor = __SliderSystem_GetPhysicalLeftMonitor($iTargetMonitor)
        If $iLeftMonitor <= 0 Then ExitLoop
        $iTargetMonitor = $iLeftMonitor
        $iSteps += 1
    WEnd
    
    ; Fahrt zum Ziel-Monitor
    If $iTargetMonitor <> $__SliderSystem_iCurrentMonitor Then
        __SliderSystem_AnimatedMoveToMonitor($iTargetMonitor)
    EndIf
    
    ; Slide OUT
    __SliderSystem_SlideWindow($SLIDER_POS_LEFT, $SLIDER_ANIM_OUT)
EndFunc

Func __SliderSystem_ContinuousSlideRight()
    If $__SliderSystem_bIsSlideOut And $__SliderSystem_sSlidePosition = $SLIDER_POS_RIGHT Then
        __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_IN)
        Return
    EndIf
    
    ; Finde äußersten rechten Monitor
    Local $iTargetMonitor = $__SliderSystem_iCurrentMonitor
    Local $iSteps = 0
    
    While $iSteps < 10
        Local $iRightMonitor = __SliderSystem_GetPhysicalRightMonitor($iTargetMonitor)
        If $iRightMonitor <= 0 Then ExitLoop
        $iTargetMonitor = $iRightMonitor
        $iSteps += 1
    WEnd
    
    ; Fahrt zum Ziel-Monitor
    If $iTargetMonitor <> $__SliderSystem_iCurrentMonitor Then
        __SliderSystem_AnimatedMoveToMonitor($iTargetMonitor)
    EndIf
    
    ; Slide OUT
    __SliderSystem_SlideWindow($SLIDER_POS_RIGHT, $SLIDER_ANIM_OUT)
EndFunc

; Schneller Monitor-Wechsel
Func __SliderSystem_FastMoveToMonitor($iTargetMonitor)
    If $iTargetMonitor < 1 Or $iTargetMonitor > $__SliderSystem_iMonitorCount Then Return False
    
    Local $aWindowPos = WinGetPos($__SliderSystem_hTargetGUI)
    If Not IsArray($aWindowPos) Then Return False
    
    ; Zentriere auf Ziel-Monitor
    Local $iCenterX = $__SliderSystem_aMonitors[$iTargetMonitor][2] + ($__SliderSystem_aMonitors[$iTargetMonitor][0] - $aWindowPos[2]) / 2
    Local $iCenterY = $__SliderSystem_aMonitors[$iTargetMonitor][3] + ($__SliderSystem_aMonitors[$iTargetMonitor][1] - $aWindowPos[3]) / 2
    
    WinMove($__SliderSystem_hTargetGUI, "", $iCenterX, $iCenterY)
    
    $__SliderSystem_iCurrentMonitor = $iTargetMonitor
    $__SliderSystem_bIsSlideOut = False
    $__SliderSystem_sSlidePosition = $SLIDER_POS_CENTER
    
    Return True
EndFunc

; Animierte Fahrt zwischen Monitoren
Func __SliderSystem_AnimatedMoveToMonitor($iTargetMonitor)
    Local $aStartPos = WinGetPos($__SliderSystem_hTargetGUI)
    If Not IsArray($aStartPos) Then Return False
    
    Local $iTargetX = $__SliderSystem_aMonitors[$iTargetMonitor][2] + ($__SliderSystem_aMonitors[$iTargetMonitor][0] - $aStartPos[2]) / 2
    Local $iTargetY = $__SliderSystem_aMonitors[$iTargetMonitor][3] + ($__SliderSystem_aMonitors[$iTargetMonitor][1] - $aStartPos[3]) / 2
    
    ; Animation (15 Schritte)
    Local $iSteps = 15
    Local $iStepX = ($iTargetX - $aStartPos[0]) / $iSteps
    Local $iStepY = ($iTargetY - $aStartPos[1]) / $iSteps
    
    For $i = 1 To $iSteps
        Local $iCurrentX = $aStartPos[0] + ($iStepX * $i)
        Local $iCurrentY = $aStartPos[1] + ($iStepY * $i)
        WinMove($__SliderSystem_hTargetGUI, "", $iCurrentX, $iCurrentY)
        Sleep(25)
    Next
    
    $__SliderSystem_iCurrentMonitor = $iTargetMonitor
    $__SliderSystem_bIsSlideOut = False
    $__SliderSystem_sSlidePosition = $SLIDER_POS_CENTER
    
    Return True
EndFunc