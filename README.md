# GUI-Slider Multi-Monitor

Ein fortschrittliches AutoIt-Tool zur Verwaltung von GUI-Fenstern in Multi-Monitor-Umgebungen mit Slide-Animationen.

## 🆕 Aktuelle Verbesserungen

### 1. **Besserer Git MCP-Server installiert**
- **Neuer Server**: `@cyanheads/git-mcp-server` 
- **Vorteile**: 
  - Arbeitet direkt mit lokalem Git CLI
  - Pusht Dateien als Ganzes (nicht Zeile für Zeile)
  - Unterstützt alle Git-Operationen (clone, commit, push, pull, branch, etc.)
- **Wichtig**: Bitte die Anwendung neu starten, damit der neue MCP-Server aktiv wird!

### 2. **GUI-Verlust-Bug behoben**
- Problem: GUI konnte aus dem sichtbaren Bereich verschwinden
- Lösung: 
  - Virtuelle Desktop-Grenzen werden jetzt korrekt berechnet (alle Monitore)
  - Sicherheitsprüfungen verhindern, dass die GUI außerhalb landet
  - Neuer Recovery-Hotkey: `Alt+End` bringt verlorene GUI zurück

### 3. **Erweiterte Monitor-Visualisierung**
- Live-Visualisierung aller Monitore mit GDI+
- Zeigt GUI-Position in Echtzeit
- Animationen werden visuell dargestellt
- Fenster rechts unten positioniert

### 4. **Umfassendes Logging-System**
- Detaillierte Logs aller Operationen
- Log-Rotation bei 10MB
- Verschiedene Log-Level (DEBUG, INFO, WARNING, ERROR)
- Logs im `src/logs/` Verzeichnis

## 📁 Projektstruktur

```
GUI-Slider-MultiMonitor/
├── src/
│   ├── main.au3                 # Hauptprogramm
│   ├── includes/
│   │   ├── GlobalVars.au3      # Globale Variablen
│   │   └── Constants.au3       # Konstanten
│   ├── modules/
│   │   ├── ConfigManager.au3   # Konfigurationsverwaltung
│   │   ├── GUIControl.au3      # GUI-Steuerung
│   │   ├── Logging.au3         # Logging-System
│   │   ├── MonitorDetection.au3 # Monitor-Erkennung
│   │   ├── SliderLogic.au3     # Slide-Animationen (mit Bugfix)
│   │   └── Visualization.au3   # Monitor-Visualisierung
│   └── logs/                   # Log-Dateien
├── config/
│   └── default_config.ini      # Standard-Konfiguration
├── backup/                     # Backup-Verzeichnis
├── docs/                       # Dokumentation
└── tests/                      # Test-Dateien
```

## ⌨️ Hotkeys

| Hotkey | Funktion |
|--------|----------|
| `Alt + ←` | Slide nach links |
| `Alt + →` | Slide nach rechts |
| `Alt + ↑` | Slide nach oben |
| `Alt + ↓` | Slide nach unten |
| `Alt + Space` | Toggle Slide In/Out |
| `Alt + Home` | GUI zentrieren |
| **`Alt + End`** | **GUI wiederherstellen (NEU!)** |

## 🛠️ Installation

1. AutoIt 3.3.16.1 oder höher installieren
2. Repository klonen:
   ```bash
   git clone https://github.com/Ralle1976/AutoIt-GUI-Slider-MultiMonitor.git
   ```
3. `src/main.au3` mit AutoIt ausführen

## 🔧 Konfiguration

Die Konfiguration erfolgt über `config/default_config.ini`:

```ini
[Hotkeys]
RecoverWindow=!{End}  ; Neuer Recovery-Hotkey

[Animation]
SlideSteps=15        ; Anzahl der Animationsschritte
AnimationSpeed=10    ; Geschwindigkeit in ms

[Logging]
LogLevel=INFO        ; DEBUG, INFO, WARNING, ERROR
EnableVisualization=1 ; Monitor-Visualisierung aktivieren
```

## 🐛 Bekannte Probleme (Behoben)

- ✅ **GUI verschwindet aus Monitor**: Behoben durch virtuelle Desktop-Berechnung
- ✅ **GitHub MCP langsam**: Behoben durch neuen git-mcp-server
- ✅ **Keine Visualisierung**: Behoben durch GDI+ Implementation

## 📝 Entwickler-Hinweise

### MCP-Server
- Der neue `git-mcp-server` arbeitet direkt mit dem lokalen Git
- Keine Zeile-für-Zeile Uploads mehr
- Unterstützt alle Standard Git-Operationen

### Sicherheit
- Keine sensiblen Daten (Pfade, IPs, Passwörter) im Code
- Alle Konfigurationen in INI-Dateien

### Debugging
- Aktiviere `LogLevel=DEBUG` für detaillierte Logs
- Visualisierung zeigt Live-Positionen
- Recovery-Funktion für verlorene GUIs

## 📄 Lizenz

Dieses Projekt ist Open Source. Details siehe LICENSE Datei.

## 👥 Mitwirkende

- Hauptentwickler: Ralle1976
- MCP-Server Integration: Claude AI Assistant

---

**Hinweis**: Nach Installation des neuen MCP-Servers bitte die Anwendung neu starten!
