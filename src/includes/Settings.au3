#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.16.1
 Module: Settings Management
 Description: Zentrale Verwaltung aller Einstellungen für GUI-Slider-MultiMonitor
#ce ----------------------------------------------------------------------------

#include-once

; ==========================================
; Einstellungskonstanten
; ==========================================

; Animation Einstellungen
Global Const $SETTING_ANIMATION_SPEED_MIN = 5
Global Const $SETTING_ANIMATION_SPEED_MAX = 50
Global Const $SETTING_ANIMATION_SPEED_DEFAULT = 20

; Auto-Slide Einstellungen
Global Const $SETTING_AUTOSLIDE_DELAY_OUT_MIN = 100
Global Const $SETTING_AUTOSLIDE_DELAY_OUT_MAX = 5000
Global Const $SETTING_AUTOSLIDE_DELAY_OUT_DEFAULT = 750

Global Const $SETTING_AUTOSLIDE_DELAY_IN_MIN = 50
Global Const $SETTING_AUTOSLIDE_DELAY_IN_MAX = 2000
Global Const $SETTING_AUTOSLIDE_DELAY_IN_DEFAULT = 250

Global Const $SETTING_AUTOSLIDE_EDGE_SIZE_MIN = 1
Global Const $SETTING_AUTOSLIDE_EDGE_SIZE_MAX = 20
Global Const $SETTING_AUTOSLIDE_EDGE_SIZE_DEFAULT = 8

; Visualizer Einstellungen
Global Const $SETTING_VISUALIZER_UPDATE_INTERVAL = 100
Global Const $SETTING_VISUALIZER_WIDTH = 400
Global Const $SETTING_VISUALIZER_HEIGHT = 250

; ==========================================
; Einstellungs-Funktionen
; ==========================================

; Validiert eine Einstellung gegen Min/Max Werte
Func _ValidateSetting($iValue, $iMin, $iMax, $iDefault)
    If $iValue < $iMin Or $iValue > $iMax Then
        Return $iDefault
    EndIf
    Return $iValue
EndFunc

; Lädt Einstellungen aus INI-Datei
Func _LoadSettingsFromINI($sINIPath)
    If Not FileExists($sINIPath) Then
        Return False
    EndIf
    
    ; Animation
    Local $iSpeed = IniRead($sINIPath, "Animation", "Speed", $SETTING_ANIMATION_SPEED_DEFAULT)
    $g_iAnimationSpeed = _ValidateSetting($iSpeed, $SETTING_ANIMATION_SPEED_MIN, $SETTING_ANIMATION_SPEED_MAX, $SETTING_ANIMATION_SPEED_DEFAULT)
    
    ; Auto-Slide
    Local $bAutoSlide = IniRead($sINIPath, "AutoSlide", "Enabled", "True") = "True"
    Local $iDelayOut = IniRead($sINIPath, "AutoSlide", "DelayOut", $SETTING_AUTOSLIDE_DELAY_OUT_DEFAULT)
    Local $iDelayIn = IniRead($sINIPath, "AutoSlide", "DelayIn", $SETTING_AUTOSLIDE_DELAY_IN_DEFAULT)
    Local $iEdgeSize = IniRead($sINIPath, "AutoSlide", "EdgeSize", $SETTING_AUTOSLIDE_EDGE_SIZE_DEFAULT)
    
    $g_bAutoSlideActive = $bAutoSlide
    $g_iAutoSlideDelayOut = _ValidateSetting($iDelayOut, $SETTING_AUTOSLIDE_DELAY_OUT_MIN, $SETTING_AUTOSLIDE_DELAY_OUT_MAX, $SETTING_AUTOSLIDE_DELAY_OUT_DEFAULT)
    $g_iAutoSlideDelayIn = _ValidateSetting($iDelayIn, $SETTING_AUTOSLIDE_DELAY_IN_MIN, $SETTING_AUTOSLIDE_DELAY_IN_MAX, $SETTING_AUTOSLIDE_DELAY_IN_DEFAULT)
    $g_iAutoSlideVisibleEdge = _ValidateSetting($iEdgeSize, $SETTING_AUTOSLIDE_EDGE_SIZE_MIN, $SETTING_AUTOSLIDE_EDGE_SIZE_MAX, $SETTING_AUTOSLIDE_EDGE_SIZE_DEFAULT)
    
    ; Visualizer
    Local $bVisualizer = IniRead($sINIPath, "Visualizer", "Enabled", "True") = "True"
    $g_bVisualizerEnabled = $bVisualizer
    
    Return True
EndFunc

; Speichert Einstellungen in INI-Datei
Func _SaveSettingsToINI($sINIPath)
    ; Animation
    IniWrite($sINIPath, "Animation", "Speed", $g_iAnimationSpeed)
    
    ; Auto-Slide
    IniWrite($sINIPath, "AutoSlide", "Enabled", $g_bAutoSlideActive ? "True" : "False")
    IniWrite($sINIPath, "AutoSlide", "DelayOut", $g_iAutoSlideDelayOut)
    IniWrite($sINIPath, "AutoSlide", "DelayIn", $g_iAutoSlideDelayIn)
    IniWrite($sINIPath, "AutoSlide", "EdgeSize", $g_iAutoSlideVisibleEdge)
    
    ; Visualizer
    IniWrite($sINIPath, "Visualizer", "Enabled", $g_bVisualizerEnabled ? "True" : "False")
    
    Return True
EndFunc

; Setzt alle Einstellungen auf Standardwerte zurück
Func _ResetSettingsToDefaults()
    $g_iAnimationSpeed = $SETTING_ANIMATION_SPEED_DEFAULT
    $g_bAutoSlideActive = True
    $g_iAutoSlideDelayOut = $SETTING_AUTOSLIDE_DELAY_OUT_DEFAULT
    $g_iAutoSlideDelayIn = $SETTING_AUTOSLIDE_DELAY_IN_DEFAULT
    $g_iAutoSlideVisibleEdge = $SETTING_AUTOSLIDE_EDGE_SIZE_DEFAULT
    $g_bVisualizerEnabled = True
EndFunc