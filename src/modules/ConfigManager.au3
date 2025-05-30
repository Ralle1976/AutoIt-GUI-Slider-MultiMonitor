#include-once
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"

; ==========================================
; Configuration Manager Module
; ==========================================

; Lädt die Konfiguration aus der INI-Datei
Func _LoadConfig()
    ; Prüfe ob Konfigurationsdatei existiert
    If Not FileExists($g_sConfigFile) Then
        ; Erstelle Standard-Konfiguration
        _CreateDefaultConfig()
    EndIf
    
    ; Lade allgemeine Einstellungen
    $g_sLastPosition = IniRead($g_sConfigFile, "General", "LastPosition", $POS_CENTER)
    $g_iLastMonitor = Int(IniRead($g_sConfigFile, "General", "LastMonitor", 1))
    $g_iCurrentScreenNumber = $g_iLastMonitor  ; Setze aktuellen Monitor auf letzten bekannten Monitor
    
    ; Lade Animations-Einstellungen
    Local $iSpeed = Int(IniRead($g_sConfigFile, "Animation", "AnimationSpeed", 20))
    Local $iSteps = Int(IniRead($g_sConfigFile, "Animation", "SlideSteps", 10))
    
    ; Validiere und setze Werte
    If $iSpeed >= $ANIM_MIN_SPEED And $iSpeed <= $ANIM_MAX_SPEED Then
        $g_iAnimationSpeed = $iSpeed
    Else
        $g_iAnimationSpeed = 20
    EndIf
    
    If $iSteps >= $ANIM_MIN_STEPS And $iSteps <= $ANIM_MAX_STEPS Then
        $g_iSlideSteps = $iSteps
    Else
        $g_iSlideSteps = 10
    EndIf
    
    ; Lade GUI-Einstellungen
    Local $iWidth = Int(IniRead($g_sConfigFile, "GUI", "DefaultWidth", $GUI_DEFAULT_WIDTH))
    Local $iHeight = Int(IniRead($g_sConfigFile, "GUI", "DefaultHeight", $GUI_DEFAULT_HEIGHT))
    
    ; Validiere GUI-Größe
    $g_iGUIWidth = _Clamp($iWidth, $GUI_MIN_WIDTH, $GUI_MAX_WIDTH)
    $g_iGUIHeight = _Clamp($iHeight, $GUI_MIN_HEIGHT, $GUI_MAX_HEIGHT)
    
    Return True
EndFunc

; Speichert die aktuelle Konfiguration
Func _SaveConfig()
    ; Speichere allgemeine Einstellungen
    IniWrite($g_sConfigFile, "General", "LastPosition", $g_sWindowIsAt)
    IniWrite($g_sConfigFile, "General", "LastMonitor", $g_iCurrentScreenNumber)
    If $g_bWindowIsOut Then
        IniWrite($g_sConfigFile, "General", "LastWindowState", "Out")
    Else
        IniWrite($g_sConfigFile, "General", "LastWindowState", "In")
    EndIf
    
    ; Speichere Animations-Einstellungen
    IniWrite($g_sConfigFile, "Animation", "AnimationSpeed", $g_iAnimationSpeed)
    IniWrite($g_sConfigFile, "Animation", "SlideSteps", $g_iSlideSteps)
    
    ; Speichere GUI-Einstellungen (falls geändert)
    If IsHWnd($g_hMainGUI) Then
        Local $aPos = WinGetPos($g_hMainGUI)
        If IsArray($aPos) Then
            IniWrite($g_sConfigFile, "GUI", "LastWidth", $aPos[2])
            IniWrite($g_sConfigFile, "GUI", "LastHeight", $aPos[3])
        EndIf
    EndIf
    
    Return True
EndFunc

; Erstellt eine Standard-Konfigurationsdatei
Func _CreateDefaultConfig()
    ; Erstelle Verzeichnis falls nicht vorhanden
    Local $sConfigDir = StringLeft($g_sConfigFile, StringInStr($g_sConfigFile, "\", 0, -1) - 1)
    If Not FileExists($sConfigDir) Then DirCreate($sConfigDir)
    
    ; Schreibe Standard-Konfiguration
    ; General Section
    IniWrite($g_sConfigFile, "General", "LastPosition", "Center")
    IniWrite($g_sConfigFile, "General", "LastMonitor", "1")
    IniWrite($g_sConfigFile, "General", "LastWindowState", "Normal")
    
    ; Animation Section
    IniWrite($g_sConfigFile, "Animation", "AnimationSpeed", "20")
    IniWrite($g_sConfigFile, "Animation", "SlideSteps", "10")
    
    ; GUI Section
    IniWrite($g_sConfigFile, "GUI", "DefaultWidth", String($GUI_DEFAULT_WIDTH))
    IniWrite($g_sConfigFile, "GUI", "DefaultHeight", String($GUI_DEFAULT_HEIGHT))
    IniWrite($g_sConfigFile, "GUI", "MinWidth", String($GUI_MIN_WIDTH))
    IniWrite($g_sConfigFile, "GUI", "MinHeight", String($GUI_MIN_HEIGHT))
    IniWrite($g_sConfigFile, "GUI", "MaxWidth", String($GUI_MAX_WIDTH))
    IniWrite($g_sConfigFile, "GUI", "MaxHeight", String($GUI_MAX_HEIGHT))
    
    ; Behavior Section
    IniWrite($g_sConfigFile, "Behavior", "StartOnPrimaryMonitor", "1")
    IniWrite($g_sConfigFile, "Behavior", "CenterOnStart", "1")
    IniWrite($g_sConfigFile, "Behavior", "AnimateOnStart", "0")
    IniWrite($g_sConfigFile, "Behavior", "SavePositionOnExit", "1")
    IniWrite($g_sConfigFile, "Behavior", "AutoSlideIn", "0")
    IniWrite($g_sConfigFile, "Behavior", "AutoSlideInDelay", "250")
    IniWrite($g_sConfigFile, "Behavior", "ClassicSliderMode", "0")
    IniWrite($g_sConfigFile, "Behavior", "DirectSlideMode", "0")
    IniWrite($g_sConfigFile, "Behavior", "ContinuousSlideMode", "0")
    
    ; Hotkeys Section
    IniWrite($g_sConfigFile, "Hotkeys", "SlideLeft", "!{Left}")
    IniWrite($g_sConfigFile, "Hotkeys", "SlideRight", "!{Right}")
    IniWrite($g_sConfigFile, "Hotkeys", "SlideUp", "!{Up}")
    IniWrite($g_sConfigFile, "Hotkeys", "SlideDown", "!{Down}")
    IniWrite($g_sConfigFile, "Hotkeys", "ToggleSlide", "!{Space}")
    IniWrite($g_sConfigFile, "Hotkeys", "CenterWindow", "!{Home}")
    IniWrite($g_sConfigFile, "Hotkeys", "RecoverWindow", "!{End}")
    
    Return True
EndFunc

; Liest einen Wert aus der Konfiguration
Func _GetConfigValue($sSection, $sKey, $sDefault = "")
    Return IniRead($g_sConfigFile, $sSection, $sKey, $sDefault)
EndFunc

; Schreibt einen Wert in die Konfiguration
Func _SetConfigValue($sSection, $sKey, $sValue)
    Return IniWrite($g_sConfigFile, $sSection, $sKey, $sValue)
EndFunc

; Liest die Hotkey-Konfiguration
Func _GetHotkeys()
    Local $aHotkeys[7][2] = [ _
        ["SlideLeft", IniRead($g_sConfigFile, "Hotkeys", "SlideLeft", "!{Left}")], _
        ["SlideRight", IniRead($g_sConfigFile, "Hotkeys", "SlideRight", "!{Right}")], _
        ["SlideUp", IniRead($g_sConfigFile, "Hotkeys", "SlideUp", "!{Up}")], _
        ["SlideDown", IniRead($g_sConfigFile, "Hotkeys", "SlideDown", "!{Down}")], _
        ["ToggleSlide", IniRead($g_sConfigFile, "Hotkeys", "ToggleSlide", "!{Space}")], _
        ["CenterWindow", IniRead($g_sConfigFile, "Hotkeys", "CenterWindow", "!{Home}")], _
        ["RecoverWindow", IniRead($g_sConfigFile, "Hotkeys", "RecoverWindow", "!{End}")] _
    ]
    
    Return $aHotkeys
EndFunc

; Liest Verhaltens-Einstellungen
Func _GetBehaviorSettings()
    Local $aSettings[9][2] = [ _
        ["StartOnPrimaryMonitor", IniRead($g_sConfigFile, "Behavior", "StartOnPrimaryMonitor", "1") = "1"], _
        ["CenterOnStart", IniRead($g_sConfigFile, "Behavior", "CenterOnStart", "1") = "1"], _
        ["AnimateOnStart", IniRead($g_sConfigFile, "Behavior", "AnimateOnStart", "0") = "1"], _
        ["SavePositionOnExit", IniRead($g_sConfigFile, "Behavior", "SavePositionOnExit", "1") = "1"], _
        ["AutoSlideIn", IniRead($g_sConfigFile, "Behavior", "AutoSlideIn", "0") = "1"], _
        ["AutoSlideInDelay", Int(IniRead($g_sConfigFile, "Behavior", "AutoSlideInDelay", "250"))], _
        ["ClassicSliderMode", IniRead($g_sConfigFile, "Behavior", "ClassicSliderMode", "0") = "1"], _
        ["DirectSlideMode", IniRead($g_sConfigFile, "Behavior", "DirectSlideMode", "0") = "1"], _
        ["ContinuousSlideMode", IniRead($g_sConfigFile, "Behavior", "ContinuousSlideMode", "0") = "1"] _
    ]
    
    Return $aSettings
EndFunc

; Hilfsfunktion: Begrenzt einen Wert zwischen Min und Max
Func _Clamp($iValue, $iMin, $iMax)
    If $iValue < $iMin Then Return $iMin
    If $iValue > $iMax Then Return $iMax
    Return $iValue
EndFunc

; Validiert die Konfiguration
Func _ValidateConfig()
    Local $bValid = True
    
    ; Prüfe ob Konfigurationsdatei lesbar ist
    If Not FileExists($g_sConfigFile) Then
        ConsoleWrite("Konfigurationsdatei nicht gefunden: " & $g_sConfigFile & @CRLF)
        Return False
    EndIf
    
    ; Prüfe kritische Werte
    Local $iMonitorCount = _GetConfigValue("General", "LastMonitor", "1")
    If Int($iMonitorCount) < 1 Then
        _SetConfigValue("General", "LastMonitor", "1")
        $bValid = False
    EndIf
    
    ; Prüfe Animationswerte
    Local $iSpeed = Int(_GetConfigValue("Animation", "AnimationSpeed", "20"))
    If $iSpeed < $ANIM_MIN_SPEED Or $iSpeed > $ANIM_MAX_SPEED Then
        _SetConfigValue("Animation", "AnimationSpeed", "20")
        $bValid = False
    EndIf
    
    Return $bValid
EndFunc

; Exportiert die Konfiguration (für Backup)
Func _ExportConfig($sExportFile)
    Return FileCopy($g_sConfigFile, $sExportFile, 1)
EndFunc

; Importiert eine Konfiguration
Func _ImportConfig($sImportFile)
    If Not FileExists($sImportFile) Then Return False
    
    ; Backup aktuelle Konfiguration
    _ExportConfig($g_sConfigFile & ".backup")
    
    ; Importiere neue Konfiguration
    Local $bResult = FileCopy($sImportFile, $g_sConfigFile, 1)
    
    ; Validiere importierte Konfiguration
    If $bResult Then
        If Not _ValidateConfig() Then
            ; Restore backup bei Fehler
            FileCopy($g_sConfigFile & ".backup", $g_sConfigFile, 1)
            Return False
        EndIf
    EndIf
    
    Return $bResult
EndFunc

; Reset auf Standard-Konfiguration
Func _ResetConfig()
    ; Backup aktuelle Konfiguration
    _ExportConfig($g_sConfigFile & ".backup")
    
    ; Lösche aktuelle Konfiguration
    FileDelete($g_sConfigFile)
    
    ; Erstelle neue Standard-Konfiguration
    _CreateDefaultConfig()
    
    ; Lade neue Konfiguration
    _LoadConfig()
    
    Return True
EndFunc
