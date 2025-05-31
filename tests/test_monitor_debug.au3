#cs ----------------------------------------------------------------------------
 Test Monitor Debug - Zeigt alle erkannten Monitore
#ce ----------------------------------------------------------------------------

#include "..\src\modules\MonitorDetection.au3"
#include "..\src\modules\Logging.au3"
#include <Array.au3>

; Logging initialisieren
_InitLogging()

ConsoleWrite("=== MONITOR DEBUG TEST ===" & @CRLF & @CRLF)

; Verschiedene Monitor-Erkennungen testen
ConsoleWrite("1. GetMonitors() Standard:" & @CRLF)
Local $aMonitors = _GetMonitors()
ConsoleWrite("   Gefundene Monitore: " & $aMonitors[0][0] & @CRLF)
For $i = 1 To $aMonitors[0][0]
    ConsoleWrite("   Monitor " & $i & ": " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1] & _
                " @ " & $aMonitors[$i][2] & "," & $aMonitors[$i][3] & @CRLF)
Next
ConsoleWrite(@CRLF)

; Array anzeigen
_ArrayDisplay($aMonitors, "GetMonitors Ergebnis")

; System Metrics
ConsoleWrite("2. System Metrics:" & @CRLF)
Local $iMonitorCount = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 80)[0]  ; SM_CMONITORS
ConsoleWrite("   SM_CMONITORS: " & $iMonitorCount & " Monitore" & @CRLF)

; Desktop-Größe
ConsoleWrite("   Desktop: " & @DesktopWidth & "x" & @DesktopHeight & @CRLF)

; Virtuelle Desktop-Größe
Local $iVirtualWidth = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 78)[0]  ; SM_CXVIRTUALSCREEN
Local $iVirtualHeight = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 79)[0]  ; SM_CYVIRTUALSCREEN
Local $iVirtualLeft = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 76)[0]  ; SM_XVIRTUALSCREEN
Local $iVirtualTop = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 77)[0]  ; SM_YVIRTUALSCREEN

ConsoleWrite("   Virtueller Desktop: " & $iVirtualWidth & "x" & $iVirtualHeight & _
            " @ " & $iVirtualLeft & "," & $iVirtualTop & @CRLF)
ConsoleWrite(@CRLF)

; Direct EnumDisplayMonitors Test
ConsoleWrite("3. Direct EnumDisplayMonitors Test:" & @CRLF)

Global $g_iTestMonitorCount = 0
Global $g_aTestMonitors[10][4]

; Callback
Func _TestMonitorCallback($hMonitor, $hDC, $pRect, $lParam)
    $g_iTestMonitorCount += 1
    
    Local $tRect = DllStructCreate("long Left;long Top;long Right;long Bottom", $pRect)
    Local $iLeft = DllStructGetData($tRect, "Left")
    Local $iTop = DllStructGetData($tRect, "Top")
    Local $iRight = DllStructGetData($tRect, "Right")
    Local $iBottom = DllStructGetData($tRect, "Bottom")
    
    ConsoleWrite("   Monitor " & $g_iTestMonitorCount & " Handle: " & $hMonitor & _
                " Rect: " & $iLeft & "," & $iTop & " - " & $iRight & "," & $iBottom & @CRLF)
    
    If $g_iTestMonitorCount <= 10 Then
        $g_aTestMonitors[$g_iTestMonitorCount - 1][0] = $iRight - $iLeft
        $g_aTestMonitors[$g_iTestMonitorCount - 1][1] = $iBottom - $iTop
        $g_aTestMonitors[$g_iTestMonitorCount - 1][2] = $iLeft
        $g_aTestMonitors[$g_iTestMonitorCount - 1][3] = $iTop
    EndIf
    
    Return 1 ; Continue
EndFunc

; Callback registrieren
Local $hCallback = DllCallbackRegister("_TestMonitorCallback", "bool", "handle;handle;ptr;lparam")
DllCall("user32.dll", "bool", "EnumDisplayMonitors", "handle", 0, "ptr", 0, _
        "ptr", DllCallbackGetPtr($hCallback), "lparam", 0)
DllCallbackFree($hCallback)

ConsoleWrite("   Gefundene Monitore: " & $g_iTestMonitorCount & @CRLF)
ConsoleWrite(@CRLF)

; Ergebnisse anzeigen
ReDim $g_aTestMonitors[$g_iTestMonitorCount][4]
_ArrayDisplay($g_aTestMonitors, "Direct EnumDisplayMonitors")

ConsoleWrite("=== TEST BEENDET ===" & @CRLF)