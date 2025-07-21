#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 3

; === CONFIGURATION ===
class Config {
    static keyBindings := Map(
        "pata", "a",
        "chika", "w",
        "pon", "d",
        "don", "s",
        "charge", "shift",
        "retreat", "ctrl",
        "pause", "p",
        "repeat", "F1"
    )
    
    static flashDetection := Map(
        "x", 116,
        "y", 1062,
        "interval", 50,
        "brightnessThreshold", 30,
        "cooldownTime", 1000
    )
}

class Songs {
    static map := Map(
        "move",    [Config.keyBindings["pata"], Config.keyBindings["pata"], Config.keyBindings["pata"], Config.keyBindings["pon"]],
        "attack",  [Config.keyBindings["pon"], Config.keyBindings["pon"], Config.keyBindings["pata"], Config.keyBindings["pon"]],
        "defense", [Config.keyBindings["chika"], Config.keyBindings["chika"], Config.keyBindings["pata"], Config.keyBindings["pon"]],
        "retreat", [Config.keyBindings["pon"], Config.keyBindings["pata"], Config.keyBindings["pon"], Config.keyBindings["pata"]],
        "charge",  [Config.keyBindings["pon"], Config.keyBindings["pon"], Config.keyBindings["chika"], Config.keyBindings["chika"]],
        "miracle", [Config.keyBindings["don"], [Config.keyBindings["don"]], [Config.keyBindings["don"]]]
    )
}

; === Global Variables ===
class State {
    static hotkeysDisabled := false
    static repeatMode := false
    static current := ""
    static queued := ""
    static isPlaying := false
    static flashCount := 0
    static isFlashing := false
    static inCooldown := false
    static lastBrightness := 0
    static currentBeat := 0
    static waitingForFlash := false
}

InitializeHotkeys() {
    for key, value in Config.keyBindings {
        if (key != "pause" && key != "repeat") {
            fn := ((key) => (*) => SongManager.QueueSong(key))(key)
            Hotkey("$" value, fn)
            SongManager.ShowToolTip("Registered: " value " -> " key)
        }
    }
    
    Hotkey("$" Config.keyBindings["pause"], (*) => SongManager.TogglePause())
    Hotkey("$" Config.keyBindings["repeat"], (*) => SongManager.ToggleRepeatMode())
    
    SetTimer(FlashDetector.CheckFlash.Bind(FlashDetector), Config.flashDetection["interval"])
}

class SongManager {
    static QueueSong(songName) {
        if (State.hotkeysDisabled) {
            this.ShowToolTip("Hotkeys are disabled. Enable them to queue songs.")
            return
        }
        
        ; Convert button name to song name
        name := Map(
            "pata", "move",
            "chika", "defense",
            "pon", "attack",
            "don", "miracle",
            "charge", "charge",
            "retreat", "retreat"
        ).Get(songName, "")
        
        if !name {
            this.ShowToolTip("Unknown input: " songName)
            return
        }
        
        if (!State.repeatMode) {
            this.PlayOnce(name)
            return
        }

        Critical 1000
        try {
            if (State.isPlaying) {
                if (name != State.current && name != State.queued) {
                    State.queued := name
                    this.ShowToolTip("Queued: " name)
                }
            } else {
                State.current := name
                State.currentBeat := 0
                State.waitingForFlash := true
                this.ShowToolTip("Playing: " name)
            }
        } finally {
            Critical False
        }
    }
    

    static PlayCurrent() {
        static running := false
        if (running)
            return
        running := true
        
        try {
            while (State.current && (State.repeatMode || State.queued != "")) {
                State.isPlaying := true
                this.PlayOnce(State.current)
                
                if (State.queued != "") {
                    State.current := State.queued
                    State.queued := ""
                } else if (!State.repeatMode) {
                    break
                }
            }
            
            State.isPlaying := false
            State.current := ""
        } finally {
            running := false
        }
    }

    static PlayOnce(songName) {
        song := Songs.map.Get(songName)
        if (!song) {
            this.ShowToolTip("Unknown song: " songName)
            return
        }
        State.current := songName
        State.currentBeat := 0
        State.waitingForFlash := true
        this.ShowToolTip("Playing once: " songName)
    }

    static PlayNextBeat() {
        if (!State.current || State.hotkeysDisabled) {
            return
        }
        song := Songs.map.Get(State.current)
        if (!song) {
            return
        }
        State.currentBeat++

        if (State.currentBeat > song.Length) {
            this.SongCompleted()
            return
        }
        
        beat := song[State.currentBeat]
        this.PlayBeat(beat)
        State.waitingForFlash := true
    }

    static SongCompleted() {
        this.ShowToolTip("Song completed: " State.current)
        if (State.queued != "") {
            State.current := State.queued
            State.queued := ""
            State.currentBeat := 0
            State.waitingForFlash := true
            this.ShowToolTip("Now playing: " State.current)
        } else if (State.repeatMode) {
            State.currentBeat := 0
            State.waitingForFlash := true
        } else {
            State.current := ""
            State.currentBeat := 0
            State.waitingForFlash := false
            this.ShowToolTip("No more songs queued.")
        }
    }

    static PlayBeat(beat) {
        if (Type(beat) = "Array") {
            this.DoublePress(beat[1])
        } else {
            this.SinglePress(beat)
        }
    }

    static SinglePress(key) {
        Send key
    }

    static DoublePress(key) {
        this.SinglePress(key)
        Sleep 100
        this.SinglePress(key)
    }
    
    static TogglePause(*) {
        State.hotkeysDisabled := !State.hotkeysDisabled
        for key, value in Config.keyBindings {
            if (key != "pause" && key != "repeat") {
                Hotkey("$" value, State.hotkeysDisabled ? "Off" : "On")
            }
        }

        if (State.hotkeysDisabled) {
            State.current := ""
            State.queued := ""
            State.currentBeat := 0
            State.waitingForFlash := false
            this.ShowToolTip("All hotkeys DISABLED")
        } else {
            this.ShowToolTip("All hotkeys ENABLED")
        }
    }

    static ToggleRepeatMode(*) {
        State.repeatMode := !State.repeatMode
        this.ShowToolTip("Repeat Mode: " (State.repeatMode ? "ON" : "OFF"))
        if (!State.repeatMode) {
            State.queued := ""
        }
    }

    static ShowToolTip(text, timeout := 1000) {
        ToolTip(text, 10, 10)
        SetTimer(() => ToolTip(), -timeout)
    }
}

class FlashDetector {
    static CheckFlash() {
        if (State.inCooldown || !State.waitingForFlash) {
            return
        }
        currentColor := PixelGetColor(Config.flashDetection["x"], Config.flashDetection["y"])
        currentBrightness := this.GetBrightness(currentColor)

        ; Start flash
        if (currentBrightness - State.lastBrightness >= Config.flashDetection["brightnessThreshold"] && !State.isFlashing) {
            State.isFlashing := true
            State.flashCount++
            SongManager.ShowToolTip("Flash detected! Count: " State.flashCount, 500)

            if (State.waitingForFlash) {
                State.waitingForFlash := false
                SetTimer(SongManager.PlayNextBeat.Bind(SongManager), -1)
            }
        }
        ; End flash
        else if (currentBrightness < State.lastBrightness) {
            State.isFlashing := false
        }

        State.lastBrightness := currentBrightness

        if (State.flashCount >= Songs.map.Get(State.current).Length) {
            State.inCooldown := true
            SetTimer(this.EndCooldown.Bind(this), -Config.flashDetection["cooldownTime"])
        }
    }

    static EndCooldown() {
        State.inCooldown := false
        State.flashCount := 0
    }

    static GetBrightness(color) {
        red := (color >> 16) & 0xFF
        green := (color >> 8) & 0xFF
        blue := color & 0xFF
        return Floor(0.299 * red + 0.587 * green + 0.114 * blue)
    }
}

InitializeHotkeys()
; Display instructions
MsgBox("This is a Patapon2 automate Script, it saves your fingers`n`n"
    . Config.keyBindings["pata"] " - toggle move`n"
    . Config.keyBindings["chika"] " - toggle defend`n"
    . Config.keyBindings["pon"] " - toggle attack`n"
    . Config.keyBindings["don"] " - toggle miracle`n"
    . Config.keyBindings["retreat"] " - toggle retreat`n"
    . Config.keyBindings["charge"] " - toggle charge`n"
    . Config.keyBindings["pause"] " - disable hotkeys`n"
    . Config.keyBindings["repeat"] " - toggle repeat mode`n`n"
    . "Created by Weizhou Xue`n"
    . "Have fun!")

