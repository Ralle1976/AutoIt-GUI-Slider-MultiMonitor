#cs ----------------------------------------------------------------------------
 GUI-Slider-MultiMonitor Test Tool - OnEvent Version
 Optimierte Version mit OnEvent Mode für bessere Performance
#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <TrayConstants.au3>
#include <StructureConstants.au3>

#include <WinAPI.au3>
#include "..\SliderSystem.au3"

; OnEvent Mode aktivieren
Opt("GUIOnEventMode", 1)
Opt("TrayMenuMode", 1+2)  ; Kein Default-Menü, kein Pause

; GUI-Elemente
Global $hMainGUI, $btnLeft, $btnUp, $btnStop, $btnDown, $btnRight
Global $comboMode, $sliderSpeed, $lblSpeed, $chkAutoSlide, $lblStatus
Global $lblInfo, $btnConfig, $btnAbout, $btnTest, $btnReset, $btnVisualizer

; Tray-Menü Elemente
Global $idTraySlideIn, $idTrayVisualizer, $idTrayAbout, $idTrayExit

; Einstellungen
Global $iAnimationSpeed = 20  ; Standard-Geschwindigkeit
Global $bAutoSlideEnabled = True
Global $bVisualizerOn = False

; Erstelle Test-GUI
Func _CreateTestGUI()
    $hMainGUI = GUICreate("GUI-Slider Test Tool (OnEvent)", 520, 420, -1, -1, $WS_OVERLAPPEDWINDOW)
    GUISetBkColor(0xF0F0F0)
    GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")

    ; Registriere Handler für Minimum-Größe
    GUIRegisterMsg($WM_GETMINMAXINFO, "_WM_GETMINMAXINFO")

    ; Titel
    GUICtrlCreateLabel("GUI-Slider MultiMonitor Test", 10, 10, 500, 25, 1)
    GUICtrlSetFont(-1, 14, 800)
    GUICtrlSetColor(-1, 0x0066CC)

    ; Slider-Steuerung (5-Tasten-Layout)
    GUICtrlCreateGroup("Slider-Steuerung", 10, 50, 200, 120)

    ; Obere Reihe
    $btnUp = GUICtrlCreateButton("↑", 85, 75, 50, 30)
    GUICtrlSetFont($btnUp, 12, 600)
    GUICtrlSetTip($btnUp, "Nach oben sliden (Alt+↑)")
    GUICtrlSetOnEvent($btnUp, "_OnSlideUp")

    ; Mittlere Reihe
    $btnLeft = GUICtrlCreateButton("←", 25, 105, 50, 30)
    GUICtrlSetFont($btnLeft, 12, 600)
    GUICtrlSetTip($btnLeft, "Nach links sliden (Alt+←)")
    GUICtrlSetOnEvent($btnLeft, "_OnSlideLeft")

    $btnStop = GUICtrlCreateButton("⏹", 85, 105, 50, 30)
    GUICtrlSetFont($btnStop, 12, 600)
    GUICtrlSetBkColor($btnStop, 0xFF6666)
    GUICtrlSetTip($btnStop, "Stop/Zurück zur Mitte (Alt+Space)")
    GUICtrlSetOnEvent($btnStop, "_OnStop")

    $btnRight = GUICtrlCreateButton("→", 145, 105, 50, 30)
    GUICtrlSetFont($btnRight, 12, 600)
    GUICtrlSetTip($btnRight, "Nach rechts sliden (Alt+→)")
    GUICtrlSetOnEvent($btnRight, "_OnSlideRight")

    ; Untere Reihe
    $btnDown = GUICtrlCreateButton("↓", 85, 135, 50, 30)
    GUICtrlSetFont($btnDown, 12, 600)
    GUICtrlSetTip($btnDown, "Nach unten sliden (Alt+↓)")
    GUICtrlSetOnEvent($btnDown, "_OnSlideDown")

    ; Einstellungen
    GUICtrlCreateGroup("Einstellungen", 220, 50, 290, 120)

    ; Modus-Auswahl
    GUICtrlCreateLabel("Slider-Modus:", 230, 75, 80, 20)
    $comboMode = GUICtrlCreateCombo("Continuous", 230, 95, 120, 200, $CBS_DROPDOWNLIST)
    GUICtrlSetData($comboMode, "Standard|Classic|Direct|Continuous", "Continuous")
    GUICtrlSetTip($comboMode, "Standard: Normal | Classic: 2-Klick | Direct: Sofort | Continuous: Durchfahren")
    GUICtrlSetOnEvent($comboMode, "_OnModeChange")

    ; Geschwindigkeit
    GUICtrlCreateLabel("Geschwindigkeit:", 360, 75, 90, 20)
    $sliderSpeed = GUICtrlCreateSlider(360, 95, 100, 20)
    GUICtrlSetLimit($sliderSpeed, 50, 5)  ; 5ms bis 50ms
    GUICtrlSetData($sliderSpeed, 20)  ; Standard: 20ms
    GUICtrlSetTip($sliderSpeed, "Animation-Geschwindigkeit (5-50ms)")
    GUICtrlSetOnEvent($sliderSpeed, "_OnSpeedChange")
    $lblSpeed = GUICtrlCreateLabel("20ms", 470, 97, 40, 20)

    ; Auto-Slide-In
    $chkAutoSlide = GUICtrlCreateCheckbox("Auto-Slide-In", 360, 125, 100, 20)
    GUICtrlSetState($chkAutoSlide, $GUI_CHECKED)
    GUICtrlSetTip($chkAutoSlide, "Automatisches Einfahren bei Maus-Berührung")
    GUICtrlSetOnEvent($chkAutoSlide, "_OnAutoSlideToggle")

    ; Visualizer Button
    $btnVisualizer = GUICtrlCreateButton("Visualizer", 360, 145, 80, 20)
    GUICtrlSetBkColor($btnVisualizer, 0x66FF66)
    GUICtrlSetTip($btnVisualizer, "Monitor-Visualisierung ein/ausschalten")
    GUICtrlSetOnEvent($btnVisualizer, "_OnVisualizerToggle")

    ; Zusätzliche Funktionen
    GUICtrlCreateGroup("Funktionen", 10, 180, 500, 60)
    $btnConfig = GUICtrlCreateButton("Konfiguration", 20, 200, 100, 30)
    GUICtrlSetTip($btnConfig, "Erweiterte Konfiguration mit Monitor-Infos")
    GUICtrlSetOnEvent($btnConfig, "_OnConfig")

    $btnTest = GUICtrlCreateButton("Alle Modi testen", 130, 200, 110, 30)
    GUICtrlSetTip($btnTest, "Testet automatisch alle 4 Slider-Modi")
    GUICtrlSetOnEvent($btnTest, "_OnTestAll")

    $btnReset = GUICtrlCreateButton("Position reset", 250, 200, 100, 30)
    GUICtrlSetTip($btnReset, "GUI zur Bildschirmmitte zurücksetzen")
    GUICtrlSetOnEvent($btnReset, "_OnReset")

    ; Monitor Info statt Slide-In Button
    Local $btnMonitorInfo = GUICtrlCreateButton("Monitor Info", 360, 200, 100, 30)
    GUICtrlSetTip($btnMonitorInfo, "Zeige aktuelle Monitor-Informationen")
    GUICtrlSetOnEvent($btnMonitorInfo, "_OnMonitorInfo")

    ; Info-Icon (statt About Button)
    $btnAbout = GUICtrlCreateButton("ℹ", 480, 10, 25, 25)
    GUICtrlSetFont($btnAbout, 12, 400)
    GUICtrlSetTip($btnAbout, "Über das Test Tool")
    GUICtrlSetOnEvent($btnAbout, "_OnAbout")

    ; Status-Anzeige
    GUICtrlCreateGroup("Status", 10, 250, 500, 80)
    $lblStatus = GUICtrlCreateLabel("Initialisiere...", 20, 275, 480, 20)
    GUICtrlSetBkColor($lblStatus, 0xFFFFFF)
    GUICtrlSetFont($lblStatus, 9, 400, 0, "Consolas")

    $lblInfo = GUICtrlCreateLabel("Bereit zum Testen", 20, 300, 480, 20)
    GUICtrlSetColor($lblInfo, 0x006600)

    ; Hotkey-Info
    GUICtrlCreateGroup("Hotkeys", 10, 340, 500, 30)
    GUICtrlCreateLabel("Alt+Pfeiltasten: Slider-Steuerung | Alt+Space: Stop | Esc: Beenden", 20, 355, 480, 15)
    GUICtrlSetFont(-1, 8)

    GUISetState(@SW_SHOW, $hMainGUI)
    Return $hMainGUI
EndFunc

; ==========================================
; Event Handler Funktionen
; ==========================================

Func _OnSlideLeft()
    _SliderSystem_SlideLeft()
    _UpdateTestStatus()
EndFunc

Func _OnSlideRight()
    _SliderSystem_SlideRight()
    _UpdateTestStatus()
EndFunc

Func _OnSlideUp()
    _SliderSystem_SlideUp()
    _UpdateTestStatus()
EndFunc

Func _OnSlideDown()
    _SliderSystem_SlideDown()
    _UpdateTestStatus()
EndFunc

Func _OnStop()
    If _SliderSystem_IsSlideOut() Then
        Local $sPos = _SliderSystem_GetSlidePosition()
        Switch $sPos
            Case "Left"
                _SliderSystem_SlideLeft()
            Case "Right"
                _SliderSystem_SlideRight()
            Case "Top"
                _SliderSystem_SlideUp()
            Case "Bottom"
                _SliderSystem_SlideDown()
        EndSwitch
        _UpdateTestStatus()
    EndIf
EndFunc

Func _OnModeChange()
    Local $sNewMode = GUICtrlRead($comboMode)
    _SliderSystem_SetMode($sNewMode)
    ConsoleWrite("Modus geändert zu: " & $sNewMode & @CRLF)
    _UpdateTestStatus()
EndFunc

Func _OnSpeedChange()
    $iAnimationSpeed = GUICtrlRead($sliderSpeed)
    GUICtrlSetData($lblSpeed, $iAnimationSpeed & "ms")
    ConsoleWrite("Geschwindigkeit geändert zu: " & $iAnimationSpeed & "ms" & @CRLF)
    _UpdateTestStatus()
EndFunc

Func _OnAutoSlideToggle()
    $bAutoSlideEnabled = (GUICtrlRead($chkAutoSlide) = $GUI_CHECKED)
    _SliderSystem_EnableAutoSlideIn($bAutoSlideEnabled, 250)
    ConsoleWrite("Auto-Slide-In: " & ($bAutoSlideEnabled ? "aktiviert" : "deaktiviert") & @CRLF)
    _UpdateTestStatus()
EndFunc

Func _OnVisualizerToggle()
    $bVisualizerOn = Not $bVisualizerOn
    _SliderSystem_EnableVisualizer($bVisualizerOn)
    GUICtrlSetBkColor($btnVisualizer, $bVisualizerOn ? 0xFF6666 : 0x66FF66)
    GUICtrlSetData($btnVisualizer, $bVisualizerOn ? "Vis AUS" : "Vis EIN")
    ConsoleWrite("Visualizer " & ($bVisualizerOn ? "aktiviert" : "deaktiviert") & @CRLF)
    _UpdateTestStatus()
EndFunc

Func _OnConfig()
    _SliderSystem_ShowConfig()
EndFunc

Func _OnAbout()
    ; Zeige Hotkey-Informationen prominent
    Local $sInfo = "GUI-Slider MultiMonitor Test Tool" & @CRLF & _
           "Version: 2.0 (OnEvent)" & @CRLF & _
           "═══════════════════════════════════════" & @CRLF & @CRLF & _
           "HOTKEYS:" & @CRLF & _
           "────────────────────────────" & @CRLF & _
           "Alt + ← : Nach links sliden" & @CRLF & _
           "Alt + → : Nach rechts sliden" & @CRLF & _
           "Alt + ↑ : Nach oben sliden" & @CRLF & _
           "Alt + ↓ : Nach unten sliden" & @CRLF & _
           "Alt + Space : Stop/Zurück zur Mitte" & @CRLF & _
           "ESC : Programm beenden" & @CRLF & @CRLF & _
           "TRAY-MENÜ:" & @CRLF & _
           "────────────────────────────" & @CRLF & _
           "Rechtsklick auf Tray-Icon für:" & @CRLF & _
           "• Slide IN (wenn ausgefahren)" & @CRLF & _
           "• Visualizer Ein/Aus" & @CRLF & _
           "• Beenden" & @CRLF & @CRLF & _
           "Autor: Ralle1976"

    MsgBox(64, "ℹ Information & Hotkeys", $sInfo)
EndFunc

Func _OnTestAll()
    Local $aModes[4] = ["Standard", "Classic", "Direct", "Continuous"]

    For $i = 0 To 3
        ConsoleWrite("Teste Modus: " & $aModes[$i] & @CRLF)
        _SliderSystem_SetMode($aModes[$i])
        GUICtrlSetData($comboMode, $aModes[$i])
        _UpdateTestStatus()

        ; Kurz warten
        Sleep(1000)

        ; Test-Bewegung
        _SliderSystem_SlideRight()
        Sleep(500)
        _SliderSystem_SlideLeft()
        Sleep(1000)
    Next

    ; Zurück zu Continuous
    _SliderSystem_SetMode("Continuous")
    GUICtrlSetData($comboMode, "Continuous")
    _UpdateTestStatus()

    MsgBox(0, "Test", "Alle Modi getestet! Zurück zu Continuous Mode.")
EndFunc

Func _OnReset()
    ; GUI in die Bildschirmmitte bewegen
    Local $iScreenWidth = @DesktopWidth
    Local $iScreenHeight = @DesktopHeight
    Local $aGUISize = WinGetClientSize($hMainGUI)

    Local $iCenterX = ($iScreenWidth - $aGUISize[0]) / 2
    Local $iCenterY = ($iScreenHeight - $aGUISize[1]) / 2

    WinMove($hMainGUI, "", $iCenterX, $iCenterY)

    ConsoleWrite("Position zurückgesetzt zur Bildschirmmitte" & @CRLF)
    _UpdateTestStatus()
EndFunc

Func _OnMonitorInfo()
    ; Zeige aktuelle Monitor-Informationen
    Local $aMonitors = _GetMonitors()
    Local $sInfo = "Aktuelle Monitor-Konfiguration:" & @CRLF & @CRLF
    $sInfo &= "Erkannte Monitore: " & $aMonitors[0][0] & @CRLF
    $sInfo &= "─────────────────────────────" & @CRLF

    For $i = 1 To $aMonitors[0][0]
        $sInfo &= "Monitor " & $i & ": " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1] & _
                 " @ Position " & $aMonitors[$i][2] & "," & $aMonitors[$i][3] & @CRLF
    Next

    $sInfo &= @CRLF & "Aktueller Monitor: " & _SliderSystem_GetCurrentMonitor()
    $sInfo &= @CRLF & "GUI Status: " & (_SliderSystem_IsSlideOut() ? "Ausgefahren" : "Eingefahren")

    MsgBox(64, "Monitor Information", $sInfo)
EndFunc

; ==========================================
; Hilfsfunktionen
; ==========================================

; Slider-System initialisieren
Func _InitSliderSystem()
    If Not _SliderSystem_Init($hMainGUI) Then
        MsgBox(16, "Fehler", "Slider-System konnte nicht initialisiert werden!")
        Exit 1
    EndIf

    ; Standard-Einstellungen
    _SliderSystem_SetMode("Continuous")
    _SliderSystem_EnableAutoSlideIn(True, 250)

    ; Status aktualisieren
    _UpdateTestStatus()

    ConsoleWrite("=== GUI-SLIDER TEST TOOL (OnEvent) ====" & @CRLF)
    ConsoleWrite("Slider-System erfolgreich initialisiert" & @CRLF)
    ConsoleWrite("Modus: " & _SliderSystem_GetMode() & @CRLF)
    ConsoleWrite("Monitor: " & _SliderSystem_GetCurrentMonitor() & @CRLF)

    ; Monitor-Info ausgeben
    Local $aMonitors = _GetMonitors()
    ConsoleWrite("Erkannte Monitore: " & $aMonitors[0][0] & @CRLF)
    For $i = 1 To $aMonitors[0][0]
        ConsoleWrite("  Monitor " & $i & ": " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1] & _
                    " @ " & $aMonitors[$i][2] & "," & $aMonitors[$i][3] & @CRLF)
    Next
    ConsoleWrite(@CRLF)
EndFunc

; Status aktualisieren mit Timer
Func _UpdateTestStatus()
    Local Static $Old_str_status = "", $Old_str_Info = ""


    Local $sStatus = "Monitor: " & _SliderSystem_GetCurrentMonitor() & " | "
    $sStatus &= "Status: " & (_SliderSystem_IsSlideOut() ? "OUT" : "IN") & " | "
    $sStatus &= "Position: " & _SliderSystem_GetSlidePosition() & " | "
    $sStatus &= "Modus: " & _SliderSystem_GetMode()

    If $Old_str_status <> $sStatus Then
        GUICtrlSetData($lblStatus, $sStatus)
        $Old_str_status = $sStatus
    EndIf

    Local $sInfo = "Geschwindigkeit: " & $iAnimationSpeed & "ms | "
    $sInfo &= "Auto-Slide: " & ($bAutoSlideEnabled ? "EIN" : "AUS") & " | "
    $sInfo &= "Visualizer: " & ($bVisualizerOn ? "EIN" : "AUS")
    If $Old_str_Info <> $sInfo Then
        GUICtrlSetData($lblInfo, $sInfo)
        $Old_str_Info = $sInfo
    EndIf
EndFunc

; Hotkeys registrieren
Func _RegisterTestHotkeys()
    HotKeySet("!{LEFT}", "_HotkeyLeft")
    HotKeySet("!{RIGHT}", "_HotkeyRight")
    HotKeySet("!{UP}", "_HotkeyUp")
    HotKeySet("!{DOWN}", "_HotkeyDown")
    HotKeySet("!{SPACE}", "_HotkeyStop")
    HotKeySet("{ESC}", "_Exit")
EndFunc

; Hotkey-Funktionen
Func _HotkeyLeft()
    _OnSlideLeft()
EndFunc

Func _HotkeyRight()
    _OnSlideRight()
EndFunc

Func _HotkeyUp()
    _OnSlideUp()
EndFunc

Func _HotkeyDown()
    _OnSlideDown()
EndFunc

Func _HotkeyStop()
    _OnStop()
EndFunc

; Cleanup und Exit
Func _Exit()
    _SliderSystem_Cleanup()
    HotKeySet("!{LEFT}")
    HotKeySet("!{RIGHT}")
    HotKeySet("!{UP}")
    HotKeySet("!{DOWN}")
    HotKeySet("!{SPACE}")
    HotKeySet("{ESC}")
    GUIDelete($hMainGUI)
    ConsoleWrite("Test Tool beendet." & @CRLF)
    Exit
EndFunc

; ==========================================
; Tray-Menü Funktionen
; ==========================================

; Erstelle Tray-Menü
Func _CreateTrayMenu()
    ; Tray-Icon setzen
    TraySetIcon("shell32.dll", 238)  ; Slider-Icon
    TraySetToolTip("GUI-Slider Test Tool")

    ; Menü-Einträge
    $idTraySlideIn = TrayCreateItem("Slide IN")
    TrayItemSetOnEvent($idTraySlideIn, "_TraySlideIn")

    TrayCreateItem("")  ; Separator

    $idTrayVisualizer = TrayCreateItem("Visualizer Ein/Aus")
    TrayItemSetOnEvent($idTrayVisualizer, "_TrayVisualizerToggle")

    $idTrayAbout = TrayCreateItem("Info && Hotkeys")
    TrayItemSetOnEvent($idTrayAbout, "_OnAbout")

    TrayCreateItem("")  ; Separator

    $idTrayExit = TrayCreateItem("Beenden")
    TrayItemSetOnEvent($idTrayExit, "_Exit")

    ; Tray-Icon anzeigen
    TraySetState(1)

    ; Update Timer für Tray-Menü
    AdlibRegister("_UpdateTrayMenu", 500)
EndFunc

; Update Tray-Menü Status
Func _UpdateTrayMenu()
    ; Slide IN nur aktivieren wenn ausgefahren
    If _SliderSystem_IsSlideOut() Then
        TrayItemSetState($idTraySlideIn, $TRAY_ENABLE)
        TrayItemSetText($idTraySlideIn, "Slide IN (von " & _SliderSystem_GetSlidePosition() & ")")
    Else
        TrayItemSetState($idTraySlideIn, $TRAY_DISABLE)
        TrayItemSetText($idTraySlideIn, "Slide IN (bereits eingefahren)")
    EndIf

    ; Visualizer Status
    TrayItemSetText($idTrayVisualizer, "Visualizer " & ($bVisualizerOn ? "ausschalten" : "einschalten"))
EndFunc

; Tray Slide IN
Func _TraySlideIn()
    If _SliderSystem_IsSlideOut() Then
        Local $sPos = _SliderSystem_GetSlidePosition()
        Switch $sPos
            Case "Left"
                _SliderSystem_SlideLeft()
            Case "Right"
                _SliderSystem_SlideRight()
            Case "Top"
                _SliderSystem_SlideUp()
            Case "Bottom"
                _SliderSystem_SlideDown()
        EndSwitch
        ConsoleWrite("Tray: Manuell eingefahren von Position: " & $sPos & @CRLF)
        _UpdateTestStatus()
    EndIf
EndFunc

; Tray Visualizer Toggle
Func _TrayVisualizerToggle()
    _OnVisualizerToggle()
EndFunc

; ==========================================
; HAUPTPROGRAMM
; ==========================================

ConsoleWrite("Starte GUI-Slider Test Tool (OnEvent Version)..." & @CRLF)

; GUI erstellen
_CreateTestGUI()

; Slider-System initialisieren
_InitSliderSystem()

; Hotkeys registrieren
_RegisterTestHotkeys()

; Tray-Menü erstellen
_CreateTrayMenu()

; Status-Update Timer starten (alle 100ms)
AdlibRegister("_UpdateTestStatus", 100)

ConsoleWrite("Test Tool bereit! Verwende Buttons oder Alt+Pfeiltasten zum Testen." & @CRLF)

; Hauptschleife (viel effizienter mit OnEvent!)
While 1
    Sleep(10)  ; Minimaler Sleep für CPU-Schonung
WEnd

; ==========================================
; Window Message Handler
; ==========================================

; Handler für Minimum-Größe
Func _WM_GETMINMAXINFO($hWnd, $msg, $wParam, $lParam)
    If $hWnd = $hMainGUI Then
        Local $minmaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $lParam)
        DllStructSetData($minmaxinfo, 7, 520) ; Minimum X
        DllStructSetData($minmaxinfo, 8, 420) ; Minimum Y
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc