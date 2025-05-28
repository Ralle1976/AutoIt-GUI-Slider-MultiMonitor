#include-once
#include "..\includes\GlobalVars.au3"
#include "..\includes\Constants.au3"
#include "Logging.au3"

; ==========================================
; Monitor Detection Module
; ==========================================

; Struktur für erweiterte Monitor-Informationen
Global $g_aMonitorDetails[1][6] ; [Index][DeviceName, Left, Top, Width, Height, Primary]

; Hauptfunktion zur Monitor-Erkennung
Func _GetMonitors()
    _LogInfo("Starte Monitor-Erkennung...")
    
    ; Versuche zuerst die erweiterte Methode
    Local $aMonitors = _GetMonitorsExtended()
    If @error Or $aMonitors[0][0] = 0 Then
        _LogWarning("Erweiterte Monitor-Erkennung fehlgeschlagen, verwende Basis-Methode")
        $aMonitors = _GetMonitorsBasic()
        If @error Or $aMonitors[0][0] = 0 Then
            _LogError("Beide Monitor-Erkennungsmethoden fehlgeschlagen, verwende Notfall-Fallback")
            $aMonitors = _GetMonitorsFallback()
            If @error Or $aMonitors[0][0] = 0 Then
                _LogError("Monitor-Erkennung komplett fehlgeschlagen!")
                Return SetError($ERR_NO_MONITORS, 0, 0)
            EndIf
        EndIf
    EndIf
    
    ; Debug-Ausgabe
    _LogInfo("Monitor-Erkennung erfolgreich: " & $aMonitors[0][0] & " Monitore")
    _LogInfo("=== Monitor-Konfiguration ===")
    _LogInfo("Anzahl Monitore: " & $aMonitors[0][0])
    
    For $i = 1 To $aMonitors[0][0]
        _LogInfo("Monitor " & $i & ":")
        _LogInfo("  - Auflösung: " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1])
        _LogInfo("  - Position: X=" & $aMonitors[$i][2] & ", Y=" & $aMonitors[$i][3])
        _LogInfo("  - Bereich: " & $aMonitors[$i][2] & "," & $aMonitors[$i][3] & " bis " & _
                 ($aMonitors[$i][2] + $aMonitors[$i][0]) & "," & ($aMonitors[$i][3] + $aMonitors[$i][1]))
    Next
    _LogInfo("=============================")
    
    Return $aMonitors
EndFunc

; Fallback wenn gar keine Monitore erkannt werden
Func _GetMonitorsFallback()
    _LogWarning("Verwende Notfall-Fallback mit Desktop-Dimensionen")
    
    Local $aMonitors[2][4]
    $aMonitors[0][0] = 1  ; Ein Monitor
    $aMonitors[1][0] = @DesktopWidth
    $aMonitors[1][1] = @DesktopHeight
    $aMonitors[1][2] = 0  ; X-Position
    $aMonitors[1][3] = 0  ; Y-Position
    
    $g_iMonitorCount = 1
    $g_aMonitors = $aMonitors
    
    _LogInfo("Fallback: 1 Monitor mit " & @DesktopWidth & "x" & @DesktopHeight & " @ 0,0")
    
    Return $aMonitors
EndFunc

; Basis Monitor-Erkennung (Fallback)
Func _GetMonitorsBasic()
_LogDebug("Verwende alternative Monitor-Erkennung mit @DesktopWidth/Height")

; Alternative Methode: Verwende @DesktopWidth/Height und Desktop-Metriken
Local $iMonitorCount = 0
Local $aMonitors[13][4] ; Max 12 Monitore + Header

; Hole virtuelle Desktop-Dimensionen
Local $iVirtualWidth = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 78)[0]  ; SM_CXVIRTUALSCREEN
Local $iVirtualHeight = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 79)[0] ; SM_CYVIRTUALSCREEN
Local $iVirtualLeft = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 76)[0]  ; SM_XVIRTUALSCREEN
Local $iVirtualTop = DllCall("user32.dll", "int", "GetSystemMetrics", "int", 77)[0]   ; SM_YVIRTUALSCREEN

_LogDebug("Virtueller Desktop: " & $iVirtualLeft & "," & $iVirtualTop & " - " & $iVirtualWidth & "x" & $iVirtualHeight)

; Verwende die alte Methode mit korrekter Struktur
Local $hMonitorList[13]
Local $iIndex = 0

; Callback für Monitor-Enumeration
Local $hCallback = DllCallbackRegister("_MonitorEnumCallback", "bool", "handle;handle;ptr;lparam")
Local $tData = DllStructCreate("int Count;handle Monitors[12]")

DllCall("user32.dll", "bool", "EnumDisplayMonitors", "handle", 0, "ptr", 0, _
        "ptr", DllCallbackGetPtr($hCallback), "lparam", DllStructGetPtr($tData))

$iMonitorCount = DllStructGetData($tData, "Count")

    ; Hole Informationen für jeden Monitor
    For $i = 1 To $iMonitorCount
        Local $hMonitor = DllStructGetData($tData, "Monitors", $i)
        Local $tMonitorInfo = DllStructCreate("dword Size;int Left;int Top;int Right;int Bottom;int WorkLeft;int WorkTop;int WorkRight;int WorkBottom;dword Flags")
        DllStructSetData($tMonitorInfo, "Size", DllStructGetSize($tMonitorInfo))
        
        DllCall("user32.dll", "bool", "GetMonitorInfo", "handle", $hMonitor, "ptr", DllStructGetPtr($tMonitorInfo))
        
        $aMonitors[$i][0] = DllStructGetData($tMonitorInfo, "Right") - DllStructGetData($tMonitorInfo, "Left")
        $aMonitors[$i][1] = DllStructGetData($tMonitorInfo, "Bottom") - DllStructGetData($tMonitorInfo, "Top")
        $aMonitors[$i][2] = DllStructGetData($tMonitorInfo, "Left")
        $aMonitors[$i][3] = DllStructGetData($tMonitorInfo, "Top")
        
        _LogDebug("Monitor " & $i & ": " & $aMonitors[$i][0] & "x" & $aMonitors[$i][1] & " @ " & $aMonitors[$i][2] & "," & $aMonitors[$i][3])
    Next
    
    DllCallbackFree($hCallback)
    
    $aMonitors[0][0] = $iMonitorCount
    $g_iMonitorCount = $iMonitorCount
    $g_aMonitors = $aMonitors
    
    ; Wenn keine Monitore gefunden wurden, verwende Fallback
    If $iMonitorCount = 0 Then
        _LogWarning("Keine Monitore mit GetMonitorInfo gefunden, verwende Fallback")
        Return _GetMonitorsFallback()
    EndIf
    
    Return $aMonitors
EndFunc

; Callback für Monitor-Enumeration
Func _MonitorEnumCallback($hMonitor, $hDC, $pRect, $lParam)
    Local $tData = DllStructCreate("int Count;handle Monitors[12]", $lParam)
    Local $iCount = DllStructGetData($tData, "Count") + 1
    
    If $iCount <= 12 Then
        DllStructSetData($tData, "Count", $iCount)
        DllStructSetData($tData, "Monitors", $hMonitor, $iCount)
    EndIf
    
    Return 1 ; Continue enumeration
EndFunc

; Erweiterte Monitor-Erkennung mit Display-Nummern
Func _GetMonitorsExtended()
    _LogDebug("Verwende erweiterte Monitor-Erkennung mit Display-Nummern")

    ; Hole alle Display-Geräte
    Local $iDevNum = 0
    Local $aDisplays[1][6] ; [Index][DeviceName, Left, Top, Width, Height, Primary]
    Local $iDisplayCount = 0

    ; DISPLAY_DEVICE Struktur
    Local $tDisplayDevice = DllStructCreate("dword cb;wchar DeviceName[32];wchar DeviceString[128];dword StateFlags;wchar DeviceID[128];wchar DeviceKey[128]")
    DllStructSetData($tDisplayDevice, "cb", DllStructGetSize($tDisplayDevice))

    ; Durchlaufe alle Display-Geräte
    While 1
        Local $aRet = DllCall("user32.dll", "bool", "EnumDisplayDevicesW", "ptr", 0, "dword", $iDevNum, "struct*", $tDisplayDevice, "dword", 0)
        If @error Or Not $aRet[0] Then ExitLoop

        Local $iStateFlags = DllStructGetData($tDisplayDevice, "StateFlags")
        ; Prüfe ob Gerät aktiv ist (DISPLAY_DEVICE_ACTIVE = 0x00000001)
        If BitAND($iStateFlags, 0x00000001) Then
            Local $sDeviceName = DllStructGetData($tDisplayDevice, "DeviceName")
            _LogDebug("Gefunden: " & $sDeviceName & " - Flags: " & $iStateFlags)

            ; Hole Monitor-Informationen
            Local $tDevMode = DllStructCreate("wchar dmDeviceName[32];word dmSpecVersion;word dmDriverVersion;word dmSize;word dmDriverExtra;dword dmFields;" & _
                                            "short dmOrientation;short dmPaperSize;short dmPaperLength;short dmPaperWidth;short dmScale;short dmCopies;" & _
                                            "short dmDefaultSource;short dmPrintQuality;short dmColor;short dmDuplex;short dmYResolution;short dmTTOption;" & _
                                            "short dmCollate;wchar dmFormName[32];word dmLogPixels;dword dmBitsPerPel;dword dmPelsWidth;dword dmPelsHeight;" & _
                                            "dword dmDisplayFlags;dword dmDisplayFrequency;dword dmICMMethod;dword dmICMIntent;dword dmMediaType;" & _
                                            "dword dmDitherType;dword dmReserved1;dword dmReserved2;dword dmPanningWidth;dword dmPanningHeight;" & _
                                            "dword dmPositionX;dword dmPositionY")
            DllStructSetData($tDevMode, "dmSize", DllStructGetSize($tDevMode))

            Local $aEnum = DllCall("user32.dll", "bool", "EnumDisplaySettingsW", "wstr", $sDeviceName, "dword", -1, "struct*", $tDevMode)
            If Not @error And $aEnum[0] Then
                $iDisplayCount += 1
                ReDim $aDisplays[$iDisplayCount + 1][6]

                $aDisplays[$iDisplayCount][0] = $sDeviceName
                $aDisplays[$iDisplayCount][1] = DllStructGetData($tDevMode, "dmPositionX")
                $aDisplays[$iDisplayCount][2] = DllStructGetData($tDevMode, "dmPositionY")
                $aDisplays[$iDisplayCount][3] = DllStructGetData($tDevMode, "dmPelsWidth")
                $aDisplays[$iDisplayCount][4] = DllStructGetData($tDevMode, "dmPelsHeight")
                $aDisplays[$iDisplayCount][5] = BitAND($iStateFlags, 0x00000004) ? 1 : 0 ; DISPLAY_DEVICE_PRIMARY_DEVICE

                _LogDebug("Monitor " & $iDisplayCount & ": " & $sDeviceName & " @ " & _
                         $aDisplays[$iDisplayCount][1] & "," & $aDisplays[$iDisplayCount][2] & " - " & _
                         $aDisplays[$iDisplayCount][3] & "x" & $aDisplays[$iDisplayCount][4] & _
                         ($aDisplays[$iDisplayCount][5] ? " (Primary)" : ""))
            EndIf
        EndIf

        $iDevNum += 1
    WEnd

    If $iDisplayCount = 0 Then
        _LogError("Keine aktiven Displays gefunden")
        Return SetError($ERR_NO_MONITORS, 0, 0)
    EndIf

    ; Sortiere Monitore nach Display-Nummer (aus DeviceName)
    _SortMonitorsByDisplayNumber($aDisplays, $iDisplayCount)

    ; Konvertiere in Standard-Format
    Local $aMonitors[$iDisplayCount + 1][4] = [[$iDisplayCount]]
    For $i = 1 To $iDisplayCount
        $aMonitors[$i][0] = $aDisplays[$i][3] ; Width
        $aMonitors[$i][1] = $aDisplays[$i][4] ; Height
        $aMonitors[$i][2] = $aDisplays[$i][1] ; Left
        $aMonitors[$i][3] = $aDisplays[$i][2] ; Top
    Next

    $g_iMonitorCount = $iDisplayCount
    $g_aMonitors = $aMonitors
    $aDisplays[0][0] = $iDisplayCount
    $g_aMonitorDetails = $aDisplays

    _LogInfo("Monitor-Erkennung abgeschlossen: " & $iDisplayCount & " Monitore gefunden")
    _LogMonitorInfoDetailed()

    Return $aMonitors
EndFunc

; Sortiert Monitore nach Display-Nummer
Func _SortMonitorsByDisplayNumber(ByRef $aDisplays, $iCount)
    _LogDebug("Sortiere Monitore nach Display-Nummer...")

    ; Bubble Sort nach Display-Nummer im DeviceName
    For $i = 1 To $iCount - 1
        For $j = $i + 1 To $iCount
            Local $iNum1 = _ExtractDisplayNumber($aDisplays[$i][0])
            Local $iNum2 = _ExtractDisplayNumber($aDisplays[$j][0])

            If $iNum1 > $iNum2 Then
                ; Tausche
                For $k = 0 To 5
                    Local $temp = $aDisplays[$i][$k]
                    $aDisplays[$i][$k] = $aDisplays[$j][$k]
                    $aDisplays[$j][$k] = $temp
                Next
            EndIf
        Next
    Next
EndFunc

; Extrahiert Display-Nummer aus DeviceName (z.B. "\\\\.\\DISPLAY1" -> 1)
Func _ExtractDisplayNumber($sDeviceName)
    Local $aMatch = StringRegExp($sDeviceName, "DISPLAY(\d+)", 1)
    If IsArray($aMatch) Then
        Return Int($aMatch[0])
    EndIf
    Return 999 ; Fallback für unbekannte Geräte
EndFunc

; Ermittelt den primären Monitor
Func _GetPrimaryMonitor()
    If $g_iMonitorCount = 0 Then _GetMonitors()

    For $i = 1 To $g_aMonitors[0][0]
        If $g_aMonitors[$i][2] = 0 And $g_aMonitors[$i][3] = 0 Then
            Return $i
        EndIf
    Next

    Return 1 ; Fallback auf ersten Monitor
EndFunc

; Ermittelt den Monitor an einer bestimmten Position
Func _GetMonitorAtPoint($x, $y)
    If $g_iMonitorCount = 0 Then _GetMonitors()

    For $i = 1 To $g_aMonitors[0][0]
        If $x >= $g_aMonitors[$i][2] And _
           $x < $g_aMonitors[$i][2] + $g_aMonitors[$i][0] And _
           $y >= $g_aMonitors[$i][3] And _
           $y < $g_aMonitors[$i][3] + $g_aMonitors[$i][1] Then
            Return $i
        EndIf
    Next

    Return 0 ; Kein Monitor gefunden
EndFunc

; Überprüft, ob es einen angrenzenden Monitor in einer bestimmten Richtung gibt
Func _HasAdjacentMonitor($iMonitor, $sDirection)
    If $iMonitor < 1 Or $iMonitor > $g_aMonitors[0][0] Then Return False

    Local $iX = $g_aMonitors[$iMonitor][2]
    Local $iY = $g_aMonitors[$iMonitor][3]
    Local $iWidth = $g_aMonitors[$iMonitor][0]
    Local $iHeight = $g_aMonitors[$iMonitor][1]

    Switch $sDirection
        Case $POS_LEFT
            ; Prüfe ob ein Monitor links angrenzt
            For $i = 1 To $g_aMonitors[0][0]
                If $i <> $iMonitor And _
                   $g_aMonitors[$i][2] + $g_aMonitors[$i][0] = $iX And _
                   _MonitorsOverlapVertically($iMonitor, $i) Then
                    Return $i
                EndIf
            Next

        Case $POS_RIGHT
            ; Prüfe ob ein Monitor rechts angrenzt
            For $i = 1 To $g_aMonitors[0][0]
                If $i <> $iMonitor And _
                   $g_aMonitors[$i][2] = $iX + $iWidth And _
                   _MonitorsOverlapVertically($iMonitor, $i) Then
                    Return $i
                EndIf
            Next

        Case $POS_TOP
            ; Prüfe ob ein Monitor oben angrenzt
            For $i = 1 To $g_aMonitors[0][0]
                If $i <> $iMonitor And _
                   $g_aMonitors[$i][3] + $g_aMonitors[$i][1] = $iY And _
                   _MonitorsOverlapHorizontally($iMonitor, $i) Then
                    Return $i
                EndIf
            Next

        Case $POS_BOTTOM
            ; Prüfe ob ein Monitor unten angrenzt
            For $i = 1 To $g_aMonitors[0][0]
                If $i <> $iMonitor And _
                   $g_aMonitors[$i][3] = $iY + $iHeight And _
                   _MonitorsOverlapHorizontally($iMonitor, $i) Then
                    Return $i
                EndIf
            Next
    EndSwitch

    Return 0 ; Kein angrenzender Monitor
EndFunc

; Hilfsfunktion: Prüft vertikale Überlappung
Func _MonitorsOverlapVertically($iMonitor1, $iMonitor2)
    Local $iTop1 = $g_aMonitors[$iMonitor1][3]
    Local $iBottom1 = $iTop1 + $g_aMonitors[$iMonitor1][1]
    Local $iTop2 = $g_aMonitors[$iMonitor2][3]
    Local $iBottom2 = $iTop2 + $g_aMonitors[$iMonitor2][1]

    Return Not ($iBottom1 <= $iTop2 Or $iTop1 >= $iBottom2)
EndFunc

; Hilfsfunktion: Prüft horizontale Überlappung
Func _MonitorsOverlapHorizontally($iMonitor1, $iMonitor2)
    Local $iLeft1 = $g_aMonitors[$iMonitor1][2]
    Local $iRight1 = $iLeft1 + $g_aMonitors[$iMonitor1][0]
    Local $iLeft2 = $g_aMonitors[$iMonitor2][2]
    Local $iRight2 = $iLeft2 + $g_aMonitors[$iMonitor2][0]

    Return Not ($iRight1 <= $iLeft2 Or $iLeft1 >= $iRight2)
EndFunc

; Debug-Funktion: Gibt Monitor-Informationen aus
Func _DebugMonitorInfo()
    Local $sInfo = "Monitor-Konfiguration:" & @CRLF & @CRLF

    For $i = 1 To $g_aMonitors[0][0]
        $sInfo &= "Monitor " & $i & ":" & @CRLF
        $sInfo &= "  Auflösung: " & $g_aMonitors[$i][0] & "x" & $g_aMonitors[$i][1] & @CRLF
        $sInfo &= "  Position: " & $g_aMonitors[$i][2] & ", " & $g_aMonitors[$i][3] & @CRLF

        ; Erweiterte Infos wenn verfügbar
        If UBound($g_aMonitorDetails) > $i And UBound($g_aMonitorDetails, 2) >= 6 Then
            $sInfo &= "  Device: " & $g_aMonitorDetails[$i][0] & @CRLF
            $sInfo &= "  Primary: " & ($g_aMonitorDetails[$i][5] ? "Ja" : "Nein") & @CRLF
        EndIf

        $sInfo &= @CRLF
    Next

    Return $sInfo
EndFunc

; Detaillierte Logging-Funktion für Monitor-Informationen
Func _LogMonitorInfoDetailed()
    _LogInfo("=== Monitor-Konfiguration ===")

    For $i = 1 To $g_aMonitors[0][0]
        _LogInfo("Monitor " & $i & ":")
        _LogInfo("  - Auflösung: " & $g_aMonitors[$i][0] & "x" & $g_aMonitors[$i][1])
        _LogInfo("  - Position: X=" & $g_aMonitors[$i][2] & ", Y=" & $g_aMonitors[$i][3])
        _LogInfo("  - Rechts: " & ($g_aMonitors[$i][2] + $g_aMonitors[$i][0]))
        _LogInfo("  - Unten: " & ($g_aMonitors[$i][3] + $g_aMonitors[$i][1]))

        If UBound($g_aMonitorDetails) > $i And UBound($g_aMonitorDetails, 2) >= 6 Then
            _LogInfo("  - Device: " & $g_aMonitorDetails[$i][0])
            _LogInfo("  - Primary: " & ($g_aMonitorDetails[$i][5] ? "Ja" : "Nein"))
        EndIf

        ; Prüfe Nachbar-Monitore
        Local $sNeighbors = "  - Nachbarn: "
        Local $bHasNeighbor = False

        Local $iLeft = _HasAdjacentMonitor($i, $POS_LEFT)
        If $iLeft > 0 Then
            $sNeighbors &= "Links(" & $iLeft & ") "
            $bHasNeighbor = True
        EndIf

        Local $iRight = _HasAdjacentMonitor($i, $POS_RIGHT)
        If $iRight > 0 Then
            $sNeighbors &= "Rechts(" & $iRight & ") "
            $bHasNeighbor = True
        EndIf

        Local $iTop = _HasAdjacentMonitor($i, $POS_TOP)
        If $iTop > 0 Then
            $sNeighbors &= "Oben(" & $iTop & ") "
            $bHasNeighbor = True
        EndIf

        Local $iBottom = _HasAdjacentMonitor($i, $POS_BOTTOM)
        If $iBottom > 0 Then
            $sNeighbors &= "Unten(" & $iBottom & ") "
            $bHasNeighbor = True
        EndIf

        If $bHasNeighbor Then
            _LogInfo($sNeighbors)
        Else
            _LogInfo("  - Nachbarn: Keine")
        EndIf
    Next

    _LogInfo("===========================")
EndFunc
