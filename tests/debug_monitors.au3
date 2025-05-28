; Debug-Tool für Monitor-Erkennung
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "..\modules\MonitorDetection.au3"
#include "..\modules\Logging.au3"

; Initialisiere Logging
_InitLogging(@ScriptDir & "\..\logs\")

ConsoleWrite("=== Monitor Debug Tool ===" & @CRLF & @CRLF)

; Teste beide Erkennungsmethoden
ConsoleWrite("1. Teste Basis-Erkennung:" & @CRLF)
Local $aBasic = _GetMonitorsBasic()
ConsoleWrite("   Gefunden: " & (IsArray($aBasic) ? $aBasic[0][0] : "FEHLER") & " Monitore" & @CRLF)

If IsArray($aBasic) Then
    For $i = 1 To $aBasic[0][0]
        ConsoleWrite("   Monitor " & $i & ": " & $aBasic[$i][0] & "x" & $aBasic[$i][1] & " @ " & $aBasic[$i][2] & "," & $aBasic[$i][3] & @CRLF)
    Next
EndIf

ConsoleWrite(@CRLF & "2. Teste erweiterte Erkennung:" & @CRLF)
Local $aExt = _GetMonitorsExtended()
ConsoleWrite("   Gefunden: " & (IsArray($aExt) ? $aExt[0][0] : "FEHLER") & " Monitore" & @CRLF)

If IsArray($aExt) Then
    For $i = 1 To $aExt[0][0]
        ConsoleWrite("   Monitor " & $i & ": " & $aExt[$i][0] & "x" & $aExt[$i][1] & " @ " & $aExt[$i][2] & "," & $aExt[$i][3] & @CRLF)
        If UBound($g_aMonitorDetails) > $i Then
            ConsoleWrite("   Device: " & $g_aMonitorDetails[$i][0] & @CRLF)
        EndIf
    Next
EndIf

ConsoleWrite(@CRLF & "3. Teste Haupt-Funktion:" & @CRLF)
Local $aMain = _GetMonitors()
ConsoleWrite("   Verwendet: " & (@error ? "Basis" : "Erweitert") & @CRLF)
ConsoleWrite("   Gefunden: " & (IsArray($aMain) ? $aMain[0][0] : "FEHLER") & " Monitore" & @CRLF)

; Zeige virtuelle Desktop-Grenzen
If IsArray($aMain) And $aMain[0][0] > 0 Then
    Local $iLeft = 999999, $iTop = 999999
    Local $iRight = -999999, $iBottom = -999999
    
    For $i = 1 To $aMain[0][0]
        If $aMain[$i][2] < $iLeft Then $iLeft = $aMain[$i][2]
        If $aMain[$i][3] < $iTop Then $iTop = $aMain[$i][3]
        If $aMain[$i][2] + $aMain[$i][0] > $iRight Then $iRight = $aMain[$i][2] + $aMain[$i][0]
        If $aMain[$i][3] + $aMain[$i][1] > $iBottom Then $iBottom = $aMain[$i][3] + $aMain[$i][1]
    Next
    
    ConsoleWrite(@CRLF & "Virtueller Desktop:" & @CRLF)
    ConsoleWrite("   Links oben: " & $iLeft & "," & $iTop & @CRLF)
    ConsoleWrite("   Rechts unten: " & $iRight & "," & $iBottom & @CRLF)
    ConsoleWrite("   Gesamtgröße: " & ($iRight - $iLeft) & "x" & ($iBottom - $iTop) & @CRLF)
EndIf

ConsoleWrite(@CRLF & "Siehe Log-Datei für weitere Details." & @CRLF)
