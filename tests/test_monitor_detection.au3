; Test-Datei für Monitor-Erkennung
#include "..\modules\MonitorDetection.au3"
#include "..\modules\Logging.au3"
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"

; Logging initialisieren
_InitLogging(@ScriptDir & "\..\logs\")

; Monitor-Erkennung testen
ConsoleWrite("=== Test Monitor-Erkennung ===" & @CRLF)

; Erweiterte Erkennung
Local $aMonitors = _GetMonitors()
If @error Then
    ConsoleWrite("Fehler bei Monitor-Erkennung: " & @error & @CRLF)
    Exit
EndIf

ConsoleWrite("Gefundene Monitore: " & $aMonitors[0][0] & @CRLF & @CRLF)

; Zeige Details
For $i = 1 To $aMonitors[0][0]
    ConsoleWrite("Monitor " & $i & ":" & @CRLF)
    ConsoleWrite("  Auflösung: " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1] & @CRLF)
    ConsoleWrite("  Position: " & $aMonitors[$i][2] & ", " & $aMonitors[$i][3] & @CRLF)
    
    If UBound($g_aMonitorDetails) > $i And UBound($g_aMonitorDetails, 2) >= 6 Then
        ConsoleWrite("  Device: " & $g_aMonitorDetails[$i][0] & @CRLF)
        ConsoleWrite("  Display-Nummer: " & _ExtractDisplayNumber($g_aMonitorDetails[$i][0]) & @CRLF)
        ConsoleWrite("  Primary: " & ($g_aMonitorDetails[$i][5] ? "Ja" : "Nein") & @CRLF)
    EndIf
    
    ConsoleWrite(@CRLF)
Next

; Nachbar-Analyse
ConsoleWrite("=== Nachbar-Analyse ===" & @CRLF)
For $i = 1 To $aMonitors[0][0]
    ConsoleWrite("Monitor " & $i & " Nachbarn: ")
    
    Local $iLeft = _HasAdjacentMonitor($i, "Left")
    If $iLeft > 0 Then ConsoleWrite("Links(" & $iLeft & ") ")
    
    Local $iRight = _HasAdjacentMonitor($i, "Right")
    If $iRight > 0 Then ConsoleWrite("Rechts(" & $iRight & ") ")
    
    Local $iTop = _HasAdjacentMonitor($i, "Top")
    If $iTop > 0 Then ConsoleWrite("Oben(" & $iTop & ") ")
    
    Local $iBottom = _HasAdjacentMonitor($i, "Bottom")
    If $iBottom > 0 Then ConsoleWrite("Unten(" & $iBottom & ") ")
    
    ConsoleWrite(@CRLF)
Next

ConsoleWrite(@CRLF & "Test abgeschlossen. Siehe Log-Datei für Details." & @CRLF)
