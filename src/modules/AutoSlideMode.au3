#include-once
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "SliderLogic.au3"
#include "Logging.au3"

; ==========================================
; Auto-Slide Modus
; ==========================================

; Globale Variablen für Auto-Slide
Global $g_bAutoSlideEnabled = False
Global $g_bMouseOverGUI = False
Global $g_iAutoSlideTimer = 0
Global $g_iAutoSlideDelay = 500  ; ms Verzögerung bevor ein/ausfahren
Global $g_bAutoSlideWaiting = False

; Aktiviert/Deaktiviert den Auto-Slide Modus
Func _SetAutoSlideMode($bEnable = True)
    $g_bAutoSlideEnabled = $bEnable
    
    If $bEnable Then
        _LogInfo("Auto-Slide Modus aktiviert")
        ; Registriere Timer-Funktion für Maus-Tracking
        AdlibRegister("_CheckAutoSlide", 50)
    Else
        _LogInfo("Auto-Slide Modus deaktiviert")
        AdlibUnRegister("_CheckAutoSlide")
        $g_bAutoSlideWaiting = False
    EndIf
EndFunc

; Prüft kontinuierlich die Mausposition für Auto-Slide
Func _CheckAutoSlide()
    If Not $g_bAutoSlideEnabled Then Return
    If $g_bIsAnimating Then Return  ; Keine Aktion während Animation
    If Not IsHWnd($g_hMainGUI) Then Return
    
    ; Hole GUI-Position und -Größe
    Local $aGUIPos = WinGetPos($g_hMainGUI)
    If Not IsArray($aGUIPos) Then Return
    
    ; Hole Mausposition
    Local $aMousePos = MouseGetPos()
    
    ; Erweitere den Erkennungsbereich wenn GUI ausgefahren ist
    Local $iMargin = 50  ; Pixel Toleranz
    Local $bMouseInArea = False
    
    ; Prüfe ob Maus über GUI oder im erweiterten Bereich ist
    If $g_bWindowIsOut Then
        ; GUI ist ausgefahren - erweiterte Erkennung
        Switch $g_sWindowIsAt
            Case $POS_LEFT
                ; GUI ist links ausgefahren - prüfe rechten Rand
                $bMouseInArea = ($aMousePos[0] >= 0 And $aMousePos[0] <= $iMargin)
                
            Case $POS_RIGHT
                ; GUI ist rechts ausgefahren - prüfe linken Rand
                Local $iScreenRight = $g_aMonitors[$g_iCurrentScreenNumber][2] + $g_aMonitors[$g_iCurrentScreenNumber][0]
                $bMouseInArea = ($aMousePos[0] >= $iScreenRight - $iMargin And $aMousePos[0] <= $iScreenRight)
                
            Case $POS_TOP
                ; GUI ist oben ausgefahren - prüfe unteren Rand
                $bMouseInArea = ($aMousePos[1] >= 0 And $aMousePos[1] <= $iMargin)
                
            Case $POS_BOTTOM
                ; GUI ist unten ausgefahren - prüfe oberen Rand
                Local $iScreenBottom = $g_aMonitors[$g_iCurrentScreenNumber][3] + $g_aMonitors[$g_iCurrentScreenNumber][1]
                $bMouseInArea = ($aMousePos[1] >= $iScreenBottom - $iMargin And $aMousePos[1] <= $iScreenBottom)
        EndSwitch
    Else
        ; GUI ist normal - prüfe ob Maus über GUI
        $bMouseInArea = _IsMouseOverWindow($aMousePos[0], $aMousePos[1], $aGUIPos)
    EndIf
    
    ; Status-Änderung erkannt?
    If $bMouseInArea <> $g_bMouseOverGUI Then
        $g_bMouseOverGUI = $bMouseInArea
        
        If $bMouseInArea Then
            ; Maus ist über GUI/Bereich gekommen
            _LogDebug("Auto-Slide: Maus über GUI erkannt")
            
            If $g_bWindowIsOut Then
                ; GUI ist ausgefahren und Maus kommt drüber - einfahren
                $g_bAutoSlideWaiting = True
                $g_iAutoSlideTimer = TimerInit()
            EndIf
        Else
            ; Maus hat GUI/Bereich verlassen
            _LogDebug("Auto-Slide: Maus hat GUI verlassen")
            
            If Not $g_bWindowIsOut And _IsGUIFullyVisible() Then
                ; GUI ist normal sichtbar und Maus verlässt - ausfahren
                $g_bAutoSlideWaiting = True
                $g_iAutoSlideTimer = TimerInit()
            ElseIf $g_bWindowIsOut Then
                ; Aktion abbrechen wenn Maus während Wartezeit verschwindet
                $g_bAutoSlideWaiting = False
            EndIf
        EndIf
    EndIf
    
    ; Prüfe ob Timer abgelaufen und Aktion ausgeführt werden soll
    If $g_bAutoSlideWaiting And TimerDiff($g_iAutoSlideTimer) >= $g_iAutoSlideDelay Then
        $g_bAutoSlideWaiting = False
        
        If $g_bMouseOverGUI And $g_bWindowIsOut Then
            ; Einfahren
            _LogInfo("Auto-Slide: Fahre GUI ein")
            _SlideIn()
        ElseIf Not $g_bMouseOverGUI And Not $g_bWindowIsOut And _IsGUIFullyVisible() Then
            ; Ausfahren in die zuletzt verwendete Richtung
            _LogInfo("Auto-Slide: Fahre GUI aus nach " & $g_sWindowIsAt)
            _SlideDirection($g_sWindowIsAt)
        EndIf
    EndIf
EndFunc

; Prüft ob Maus über einem Fenster ist
Func _IsMouseOverWindow($iMouseX, $iMouseY, $aWindowPos)
    Return ($iMouseX >= $aWindowPos[0] And _
            $iMouseX <= $aWindowPos[0] + $aWindowPos[2] And _
            $iMouseY >= $aWindowPos[1] And _
            $iMouseY <= $aWindowPos[1] + $aWindowPos[3])
EndFunc

; Prüft ob GUI vollständig sichtbar ist (nicht ausgefahren)
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

; Setzt die Verzögerung für Auto-Slide
Func _SetAutoSlideDelay($iDelay)
    If $iDelay < 100 Then $iDelay = 100  ; Minimum 100ms
    If $iDelay > 5000 Then $iDelay = 5000  ; Maximum 5 Sekunden
    
    $g_iAutoSlideDelay = $iDelay
    _LogInfo("Auto-Slide Verzögerung gesetzt auf: " & $iDelay & "ms")
EndFunc

; Hilfsfunktion zum Einfahren
Func _SlideIn()
    If Not $g_bWindowIsOut Then Return
    
    ; Fahre in die entgegengesetzte Richtung ein
    _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $g_sWindowIsAt, $ANIM_IN)
    $g_bWindowIsOut = False
EndFunc

; Hilfsfunktion zum Ausfahren in eine Richtung
Func _SlideDirection($sDirection)
    If $g_bWindowIsOut Then Return
    
    _SlideWindow($g_hMainGUI, $g_iCurrentScreenNumber, $sDirection, $ANIM_OUT)
    $g_bWindowIsOut = True
    $g_sWindowIsAt = $sDirection
EndFunc