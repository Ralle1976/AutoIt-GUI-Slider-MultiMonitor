#include-once
#include <File.au3>
#include <Date.au3>
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"

; ==========================================
; Logging Module für GUI-Slider
; ==========================================
; Log-Level Konstanten (falls nicht in Constants.au3)
If Not IsDeclared("LOG_ERROR") Then
    Global Const $LOG_ERROR = 0
    Global Const $LOG_WARNING = 1
    Global Const $LOG_INFO = 2
    Global Const $LOG_DEBUG = 3
EndIf

Global $g_hLogFile = -1
Global $g_sLogFilePath = @ScriptDir & "\logs\gui-slider.log"
Global $g_iLogLevel = $LOG_INFO
Global $g_iMaxLogSize = 5 * 1024 * 1024  ; 5 MB
Global $g_iMaxLogFiles = 3


; Initialisiert das Logging-System
Func _InitLogging($sLogPath = Default, $iLogLevel = Default)
    If $sLogPath <> Default Then $g_sLogFilePath = $sLogPath
    If $iLogLevel <> Default Then $g_iLogLevel = $iLogLevel

    ; Log-Verzeichnis erstellen
    Local $sLogDir = StringRegExpReplace($g_sLogFilePath, "\\[^\\]*$", "")
    If Not FileExists($sLogDir) Then DirCreate($sLogDir)

    ; Rotation prüfen
    If FileExists($g_sLogFilePath) And FileGetSize($g_sLogFilePath) > $g_iMaxLogSize Then
        _RotateLogFile()
    EndIf

    ; Logdatei öffnen
    $g_hLogFile = FileOpen($g_sLogFilePath, $FO_APPEND)
    If $g_hLogFile = -1 Then
        ConsoleWrite("FEHLER: Konnte Logdatei nicht öffnen: " & $g_sLogFilePath & @CRLF)
        Return False
    EndIf

    _LogMessage($LOG_INFO, "")
    _LogMessage($LOG_INFO, "========================================")
    _LogMessage($LOG_INFO, "GUI-Slider gestartet: " & _NowCalc())
    _LogMessage($LOG_INFO, "========================================")
    _LogMessage($LOG_INFO, "AutoIt Version: " & @AutoItVersion)
    _LogMessage($LOG_INFO, "Skript: " & @ScriptFullPath)
    _LogMessage($LOG_INFO, "Arbeitsverzeichnis: " & @WorkingDir)
    _LogMessage($LOG_INFO, "")

    Return True
EndFunc

; Schließt das Logging-System
Func _CloseLogging()
    If $g_hLogFile = -1 Then Return True

    _LogMessage($LOG_INFO, "")
    _LogMessage($LOG_INFO, "========================================")
    _LogMessage($LOG_INFO, "GUI-Slider beendet: " & _NowCalc())
    _LogMessage($LOG_INFO, "========================================")

    FileClose($g_hLogFile)
    $g_hLogFile = -1

    Return True
EndFunc

; Rotiert die Logdatei
Func _RotateLogFile()
    If $g_hLogFile <> -1 Then
        FileClose($g_hLogFile)
        $g_hLogFile = -1
    EndIf

    ; Alte Dateien verschieben
    For $i = $g_iMaxLogFiles - 1 To 1 Step -1
        Local $sOldFile = ($i = 1) ? $g_sLogFilePath : $g_sLogFilePath & "." & ($i - 1)
        Local $sNewFile = $g_sLogFilePath & "." & $i

        If FileExists($sOldFile) Then
            If FileExists($sNewFile) Then FileDelete($sNewFile)
            FileMove($sOldFile, $sNewFile)
        EndIf
    Next

    Return True
EndFunc

; Schreibt eine Log-Nachricht
Func _LogMessage($iLevel, $sMessage)
    If $iLevel > $g_iLogLevel Then Return True

    ; Level-Präfix
    Local $sLevelPrefix
    Switch $iLevel
        Case $LOG_ERROR
            $sLevelPrefix = "ERROR  "
        Case $LOG_WARNING
            $sLevelPrefix = "WARNING"
        Case $LOG_INFO
            $sLevelPrefix = "INFO   "
        Case $LOG_DEBUG
            $sLevelPrefix = "DEBUG  "
        Case Else
            $sLevelPrefix = "UNKNOWN"
    EndSwitch

    ; Formatiere Nachricht
    Local $sTimestamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC
    Local $sFormattedMessage = $sTimestamp & " [" & $sLevelPrefix & "] " & $sMessage

    ; Schreibe in Datei und Konsole
    If $g_hLogFile <> -1 Then FileWriteLine($g_hLogFile, $sFormattedMessage)
    ConsoleWrite($sFormattedMessage & @CRLF)

    Return True
EndFunc

; Convenience-Funktionen
Func _LogError($sMessage)
    Return _LogMessage($LOG_ERROR, $sMessage)
EndFunc

Func _LogWarning($sMessage)
    Return _LogMessage($LOG_WARNING, $sMessage)
EndFunc

Func _LogInfo($sMessage)
    Return _LogMessage($LOG_INFO, $sMessage)
EndFunc

Func _LogDebug($sMessage)
    Return _LogMessage($LOG_DEBUG, $sMessage)
EndFunc

; Spezielle Log-Funktionen für GUI-Slider
Func _LogMonitorInfo()
    _LogInfo("=== Monitor-Konfiguration ===")
    _LogInfo("Anzahl Monitore: " & $g_aMonitors[0][0])

    For $i = 1 To $g_aMonitors[0][0]
        _LogInfo("Monitor " & $i & ":")
        _LogInfo("  - Auflösung: " & $g_aMonitors[$i][0] & "x" & $g_aMonitors[$i][1])
        _LogInfo("  - Position: X=" & $g_aMonitors[$i][2] & ", Y=" & $g_aMonitors[$i][3])
        _LogInfo("  - Bereich: " & $g_aMonitors[$i][2] & "," & $g_aMonitors[$i][3] & " bis " & _
                ($g_aMonitors[$i][2] + $g_aMonitors[$i][0]) & "," & ($g_aMonitors[$i][3] + $g_aMonitors[$i][1]))
    Next
    _LogInfo("=============================")
EndFunc

Func _LogWindowPosition($hWindow, $sContext = "")
    Local $aPos = WinGetPos($hWindow)
    If Not IsArray($aPos) Then
        _LogError("Konnte Fensterposition nicht ermitteln" & ($sContext ? " (" & $sContext & ")" : ""))
        Return False
    EndIf

    Local $sMsg = "Fensterposition"
    If $sContext Then $sMsg &= " [" & $sContext & "]"
    $sMsg &= ": X=" & $aPos[0] & ", Y=" & $aPos[1] & ", W=" & $aPos[2] & ", H=" & $aPos[3]
    $sMsg &= " (Monitor " & $g_iCurrentScreenNumber & ")"

    _LogDebug($sMsg)
    Return True
EndFunc

Func _LogSlideOperation($sDirection, $sInOrOut, $iFromMonitor, $iToMonitor = 0)
    Local $sMsg = "Slide-Operation: " & $sInOrOut & " " & $sDirection
    $sMsg &= " auf Monitor " & $iFromMonitor
    If $iToMonitor > 0 Then $sMsg &= " → Monitor " & $iToMonitor

    _LogInfo($sMsg)
EndFunc
