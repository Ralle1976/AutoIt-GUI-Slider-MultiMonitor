#include-once

; ==========================================
; Settings Include File
; ==========================================

; Diese Datei dient als zentrale Stelle für Einstellungen,
; die zur Compile-Zeit festgelegt werden

; Debug-Modus
Global Const $DEBUG_MODE = False

; Versions-Information
Global Const $APP_VERSION = "1.0.0"
Global Const $APP_NAME = "GUI-Slider Multi-Monitor"
Global Const $APP_AUTHOR = "Multi-Monitor Slider Project"

; Standard-Pfade
Global Const $DEFAULT_CONFIG_PATH = @ScriptDir & "\config"
Global Const $DEFAULT_BACKUP_PATH = @ScriptDir & "\backup"
Global Const $DEFAULT_LOG_PATH = @ScriptDir & "\logs"

; Feature-Flags
Global Const $FEATURE_MULTI_MONITOR_TRANSITION = True
Global Const $FEATURE_ANIMATION_EFFECTS = True
Global Const $FEATURE_HOTKEY_SUPPORT = True
Global Const $FEATURE_TRAY_MENU = True
Global Const $FEATURE_AUTO_SAVE = True

; Performance-Einstellungen
Global Const $PERFORMANCE_HIGH_PRIORITY = False
Global Const $PERFORMANCE_GPU_ACCELERATION = False

; Erweiterte Einstellungen
Global Const $ADVANCED_EDGE_DETECTION = True
Global Const $ADVANCED_SMOOTH_ANIMATION = True
Global Const $ADVANCED_MONITOR_MAPPING = True

; Logging-Einstellungen
Global Const $LOG_ENABLED = $DEBUG_MODE
Global Const $LOG_LEVEL = "INFO"  ; ERROR, WARNING, INFO, DEBUG
Global Const $LOG_TO_FILE = False
Global Const $LOG_TO_CONSOLE = True

; Validierungs-Einstellungen
Global Const $VALIDATE_MONITOR_BOUNDS = True
Global Const $VALIDATE_ANIMATION_PARAMS = True

; UI-Einstellungen
Global Const $UI_THEME = "Dark"  ; Dark, Light, Auto
Global Const $UI_TRANSPARENCY = False
Global Const $UI_SHADOW_EFFECTS = False

; Kompatibilitäts-Einstellungen
Global Const $COMPAT_WIN7 = True
Global Const $COMPAT_MULTI_DPI = True
Global Const $COMPAT_VIRTUAL_DESKTOP = False
