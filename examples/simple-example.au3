#cs ----------------------------------------------------------------------------
 Simple Example: Grundlegende Verwendung der GUI-Slider-MultiMonitor UDF
#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include "..\SliderSystem.au3"

; Erstelle dein GUI
Local $hGUI = GUICreate("Einfaches Slider Beispiel", 400, 200)
GUISetBkColor(0xF0F0F0)

; Deine GUI-Elemente
Local $lblTitle = GUICtrlCreateLabel("Mein Programm mit Slider", 50, 20, 300, 30, 1)
GUICtrlSetFont($lblTitle, 14, 600)

Local $btnMyButton = GUICtrlCreateButton("Meine Funktion", 50, 60, 120, 30)

; Slider-Steuerung
Local $btnLeft = GUICtrlCreateButton("← Links", 50, 110, 60, 30)
Local $btnRight = GUICtrlCreateButton("Rechts →", 120, 110, 60, 30)
Local $btnUp = GUICtrlCreateButton("↑ Oben", 190, 110, 60, 30)
Local $btnDown = GUICtrlCreateButton("↓ Unten", 260, 110, 60, 30)

Local $btnExit = GUICtrlCreateButton("Beenden", 320, 160, 60, 30)

; GUI anzeigen
GUISetState(@SW_SHOW, $hGUI)

; ==========================================
; Slider-System initialisieren
; ==========================================
_SliderSystem_Init($hGUI)
_SliderSystem_SetMode($SLIDER_MODE_CONTINUOUS)  ; Continuous Mode
_SliderSystem_EnableAutoSlideIn(True, 250)      ; Auto-Slide-In nach 250ms

ConsoleWrite("Slider-System initialisiert!" & @CRLF)
ConsoleWrite("Modus: " & _SliderSystem_GetMode() & @CRLF)
ConsoleWrite("Monitor: " & _SliderSystem_GetCurrentMonitor() & @CRLF)

; ==========================================
; Event-Loop
; ==========================================
While 1
    Local $msg = GUIGetMsg()
    
    Switch $msg
        Case $GUI_EVENT_CLOSE, $btnExit
            ExitLoop
            
        Case $btnMyButton
            MsgBox(0, "Info", "Meine Funktion wurde ausgeführt!")
            
        ; Slider-Steuerung
        Case $btnLeft
            _SliderSystem_SlideLeft()
            
        Case $btnRight
            _SliderSystem_SlideRight()
            
        Case $btnUp
            _SliderSystem_SlideUp()
            
        Case $btnDown
            _SliderSystem_SlideDown()
    EndSwitch
    
    Sleep(10)
WEnd

; ==========================================
; Cleanup
; ==========================================
_SliderSystem_Cleanup()
GUIDelete($hGUI)

ConsoleWrite("Programm beendet." & @CRLF)