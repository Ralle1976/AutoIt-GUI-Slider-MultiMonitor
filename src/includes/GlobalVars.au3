#include-once

; ==========================================
; Globale Variablen für GUI-Slider
; ==========================================

#Region Global Variables - Slider Core
Global $g_nMsg                           ; Message handler
Global $g_bWindowIsOut = False           ; Status: Fenster ausgefahren
Global $g_sWindowIsAt = "Top"            ; Position des Fensters
Global $g_iCurScreenX                    ; Aktuelle Screen X-Position
Global $g_iCurScreenY                    ; Aktuelle Screen Y-Position
Global $g_iCurScreenWidth                ; Aktuelle Screen Breite
Global $g_iCurScreenHeight               ; Aktuelle Screen Höhe
Global $g_iCurrentScreenNumber = 1       ; Aktuelle Monitor-Nummer
Global $g_sSwitchSide = "Top"            ; Seite für den Wechsel
#EndRegion Global Variables - Slider Core

#Region Global Variables - Monitor Management
Global $g_aMonitors[1][4]                ; Array mit Monitor-Informationen
Global $g_iMonitorCount = 0              ; Anzahl der erkannten Monitore
Global $g_hMainGUI                       ; Handle des Haupt-GUI
Global $g_iGUIWidth = 400                ; GUI Breite (Standard)
Global $g_iGUIHeight = 300               ; GUI Höhe (Standard)
#EndRegion Global Variables - Monitor Management

#Region Global Variables - Animation
Global $g_iAnimationSpeed = 20           ; Animationsgeschwindigkeit (ms)
Global $g_iSlideSteps = 10               ; Anzahl der Animationsschritte
Global $g_bIsAnimating = False           ; Animation läuft gerade
#EndRegion Global Variables - Animation

#Region Global Variables - Configuration
Global $g_sConfigFile = @ScriptDir & "\config\settings.ini"
Global $g_sLastPosition = "Center"       ; Letzte gespeicherte Position
Global $g_iLastMonitor = 1               ; Letzter verwendeter Monitor
#EndRegion Global Variables - Configuration

#Region Global Variables - GUI Controls
Global $g_idLblMonitorInfo               ; Label für Monitor-Information
Global $g_idLblStatus                    ; Status-Label
Global $g_idBtnLeft                      ; Button Links
Global $g_idBtnRight                     ; Button Rechts
Global $g_idBtnUp                        ; Button Oben
Global $g_idBtnDown                      ; Button Unten
Global $g_idBtnCenter                    ; Button Zentrieren
#EndRegion Global Variables - GUI Controls
