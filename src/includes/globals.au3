#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         GUI-Slider-MultiMonitor Team
 Script Function: Globale Variablen für das GUI-Slider-System
 
 Datei: globals.au3
 Beschreibung: Zentrale Definition aller globalen Variablen
#ce ----------------------------------------------------------------------------

#include-once

; ===== GUI Status Variablen =====
Global $g_bWindowIsOut = False          ; Status: GUI ausgefahren (True) oder eingefahren (False)
Global $g_sWindowPosition = "Top"       ; Aktuelle Position: "Top", "Bottom", "Left", "Right"
Global $g_hMainGUI = 0                  ; Handle des Haupt-GUI-Fensters

; ===== Monitor Informationen =====
Global $g_iCurrentScreenX = 0           ; X-Position des aktuellen Monitors
Global $g_iCurrentScreenY = 0           ; Y-Position des aktuellen Monitors
Global $g_iCurrentScreenWidth = 0       ; Breite des aktuellen Monitors
Global $g_iCurrentScreenHeight = 0      ; Höhe des aktuellen Monitors
Global $g_iCurrentScreenNumber = 1      ; Nummer des aktuellen Monitors (1-basiert)
Global $g_aMonitorInfo[1][4]           ; Array mit allen Monitor-Informationen

; ===== Animations-Einstellungen =====
Global $g_iAnimationSteps = 10          ; Anzahl der Animationsschritte
Global $g_iAnimationDelay = 20          ; Verzögerung zwischen Schritten (ms)
Global $g_bAnimationInProgress = False  ; Flag für laufende Animation

; ===== Bewegungs-Steuerung =====
Global $g_sSlideDirection = ""          ; Aktuelle Bewegungsrichtung
Global $g_bCanMoveLeft = True           ; Bewegung nach links möglich
Global $g_bCanMoveRight = True          ; Bewegung nach rechts möglich
Global $g_bCanMoveUp = True             ; Bewegung nach oben möglich
Global $g_bCanMoveDown = True           ; Bewegung nach unten möglich

; ===== Konfiguration =====
Global $g_sConfigFile = @ScriptDir & "\config\settings.ini"
Global $g_iMonitorTolerance = 5         ; Toleranz für Monitor-Ausrichtung (Pixel)
Global $g_bEnableLogging = False        ; Logging aktiviert
Global $g_sLogLevel = "INFO"            ; Log-Level: DEBUG, INFO, WARN, ERROR

; ===== Hotkeys =====
Global $g_sHotkeySlideLeft = "^{LEFT}"  ; Strg+Links
Global $g_sHotkeySlideRight = "^{RIGHT}" ; Strg+Rechts
Global $g_sHotkeySlideUp = "^{UP}"      ; Strg+Hoch
Global $g_sHotkeySlideDown = "^{DOWN}"  ; Strg+Runter
Global $g_sHotkeyToggle = "^{SPACE}"    ; Strg+Leertaste

; ===== System =====
Global $g_nMsg = 0                      ; GUI Message Variable
Global $g_bExitRequested = False        ; Programm-Beendigungs-Flag
Global $g_iLastError = 0                ; Letzter Fehlercode
Global $g_sLastErrorMsg = ""            ; Letzte Fehlermeldung

; ===== GUI Dimensionen =====
Global Const $GUI_DEFAULT_WIDTH = 300   ; Standard GUI-Breite
Global Const $GUI_DEFAULT_HEIGHT = 400  ; Standard GUI-Höhe
Global Const $GUI_MIN_WIDTH = 200       ; Minimale GUI-Breite
Global Const $GUI_MIN_HEIGHT = 300      ; Minimale GUI-Höhe

; ===== DLL Handles =====
Global $g_hUser32DLL = 0               ; Handle für User32.dll
Global $g_hGDIPlusDLL = 0              ; Handle für GDIPlus.dll

; ===== Callback Handles =====
Global $g_hMonitorEnumCallback = 0      ; Callback für Monitor-Enumeration

; ===== Timer =====
Global $g_hAnimationTimer = 0           ; Timer für Animationen
Global $g_hMonitorCheckTimer = 0        ; Timer für Monitor-Änderungen

; ===== Debug =====
Global Const $DEBUG_MODE = (@Compiled = 0) ; Debug-Modus wenn nicht kompiliert
