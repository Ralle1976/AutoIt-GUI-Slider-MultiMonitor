#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.16.1
 Author:         Multi-Monitor Slider Project

 Script Function:
    Hauptprogramm für die GUI-Slider Multi-Monitor Anwendung
#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "includes\GlobalVars.au3"
#include "includes\Constants.au3"
#include "modules\MonitorDetection.au3"
#include "modules\SliderLogic.au3"
#include "modules\ConfigManager.au3"
#include "modules\GUIControl.au3"
#include "modules\Logging.au3"
#include "modules\Visualization.au3"

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
    
    ; Registriere Auto-Slide-In wenn aktiviert
    Local $aBehavior = _GetBehaviorSettings()
    Local $bAutoSlideIn = False
    Local $iAutoSlideInDelay = 250
    
    For $i = 0 To UBound($aBehavior) - 1
        Switch $aBehavior[$i][0]
            Case "AutoSlideIn"
                $bAutoSlideIn = $aBehavior[$i][1]
            Case "AutoSlideInDelay"
                $iAutoSlideInDelay = Int($aBehavior[$i][1])
        EndSwitch
    Next
    
    If $bAutoSlideIn Then
        AdlibRegister("_CheckAutoSlideIn", $iAutoSlideInDelay)
        _LogInfo("Auto-Slide-In aktiviert (Interval: " & $iAutoSlideInDelay & "ms)")
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

    ; Lade Konfiguration
    If Not _LoadConfig() Then
        _LogError("Fehler beim Laden der Konfiguration!")
        Return False
    EndIf

    ; Erkenne Monitore
    Local $aMonitors = _GetMonitors()
    If @error Or $aMonitors[0][0] = 0 Then
        _LogError("Keine Monitore erkannt!")
        MsgBox(16, "Fehler", "Keine Monitore erkannt!")
        Return False
    EndIf

    _LogInfo("System initialisiert:")
    _LogInfo("- Monitore erkannt: " & $aMonitors[0][0])
    _LogInfo("- Konfig geladen: " & $g_sConfigFile)

    ; Monitor-Details loggen
    _LogMonitorInfo()

    ; Setze initialen Monitor
    If $g_iLastMonitor > $aMonitors[0][0] Then
        $g_iLastMonitor = 1
    EndIf
    $g_iCurrentScreenNumber = $g_iLastMonitor

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

    ; Tray-Icon Tooltip mit korrekter Display-Nummer
    Local $sTooltip = "GUI Slider - Monitor " & $g_iCurrentScreenNumber
    If UBound($g_aMonitorDetails) > $g_iCurrentScreenNumber And UBound($g_aMonitorDetails, 2) >= 6 Then
        Local $iDisplayNum = _ExtractDisplayNumber($g_aMonitorDetails[$g_iCurrentScreenNumber][0])
        If $iDisplayNum <> 999 Then
            $sTooltip = "GUI Slider - Display " & $iDisplayNum
        EndIf
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
; Singleton-Funktion
; ==========================================
Func _Singleton($sOccurrenceName, $iFlag = 0)
    Local Const $ERROR_ALREADY_EXISTS = 183
    Local $hMutex = DllCall("kernel32.dll", "handle", "CreateMutexW", _
                            "struct*", 0, "bool", 1, "wstr", $sOccurrenceName)

    If @error Then Return SetError(@error, 0, 0)

    Local $iError = DllCall("kernel32.dll", "dword", "GetLastError")[0]
    If $iError = $ERROR_ALREADY_EXISTS Then
        DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hMutex[0])
        If $iFlag Then Exit -1
        Return 0
    EndIf

    Return $hMutex[0]
EndFunc

; ==========================================
; Cleanup beim Beenden
; ==========================================
Func _Cleanup()
    _LogInfo("Beende Programm...")
    
    ; Speichere aktuelle Position
    _SaveConfig()
    
    ; Deaktiviere Auto-Slide-In
    AdlibUnRegister("_CheckAutoSlideIn")
    
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
