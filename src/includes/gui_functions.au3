#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         GUI-Slider-MultiMonitor Team
 Script Function: GUI-Erstellungs- und Verwaltungsfunktionen
 
 Datei: gui_functions.au3
 Beschreibung: Funktionen für GUI-Erstellung und -Verwaltung
#ce ----------------------------------------------------------------------------

#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GDIPlus.au3>
#include <StaticConstants.au3>
#include <ColorConstants.au3>
#include "globals.au3"

; ===============================================
; Funktion: _CreateMainGUI
; Beschreibung: Erstellt das Haupt-GUI
; Rückgabe: GUI Handle
; ===============================================
Func _CreateMainGUI()
    ; GUI erstellen
    $g_hMainGUI = GUICreate("GUI Slider MultiMonitor", _
                           $GUI_DEFAULT_WIDTH, $GUI_DEFAULT_HEIGHT, _
                           -1, -1, _
                           BitOR($WS_POPUP, $WS_BORDER), _
                           BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
    
    ; Hintergrundfarbe setzen
    GUISetBkColor(0x2B2B2B, $g_hMainGUI)
    
    ; Titel-Bereich
    Local $hTitleLabel = GUICtrlCreateLabel("GUI Slider", 10, 10, 280, 30, $SS_CENTER)
    GUICtrlSetFont($hTitleLabel, 14, 800, 0, "Segoe UI")
    GUICtrlSetColor($hTitleLabel, 0xFFFFFF)
    GUICtrlSetBkColor($hTitleLabel, $GUI_BKCOLOR_TRANSPARENT)
    
    ; Close Button
    Local $hCloseBtn = GUICtrlCreateLabel("✕", $GUI_DEFAULT_WIDTH - 30, 5, 25, 25, $SS_CENTER)
    GUICtrlSetFont($hCloseBtn, 12, 400, 0, "Segoe UI")
    GUICtrlSetColor($hCloseBtn, 0xFFFFFF)
    GUICtrlSetCursor($hCloseBtn, 0)
    
    ; Trennlinie
    GUICtrlCreateLabel("", 10, 45, 280, 1)
    GUICtrlSetBkColor(-1, 0x555555)
    
    ; Info-Bereich
    Local $hInfoGroup = GUICtrlCreateGroup("Monitor Information", 10, 60, 280, 120)
    GUICtrlSetColor($hInfoGroup, 0xFFFFFF)
    
    ; Monitor-Info Labels
    Global $g_hMonitorLabel = GUICtrlCreateLabel("Monitor: -", 20, 80, 260, 20)
    GUICtrlSetColor($g_hMonitorLabel, 0xDDDDDD)
    
    Global $g_hResolutionLabel = GUICtrlCreateLabel("Resolution: -", 20, 100, 260, 20)
    GUICtrlSetColor($g_hResolutionLabel, 0xDDDDDD)
    
    Global $g_hPositionLabel = GUICtrlCreateLabel("Position: -", 20, 120, 260, 20)
    GUICtrlSetColor($g_hPositionLabel, 0xDDDDDD)
    
    Global $g_hStatusLabel = GUICtrlCreateLabel("Status: -", 20, 140, 260, 20)
    GUICtrlSetColor($g_hStatusLabel, 0xDDDDDD)
    
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Gruppe schließen
    
    ; Control-Bereich
    Local $hControlGroup = GUICtrlCreateGroup("Controls", 10, 190, 280, 150)
    GUICtrlSetColor($hControlGroup, 0xFFFFFF)
    
    ; Richtungs-Buttons
    Global $g_hBtnUp = GUICtrlCreateButton("▲", 130, 210, 40, 30)
    Global $g_hBtnLeft = GUICtrlCreateButton("◄", 85, 245, 40, 30)
    Global $g_hBtnCenter = GUICtrlCreateButton("●", 130, 245, 40, 30)
    Global $g_hBtnRight = GUICtrlCreateButton("►", 175, 245, 40, 30)
    Global $g_hBtnDown = GUICtrlCreateButton("▼", 130, 280, 40, 30)
    
    ; Button-Styles
    _SetButtonStyle($g_hBtnUp)
    _SetButtonStyle($g_hBtnLeft)
    _SetButtonStyle($g_hBtnCenter)
    _SetButtonStyle($g_hBtnRight)
    _SetButtonStyle($g_hBtnDown)
    
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    
    ; Settings Button
    Global $g_hBtnSettings = GUICtrlCreateButton("⚙ Settings", 10, 350, 135, 35)
    _SetButtonStyle($g_hBtnSettings)
    
    ; About Button
    Global $g_hBtnAbout = GUICtrlCreateButton("ℹ About", 155, 350, 135, 35)
    _SetButtonStyle($g_hBtnAbout)
    
    ; GUI anzeigen
    GUISetState(@SW_SHOW, $g_hMainGUI)
    
    ; Event-IDs speichern
    Global $g_idCloseBtn = $hCloseBtn
    
    Return $g_hMainGUI
EndFunc

; ===============================================
; Funktion: _SetButtonStyle
; Beschreibung: Setzt einheitlichen Button-Style
; ===============================================
Func _SetButtonStyle($hButton)
    GUICtrlSetFont($hButton, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor($hButton, 0xFFFFFF)
    GUICtrlSetBkColor($hButton, 0x404040)
EndFunc

; ===============================================
; Funktion: _UpdateGUIInfo
; Beschreibung: Aktualisiert Info-Labels
; ===============================================
Func _UpdateGUIInfo()
    ; Monitor-Nummer
    GUICtrlSetData($g_hMonitorLabel, "Monitor: " & $g_iCurrentScreenNumber & " / " & $g_aMonitorInfo[0][0])
    
    ; Auflösung
    GUICtrlSetData($g_hResolutionLabel, "Resolution: " & $g_iCurrentScreenWidth & " x " & $g_iCurrentScreenHeight)
    
    ; Position
    GUICtrlSetData($g_hPositionLabel, "Position: (" & $g_iCurrentScreenX & ", " & $g_iCurrentScreenY & ")")
    
    ; Status
    Local $sStatus = "Status: "
    If $g_bWindowIsOut Then
        $sStatus &= "Out (" & $g_sWindowPosition & ")"
    Else
        $sStatus &= "In"
    EndIf
    GUICtrlSetData($g_hStatusLabel, $sStatus)
    
    ; Button-Status aktualisieren
    _UpdateButtonStates()
EndFunc

; ===============================================
; Funktion: _UpdateButtonStates
; Beschreibung: Aktiviert/Deaktiviert Buttons
; ===============================================
Func _UpdateButtonStates()
    ; Buttons basierend auf Bewegungsmöglichkeiten aktivieren/deaktivieren
    If $g_bCanMoveUp Or _FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Top") > 0 Then
        GUICtrlSetState($g_hBtnUp, $GUI_ENABLE)
    Else
        GUICtrlSetState($g_hBtnUp, $GUI_DISABLE)
    EndIf
    
    If $g_bCanMoveDown Or _FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Bottom") > 0 Then
        GUICtrlSetState($g_hBtnDown, $GUI_ENABLE)
    Else
        GUICtrlSetState($g_hBtnDown, $GUI_DISABLE)
    EndIf
    
    If $g_bCanMoveLeft Or _FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Left") > 0 Then
        GUICtrlSetState($g_hBtnLeft, $GUI_ENABLE)
    Else
        GUICtrlSetState($g_hBtnLeft, $GUI_DISABLE)
    EndIf
    
    If $g_bCanMoveRight Or _FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Right") > 0 Then
        GUICtrlSetState($g_hBtnRight, $GUI_ENABLE)
    Else
        GUICtrlSetState($g_hBtnRight, $GUI_DISABLE)
    EndIf
EndFunc

; ===============================================
; Funktion: _ShowSettingsDialog
; Beschreibung: Zeigt Einstellungs-Dialog
; ===============================================
Func _ShowSettingsDialog()
    Local $hSettingsGUI = GUICreate("Settings", 400, 300, -1, -1, _
                                   BitOR($WS_CAPTION, $WS_SYSMENU), _
                                   $WS_EX_TOPMOST, $g_hMainGUI)
    
    GUISetBkColor(0x2B2B2B, $hSettingsGUI)
    
    ; Titel
    GUICtrlCreateLabel("Settings", 10, 10, 380, 30, $SS_CENTER)
    GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0xFFFFFF)
    
    ; Animation Settings
    GUICtrlCreateGroup("Animation", 10, 50, 380, 80)
    GUICtrlSetColor(-1, 0xFFFFFF)
    
    GUICtrlCreateLabel("Animation Steps:", 20, 70, 100, 20)
    GUICtrlSetColor(-1, 0xDDDDDD)
    Local $hStepsInput = GUICtrlCreateInput($g_iAnimationSteps, 130, 68, 50, 20)
    
    GUICtrlCreateLabel("Animation Delay (ms):", 20, 95, 120, 20)
    GUICtrlSetColor(-1, 0xDDDDDD)
    Local $hDelayInput = GUICtrlCreateInput($g_iAnimationDelay, 150, 93, 50, 20)
    
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    
    ; General Settings
    GUICtrlCreateGroup("General", 10, 140, 380, 80)
    GUICtrlSetColor(-1, 0xFFFFFF)
    
    Local $hLoggingCheck = GUICtrlCreateCheckbox("Enable Logging", 20, 160, 150, 20)
    GUICtrlSetColor(-1, 0xDDDDDD)
    If $g_bEnableLogging Then GUICtrlSetState($hLoggingCheck, $GUI_CHECKED)
    
    GUICtrlCreateLabel("Monitor Tolerance (px):", 20, 185, 130, 20)
    GUICtrlSetColor(-1, 0xDDDDDD)
    Local $hToleranceInput = GUICtrlCreateInput($g_iMonitorTolerance, 155, 183, 50, 20)
    
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    
    ; Buttons
    Local $hOkBtn = GUICtrlCreateButton("OK", 140, 250, 80, 30)
    Local $hCancelBtn = GUICtrlCreateButton("Cancel", 230, 250, 80, 30)
    
    GUISetState(@SW_SHOW, $hSettingsGUI)
    
    ; Event Loop
    While 1
        Local $nMsg = GUIGetMsg()
        Switch $nMsg
            Case $GUI_EVENT_CLOSE, $hCancelBtn
                ExitLoop
                
            Case $hOkBtn
                ; Einstellungen speichern
                $g_iAnimationSteps = Int(GUICtrlRead($hStepsInput))
                $g_iAnimationDelay = Int(GUICtrlRead($hDelayInput))
                $g_bEnableLogging = (GUICtrlRead($hLoggingCheck) = $GUI_CHECKED)
                $g_iMonitorTolerance = Int(GUICtrlRead($hToleranceInput))
                
                ; In INI speichern
                IniWrite($g_sConfigFile, "Animation", "Steps", $g_iAnimationSteps)
                IniWrite($g_sConfigFile, "Animation", "Delay", $g_iAnimationDelay)
                IniWrite($g_sConfigFile, "General", "EnableLogging", $g_bEnableLogging)
                IniWrite($g_sConfigFile, "General", "MonitorTolerance", $g_iMonitorTolerance)
                
                ExitLoop
        EndSwitch
    WEnd
    
    GUIDelete($hSettingsGUI)
EndFunc

; ===============================================
; Funktion: _ShowAboutDialog
; Beschreibung: Zeigt About-Dialog
; ===============================================
Func _ShowAboutDialog()
    Local $hAboutGUI = GUICreate("About", 350, 250, -1, -1, _
                                BitOR($WS_CAPTION, $WS_SYSMENU), _
                                $WS_EX_TOPMOST, $g_hMainGUI)
    
    GUISetBkColor(0x2B2B2B, $hAboutGUI)
    
    ; Logo/Titel
    GUICtrlCreateLabel("GUI Slider MultiMonitor", 10, 20, 330, 30, $SS_CENTER)
    GUICtrlSetFont(-1, 16, 800, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0xFFFFFF)
    
    ; Version
    GUICtrlCreateLabel("Version 1.0.0", 10, 55, 330, 20, $SS_CENTER)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0xAAAAAA)
    
    ; Beschreibung
    GUICtrlCreateLabel("A dynamic GUI system for multi-monitor setups" & @CRLF & _
                      "with intelligent slider functionality.", _
                      20, 90, 310, 40, $SS_CENTER)
    GUICtrlSetColor(-1, 0xDDDDDD)
    
    ; Info
    GUICtrlCreateLabel("Developed with AutoIt v3", 10, 140, 330, 20, $SS_CENTER)
    GUICtrlSetColor(-1, 0xAAAAAA)
    
    ; GitHub Link
    GUICtrlCreateLabel("github.com/yourusername/gui-slider-multimonitor", _
                      10, 160, 330, 20, $SS_CENTER)
    GUICtrlSetColor(-1, 0x4A90E2)
    GUICtrlSetCursor(-1, 0)
    
    ; OK Button
    Local $hOkBtn = GUICtrlCreateButton("OK", 135, 200, 80, 30)
    
    GUISetState(@SW_SHOW, $hAboutGUI)
    
    While 1
        Local $nMsg = GUIGetMsg()
        Switch $nMsg
            Case $GUI_EVENT_CLOSE, $hOkBtn
                ExitLoop
        EndSwitch
    WEnd
    
    GUIDelete($hAboutGUI)
EndFunc

; ===============================================
; Funktion: _CreateTrayMenu
; Beschreibung: Erstellt Tray-Menü
; ===============================================
Func _CreateTrayMenu()
    Opt("TrayMenuMode", 3) ; Default Tray-Menü-Items entfernen
    
    ; Tray-Icon setzen
    TraySetIcon(@ScriptFullPath, -1)
    TraySetToolTip("GUI Slider MultiMonitor")
    
    ; Menü-Items
    Global $g_idTrayShow = TrayCreateItem("Show/Hide")
    TrayCreateItem("")
    Global $g_idTraySettings = TrayCreateItem("Settings")
    Global $g_idTrayAbout = TrayCreateItem("About")
    TrayCreateItem("")
    Global $g_idTrayExit = TrayCreateItem("Exit")
    
    TraySetState($TRAY_ICONSTATE_SHOW)
EndFunc

; ===============================================
; Funktion: _ShowMonitorVisualization
; Beschreibung: Zeigt visuelle Monitor-Übersicht
; ===============================================
Func _ShowMonitorVisualization()
    ; GDI+ initialisieren
    _GDIPlus_Startup()
    
    Local $hVisuGUI = GUICreate("Monitor Layout", 600, 400, -1, -1)
    GUISetBkColor(0x202020, $hVisuGUI)
    
    ; Graphics erstellen
    Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hVisuGUI)
    Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics(600, 400, $hGraphics)
    Local $hBackbuffer = _GDIPlus_ImageGetGraphicsContext($hBitmap)
    
    ; Anti-Aliasing
    _GDIPlus_GraphicsSetSmoothingMode($hBackbuffer, 2)
    
    GUISetState(@SW_SHOW, $hVisuGUI)
    
    ; Zeichnen
    _DrawMonitorLayout($hBackbuffer)
    _GDIPlus_GraphicsDrawImage($hGraphics, $hBitmap, 0, 0)
    
    ; Event Loop
    While 1
        Local $nMsg = GUIGetMsg()
        If $nMsg = $GUI_EVENT_CLOSE Then ExitLoop
    WEnd
    
    ; Aufräumen
    _GDIPlus_GraphicsDispose($hBackbuffer)
    _GDIPlus_BitmapDispose($hBitmap)
    _GDIPlus_GraphicsDispose($hGraphics)
    _GDIPlus_Shutdown()
    
    GUIDelete($hVisuGUI)
EndFunc

; ===============================================
; Funktion: _DrawMonitorLayout
; Beschreibung: Zeichnet Monitor-Layout
; ===============================================
Func _DrawMonitorLayout($hGraphics)
    ; Hintergrund löschen
    Local $hBrushBg = _GDIPlus_BrushCreateSolid(0xFF202020)
    _GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 600, 400, $hBrushBg)
    
    ; Skalierung berechnen
    Local $iMinX = 999999, $iMinY = 999999
    Local $iMaxX = -999999, $iMaxY = -999999
    
    For $i = 1 To $g_aMonitorInfo[0][0]
        If $g_aMonitorInfo[$i][2] < $iMinX Then $iMinX = $g_aMonitorInfo[$i][2]
        If $g_aMonitorInfo[$i][3] < $iMinY Then $iMinY = $g_aMonitorInfo[$i][3]
        If $g_aMonitorInfo[$i][2] + $g_aMonitorInfo[$i][0] > $iMaxX Then 
            $iMaxX = $g_aMonitorInfo[$i][2] + $g_aMonitorInfo[$i][0]
        EndIf
        If $g_aMonitorInfo[$i][3] + $g_aMonitorInfo[$i][1] > $iMaxY Then 
            $iMaxY = $g_aMonitorInfo[$i][3] + $g_aMonitorInfo[$i][1]
        EndIf
    Next
    
    Local $fScaleX = 500 / ($iMaxX - $iMinX)
    Local $fScaleY = 300 / ($iMaxY - $iMinY)
    Local $fScale = ($fScaleX < $fScaleY) ? $fScaleX : $fScaleY
    
    ; Monitore zeichnen
    Local $hPen = _GDIPlus_PenCreate(0xFF4A90E2, 2)
    Local $hBrush = _GDIPlus_BrushCreateSolid(0x804A90E2)
    Local $hBrushActive = _GDIPlus_BrushCreateSolid(0x8090E24A)
    Local $hFont = _GDIPlus_FontCreate(_GDIPlus_FontFamilyCreate("Arial"), 12)
    Local $hStringFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hStringFormat, 1)
    
    For $i = 1 To $g_aMonitorInfo[0][0]
        Local $iX = 50 + ($g_aMonitorInfo[$i][2] - $iMinX) * $fScale
        Local $iY = 50 + ($g_aMonitorInfo[$i][3] - $iMinY) * $fScale
        Local $iW = $g_aMonitorInfo[$i][0] * $fScale
        Local $iH = $g_aMonitorInfo[$i][1] * $fScale
        
        ; Monitor zeichnen
        If $i = $g_iCurrentScreenNumber Then
            _GDIPlus_GraphicsFillRect($hGraphics, $iX, $iY, $iW, $iH, $hBrushActive)
        Else
            _GDIPlus_GraphicsFillRect($hGraphics, $iX, $iY, $iW, $iH, $hBrush)
        EndIf
        _GDIPlus_GraphicsDrawRect($hGraphics, $iX, $iY, $iW, $iH, $hPen)
        
        ; Monitor-Nummer
        Local $tLayout = _GDIPlus_RectFCreate($iX, $iY + $iH/2 - 10, $iW, 20)
        _GDIPlus_GraphicsDrawStringEx($hGraphics, String($i), $hFont, $tLayout, _
                                     $hStringFormat, _GDIPlus_BrushCreateSolid(0xFFFFFFFF))
    Next
    
    ; Aufräumen
    _GDIPlus_PenDispose($hPen)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_BrushDispose($hBrushActive)
    _GDIPlus_BrushDispose($hBrushBg)
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_StringFormatDispose($hStringFormat)
EndFunc
