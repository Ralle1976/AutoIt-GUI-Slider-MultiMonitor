#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.16.1
 Author:         Multi-Monitor Slider Project

 Script Function:
    Hauptprogramm für die GUI-Slider Multi-Monitor Anwendung
#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include "includes\GlobalVars.au3"
#include "includes\Constants.au3"
#include "modules\MonitorDetection.au3"
#include "modules\SliderLogic.au3"
#include "modules\ConfigManager.au3"
#include "modules\GUIControl.au3"
#include "modules\Logging.au3"
#include "modules\Visualization.au3"
#include "modules\AutoSlideMode.au3"

; ==========================================
; Hauptprogramm
; ==========================================

; AutoIt Optionen setzen
Opt("GUIOnEventMode", 1)          ; Event-Modus aktivieren
Opt("GUICloseOnESC", 0)           ; ESC schließt GUI nicht
Opt("TrayIconHide", 0)            ; Tray-Icon anzeigen
Opt("TrayMenuMode", 3)            ; Standard Tray-Menü-Items entfernen

; Initialisierung
_Main()

; ==========================================
; Hauptfunktion
; ==========================================
Func _Main()
    ; Prüfe auf bereits laufende Instanz
    If _Singleton("GUI_Slider_MultiMonitor", 1) = 0 Then
        MsgBox(48, "Information", "Das Programm läuft bereits!")
        Exit
    EndIf

    ; Initialisiere System
    If Not _InitializeSystem() Then
        MsgBox(16, "Fehler", "System konnte nicht initialisiert werden!")
        Exit
    EndIf

    ; Erstelle und zeige GUI
    If Not _CreateMainGUI() Then
        MsgBox(16, "Fehler", "GUI konnte nicht erstellt werden!")
        Exit
    EndIf

    ; Registriere Hotkeys
    _RegisterHotkeys()

    ; Zeige GUI
    _ShowGUI()

    ; Erstelle Tray-Menü
    _CreateTrayMenu()

    ; Registriere Auto-Slide wenn aktiviert
    Local $aBehavior = _GetBehaviorSettings()
    Local $bAutoSlideIn = False
    Local $iAutoSlideInDelay = 250

    For $i = 0 To UBound($aBehavior) - 1
        Switch $aBehavior[$i][0]
            Case "AutoSlideMode"
                $bAutoSlideIn = $aBehavior[$i][1]
            Case "AutoSlideDelay"
                $iAutoSlideInDelay = Int($aBehavior[$i][1])
            Case "ClassicSliderMode"
                $g_bClassicSliderMode = $aBehavior[$i][1]
            Case "DirectSlideMode"
                $g_bDirectSlideMode = $aBehavior[$i][1]
            Case "ContinuousSlideMode"
                $g_bContinuousSlideMode = $aBehavior[$i][1]
        EndSwitch
    Next

    ; Modus-Validierung: Nur ein Modus kann aktiv sein
    Local $iActiveModes = 0
    If $g_bClassicSliderMode Then $iActiveModes += 1
    If $g_bDirectSlideMode Then $iActiveModes += 1
    If $g_bContinuousSlideMode Then $iActiveModes += 1

    If $iActiveModes > 1 Then
        _LogWarning("Mehrere Slider-Modi aktiviert! Verwende Standard-Modus.")
        $g_bClassicSliderMode = False
        $g_bDirectSlideMode = False
        $g_bContinuousSlideMode = False
    EndIf

    ; Modus-Logging
    Local $sActiveMode = "Standard"
    If $g_bClassicSliderMode Then $sActiveMode = "Classic"
    If $g_bDirectSlideMode Then $sActiveMode = "Direct"
    If $g_bContinuousSlideMode Then $sActiveMode = "Continuous"
    _LogInfo("Slider-Modus: " & $sActiveMode)

    If $bAutoSlideIn Then
        _SetAutoSlideMode(True, 500, $iAutoSlideInDelay)
        _LogInfo("Auto-Slide aktiviert (Delay Out: 500ms, Delay In: " & $iAutoSlideInDelay & "ms)")
    EndIf

    ; Hauptschleife
    Local $iLastCheck = 0
    Local $iVisUpdate = 0
    While 1
        Sleep(50)

        ; Prüfe auf GUI-Updates
        If $g_bIsAnimating Then
            ContinueLoop
        EndIf

        ; Monitor-Position aktualisieren wenn GUI bewegt wurde
        If TimerDiff($iLastCheck) > 500 Then
            _UpdateCurrentMonitor()
            $iLastCheck = TimerInit()
        EndIf

        ; Visualisierung regelmäßig aktualisieren
        If TimerDiff($iVisUpdate) > 100 Then  ; Alle 100ms
            _UpdateVisualization()

            ; Auto-Slide prüfen
            _CheckAutoSlide($g_hMainGUI)

            ; Automatische GUI-Wiederherstellung wenn außerhalb
            Local $aPos = WinGetPos($g_hMainGUI)
            If IsArray($aPos) Then
                If _IsWindowOutOfBounds($aPos[0], $aPos[1], $aPos[2], $aPos[3]) Then
                    _LogWarning("GUI ist außerhalb des sichtbaren Bereichs - starte automatische Wiederherstellung")
                    _RecoverLostWindow($g_hMainGUI)
                EndIf
            EndIf

            $iVisUpdate = TimerInit()
        EndIf
    WEnd
EndFunc

; ==========================================
; System-Initialisierung
; ==========================================
Func _InitializeSystem()
    ; Logging initialisieren
    If Not _InitLogging() Then
        MsgBox(16, "Fehler", "Logging konnte nicht initialisiert werden!")
        Return False
    EndIf

    _LogInfo("=== System-Initialisierung ===")

    ; Erkenne Monitore ZUERST
    Local $aMonitors = _GetMonitors()
    If @error Or $aMonitors[0][0] = 0 Then
        _LogError("Keine Monitore erkannt!")
        MsgBox(16, "Fehler", "Keine Monitore erkannt!")
        Return False
    EndIf

    ; Lade Konfiguration NACH Monitor-Erkennung
    If Not _LoadConfig() Then
        _LogError("Fehler beim Laden der Konfiguration!")
        Return False
    EndIf

    _LogInfo("System initialisiert:")
    _LogInfo("- Monitore erkannt: " & $aMonitors[0][0])
    _LogInfo("- Konfig geladen: " & $g_sConfigFile)

    ; Monitor-Details loggen
    _LogMonitorInfo()

    ; Validiere und setze initialen Monitor
    If $g_iCurrentScreenNumber < 1 Or $g_iCurrentScreenNumber > $aMonitors[0][0] Then
        _LogWarning("Ungültiger gespeicherter Monitor-Index: " & $g_iCurrentScreenNumber & " - verwende Monitor 1")
        $g_iCurrentScreenNumber = 1
        $g_iLastMonitor = 1
    EndIf

    ; Visualisierung initialisieren
    If Not _InitVisualization() Then
        _LogWarning("Visualisierung konnte nicht initialisiert werden")
    EndIf

    Return True
EndFunc

; ==========================================
; Tray-Menü
; ==========================================
Func _CreateTrayMenu()
    ; Tray-Menü Items
    Local $idTrayShow = TrayCreateItem("Anzeigen")
    Local $idTrayHide = TrayCreateItem("Verstecken")
    TrayCreateItem("")  ; Separator
    Local $idTrayCenter = TrayCreateItem("Zentrieren")
    Local $idTrayRecover = TrayCreateItem("GUI wiederherstellen (Alt+Ende)")
    TrayCreateItem("")  ; Separator
    Local $idTrayConfig = TrayCreateItem("Konfiguration öffnen")
    TrayCreateItem("")  ; Separator
    Local $idTrayAbout = TrayCreateItem("Über...")
    Local $idTrayExit = TrayCreateItem("Beenden")

    ; Tray Events
    TrayItemSetOnEvent($idTrayShow, "_TrayShow")
    TrayItemSetOnEvent($idTrayHide, "_TrayHide")
    TrayItemSetOnEvent($idTrayCenter, "_TrayCenter")
    TrayItemSetOnEvent($idTrayRecover, "_TrayRecover")
    TrayItemSetOnEvent($idTrayConfig, "_TrayConfig")
    TrayItemSetOnEvent($idTrayAbout, "_TrayAbout")
    TrayItemSetOnEvent($idTrayExit, "_TrayExit")

    ; Tray-Icon Tooltip mit visueller Position und Display-Nummer
    Local $iVisualIndex = _GetVisualMonitorIndex($g_iCurrentScreenNumber)
    Local $iActualDisplay = _GetActualDisplayNumber($g_iCurrentScreenNumber)

    Local $sTooltip = "GUI Slider - Monitor " & $iVisualIndex
    If $iActualDisplay <> $g_iCurrentScreenNumber Then
        $sTooltip &= " (Display " & $iActualDisplay & ")"
    EndIf
    TraySetToolTip($sTooltip)

    ; Zeige Tray-Icon
    TraySetState(1)
EndFunc

; Tray-Event-Handler
Func _TrayShow()
    _ShowGUI()
EndFunc

Func _TrayHide()
    _HideGUI()
EndFunc

Func _TrayCenter()
    _CenterOnMonitor($g_hMainGUI)
    _UpdateMonitorInfo()
EndFunc

Func _TrayRecover()
    _LogInfo("GUI-Wiederherstellung über Tray-Menü")
    _RecoverLostWindow($g_hMainGUI)
    _ShowGUI()
    _UpdateMonitorInfo()
EndFunc

Func _TrayConfig()
    ; Öffne Konfigurations-Datei
    ShellExecute($g_sConfigFile)
EndFunc

Func _TrayAbout()
    Local $sMsg = "GUI-Slider Multi-Monitor" & @CRLF & @CRLF
    $sMsg &= "Version: 1.0.0" & @CRLF
    $sMsg &= "Entwickelt für Multi-Monitor-Setups" & @CRLF & @CRLF
    $sMsg &= "Erkannte Monitore: " & $g_aMonitors[0][0] & @CRLF
    $sMsg &= "Aktueller Monitor: " & $g_iCurrentScreenNumber & @CRLF & @CRLF
    $sMsg &= "=== Hotkeys ===" & @CRLF
    $sMsg &= "Alt + Pfeiltasten: GUI verschieben" & @CRLF
    $sMsg &= "Alt + Leertaste: Slide ein/aus" & @CRLF
    $sMsg &= "Alt + Pos1: GUI zentrieren" & @CRLF
    $sMsg &= "Alt + Ende: GUI wiederherstellen (wenn verschwunden)" & @CRLF & @CRLF
    $sMsg &= _DebugMonitorInfo()

    MsgBox(64, "Über GUI-Slider", $sMsg)
EndFunc

Func _TrayExit()
    _OnClose()
EndFunc

; ==========================================
; Cleanup beim Beenden
; ==========================================
Func _Cleanup()
    _LogInfo("Beende Programm...")

    ; Speichere aktuelle Position
    _SaveConfig()

    ; Deaktiviere Auto-Slide
    _SetAutoSlideMode(False)

    ; Entferne Hotkeys
    HotKeySet("!{Left}")
    HotKeySet("!{Right}")
    HotKeySet("!{Up}")
    HotKeySet("!{Down}")
    HotKeySet("!{Space}")
    HotKeySet("!{Home}")
    HotKeySet("!{End}")

    ; Visualisierung schließen
    _CloseVisualization()

    ; GUI aufräumen
    _DestroyGUI()

    ; Logging beenden
    _CloseLogging()
EndFunc

; OnAutoItExitRegister
OnAutoItExitRegister("_Cleanup")
