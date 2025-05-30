#include-once

; ==========================================
; Konstanten für GUI-Slider
; ==========================================

#Region Constants - Window Positions
Global Const $POS_TOP = "Top"
Global Const $POS_BOTTOM = "Bottom"
Global Const $POS_LEFT = "Left"
Global Const $POS_RIGHT = "Right"
Global Const $POS_CENTER = "Center"
#EndRegion Constants - Window Positions

#Region Constants - Animation
Global Const $ANIM_IN = "In"
Global Const $ANIM_OUT = "Out"
Global Const $ANIM_MIN_SPEED = 10
Global Const $ANIM_MAX_SPEED = 100
Global Const $ANIM_MIN_STEPS = 5
Global Const $ANIM_MAX_STEPS = 50
#EndRegion Constants - Animation

#Region Constants - Monitor Detection
Global Const $MAX_MONITORS = 12          ; Maximale Anzahl unterstützter Monitore
Global Const $MONITOR_PRIMARY = 0x00000001
;~ Global Const $MONITOR_DEFAULTTONEAREST = 0x00000002
;~ Global Const $MONITOR_DEFAULTTONULL = 0x00000000
;~ Global Const $MONITOR_DEFAULTTOPRIMARY = 0x00000001
#EndRegion Constants - Monitor Detection

#Region Constants - GUI Defaults
Global Const $GUI_MIN_WIDTH = 200
Global Const $GUI_MIN_HEIGHT = 150
Global Const $GUI_MAX_WIDTH = 1920
Global Const $GUI_MAX_HEIGHT = 1080
Global Const $GUI_DEFAULT_WIDTH = 400
Global Const $GUI_DEFAULT_HEIGHT = 300
#EndRegion Constants - GUI Defaults

#Region Constants - Error Codes
Global Const $ERR_SUCCESS = 0
Global Const $ERR_NO_MONITORS = -1
Global Const $ERR_INVALID_MONITOR = -2
Global Const $ERR_ANIMATION_ACTIVE = -3
Global Const $ERR_CONFIG_NOT_FOUND = -4
#EndRegion Constants - Error Codes
