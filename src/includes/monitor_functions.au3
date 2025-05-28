#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         GUI-Slider-MultiMonitor Team
 Script Function: Monitor-Erkennungs- und Verwaltungsfunktionen
 
 Datei: monitor_functions.au3
 Beschreibung: Funktionen zur Erkennung und Verwaltung von Multi-Monitor-Setups
#ce ----------------------------------------------------------------------------

#include-once
#include "globals.au3"

; ===============================================
; Funktion: _GetMonitors
; Beschreibung: Erkennt alle angeschlossenen Monitore
; Rückgabe: Array mit Monitor-Informationen
; ===============================================
Func _GetMonitors()
    Local $cbMonitorEnumProc = DllCallbackRegister("_MonitorEnumProc", "ubyte", "ptr;ptr;ptr;int")
    Local $strctCount = DllStructCreate("uint Count;uint Width[12];uint Height[12];int left[12];int top[12]")
    DllStructSetData($strctCount, "Count", 0)
    
    ; User32.dll aufrufen für Monitor-Enumeration
    Local $ret = DllCall("User32.dll", "ubyte", "EnumDisplayMonitors", _
                         "ptr", 0, "ptr", 0, _
                         "ptr", DllCallbackGetPtr($cbMonitorEnumProc), _
                         "ptr", DllStructGetPtr($strctCount))
    
    ; Callback freigeben
    DllCallbackFree($cbMonitorEnumProc)
    
    ; Ergebnisse verarbeiten
    Local $iCount = Int(DllStructGetData($strctCount, "Count"))
    Local $aMonitors[$iCount + 1][4] = [[$iCount]]
    
    For $i = 1 To $iCount
        $aMonitors[$i][0] = Int(DllStructGetData($strctCount, "Width", $i))    ; Breite
        $aMonitors[$i][1] = Int(DllStructGetData($strctCount, "Height", $i))   ; Höhe
        $aMonitors[$i][2] = Int(DllStructGetData($strctCount, "left", $i))     ; X-Position
        $aMonitors[$i][3] = Int(DllStructGetData($strctCount, "top", $i))      ; Y-Position
    Next
    
    Return $aMonitors
EndFunc

; ===============================================
; Funktion: _MonitorEnumProc
; Beschreibung: Callback-Funktion für EnumDisplayMonitors
; ===============================================
Func _MonitorEnumProc($hMonitor, $hDC, $pRect, $lParam)
    Local $rect = DllStructCreate("int left;int top;int right;int bottom", $pRect)
    Local $strctCount = DllStructCreate("uint Count;uint Width[12];uint Height[12];int left[12];int top[12]", $lParam)
    
    Local $iCount = DllStructGetData($strctCount, "Count") + 1
    DllStructSetData($strctCount, "Count", $iCount)
    
    ; Monitor-Dimensionen berechnen
    Local $iWidth = DllStructGetData($rect, "right") - DllStructGetData($rect, "left")
    Local $iHeight = DllStructGetData($rect, "bottom") - DllStructGetData($rect, "top")
    
    ; Daten speichern
    DllStructSetData($strctCount, "Width", $iWidth, $iCount)
    DllStructSetData($strctCount, "Height", $iHeight, $iCount)
    DllStructSetData($strctCount, "left", DllStructGetData($rect, "left"), $iCount)
    DllStructSetData($strctCount, "top", DllStructGetData($rect, "top"), $iCount)
    
    Return 1 ; Fortsetzung der Enumeration
EndFunc

; ===============================================
; Funktion: _FindAdjacentMonitor
; Beschreibung: Findet angrenzenden Monitor in gegebener Richtung
; Parameter: $aMonitors - Monitor-Array
;           $iCurrent - Aktueller Monitor
;           $sDirection - Richtung ("Left", "Right", "Top", "Bottom")
; Rückgabe: Monitor-Nummer oder -1
; ===============================================
Func _FindAdjacentMonitor($aMonitors, $iCurrent, $sDirection)
    If $iCurrent < 1 Or $iCurrent > $aMonitors[0][0] Then Return -1
    
    Local $iCurrentLeft = $aMonitors[$iCurrent][2]
    Local $iCurrentTop = $aMonitors[$iCurrent][3]
    Local $iCurrentRight = $iCurrentLeft + $aMonitors[$iCurrent][0]
    Local $iCurrentBottom = $iCurrentTop + $aMonitors[$iCurrent][1]
    
    For $i = 1 To $aMonitors[0][0]
        If $i = $iCurrent Then ContinueLoop
        
        Local $iLeft = $aMonitors[$i][2]
        Local $iTop = $aMonitors[$i][3]
        Local $iRight = $iLeft + $aMonitors[$i][0]
        Local $iBottom = $iTop + $aMonitors[$i][1]
        
        Switch $sDirection
            Case "Left"
                ; Monitor muss links anliegen
                If Abs($iRight - $iCurrentLeft) <= $g_iMonitorTolerance Then
                    ; Vertikale Überlappung prüfen
                    If _CheckOverlap($iTop, $iBottom, $iCurrentTop, $iCurrentBottom) Then
                        Return $i
                    EndIf
                EndIf
                
            Case "Right"
                ; Monitor muss rechts anliegen
                If Abs($iLeft - $iCurrentRight) <= $g_iMonitorTolerance Then
                    ; Vertikale Überlappung prüfen
                    If _CheckOverlap($iTop, $iBottom, $iCurrentTop, $iCurrentBottom) Then
                        Return $i
                    EndIf
                EndIf
                
            Case "Top"
                ; Monitor muss oben anliegen
                If Abs($iBottom - $iCurrentTop) <= $g_iMonitorTolerance Then
                    ; Horizontale Überlappung prüfen
                    If _CheckOverlap($iLeft, $iRight, $iCurrentLeft, $iCurrentRight) Then
                        Return $i
                    EndIf
                EndIf
                
            Case "Bottom"
                ; Monitor muss unten anliegen
                If Abs($iTop - $iCurrentBottom) <= $g_iMonitorTolerance Then
                    ; Horizontale Überlappung prüfen
                    If _CheckOverlap($iLeft, $iRight, $iCurrentLeft, $iCurrentRight) Then
                        Return $i
                    EndIf
                EndIf
        EndSwitch
    Next
    
    Return -1
EndFunc

; ===============================================
; Funktion: _CheckOverlap
; Beschreibung: Prüft Überlappung zweier Bereiche
; ===============================================
Func _CheckOverlap($iStart1, $iEnd1, $iStart2, $iEnd2)
    Return Not ($iEnd1 <= $iStart2 Or $iEnd2 <= $iStart1)
EndFunc

; ===============================================
; Funktion: _GetPrimaryMonitor
; Beschreibung: Ermittelt den primären Monitor
; ===============================================
Func _GetPrimaryMonitor($aMonitors)
    For $i = 1 To $aMonitors[0][0]
        ; Primärmonitor hat Position (0,0) oder ist am nächsten dazu
        If $aMonitors[$i][2] = 0 And $aMonitors[$i][3] = 0 Then
            Return $i
        EndIf
    Next
    
    ; Falls kein Monitor bei (0,0), nimm den ersten
    Return 1
EndFunc

; ===============================================
; Funktion: _GetMonitorFromPoint
; Beschreibung: Ermittelt Monitor an gegebener Position
; ===============================================
Func _GetMonitorFromPoint($aMonitors, $iX, $iY)
    For $i = 1 To $aMonitors[0][0]
        Local $iLeft = $aMonitors[$i][2]
        Local $iTop = $aMonitors[$i][3]
        Local $iRight = $iLeft + $aMonitors[$i][0]
        Local $iBottom = $iTop + $aMonitors[$i][1]
        
        If $iX >= $iLeft And $iX < $iRight And $iY >= $iTop And $iY < $iBottom Then
            Return $i
        EndIf
    Next
    
    Return -1
EndFunc

; ===============================================
; Funktion: _UpdateMonitorInfo
; Beschreibung: Aktualisiert globale Monitor-Variablen
; ===============================================
Func _UpdateMonitorInfo()
    $g_aMonitorInfo = _GetMonitors()
    
    ; Bewegungsmöglichkeiten für aktuellen Monitor prüfen
    If $g_iCurrentScreenNumber > 0 And $g_iCurrentScreenNumber <= $g_aMonitorInfo[0][0] Then
        $g_bCanMoveLeft = (_FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Left") = -1)
        $g_bCanMoveRight = (_FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Right") = -1)
        $g_bCanMoveUp = (_FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Top") = -1)
        $g_bCanMoveDown = (_FindAdjacentMonitor($g_aMonitorInfo, $g_iCurrentScreenNumber, "Bottom") = -1)
        
        ; Aktuelle Monitor-Dimensionen aktualisieren
        $g_iCurrentScreenX = $g_aMonitorInfo[$g_iCurrentScreenNumber][2]
        $g_iCurrentScreenY = $g_aMonitorInfo[$g_iCurrentScreenNumber][3]
        $g_iCurrentScreenWidth = $g_aMonitorInfo[$g_iCurrentScreenNumber][0]
        $g_iCurrentScreenHeight = $g_aMonitorInfo[$g_iCurrentScreenNumber][1]
    EndIf
EndFunc

; ===============================================
; Funktion: _GetMonitorArrangement
; Beschreibung: Ermittelt die Anordnung der Monitore
; Rückgabe: String mit Beschreibung der Anordnung
; ===============================================
Func _GetMonitorArrangement($aMonitors)
    Local $sArrangement = ""
    Local $iMonitorCount = $aMonitors[0][0]
    
    If $iMonitorCount = 1 Then
        Return "Single Monitor"
    ElseIf $iMonitorCount = 2 Then
        ; Prüfen ob horizontal oder vertikal angeordnet
        If Abs($aMonitors[1][3] - $aMonitors[2][3]) < $g_iMonitorTolerance Then
            Return "2 Monitors Horizontal"
        Else
            Return "2 Monitors Vertical"
        EndIf
    Else
        ; Komplexere Anordnungen analysieren
        Local $bAllHorizontal = True
        Local $bAllVertical = True
        
        For $i = 2 To $iMonitorCount
            If Abs($aMonitors[1][3] - $aMonitors[$i][3]) > $g_iMonitorTolerance Then
                $bAllHorizontal = False
            EndIf
            If Abs($aMonitors[1][2] - $aMonitors[$i][2]) > $g_iMonitorTolerance Then
                $bAllVertical = False
            EndIf
        Next
        
        If $bAllHorizontal Then
            Return $iMonitorCount & " Monitors Horizontal"
        ElseIf $bAllVertical Then
            Return $iMonitorCount & " Monitors Vertical"
        Else
            Return $iMonitorCount & " Monitors Mixed Arrangement"
        EndIf
    EndIf
EndFunc
