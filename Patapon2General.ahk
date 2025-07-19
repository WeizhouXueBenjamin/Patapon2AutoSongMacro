#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 3


; === CONFIGURATION ===
; Change these keys if your controls are different
pata := "a"    ; Key for pata
chika := "w"   ; Key for chika
pon := "d"  ; Key for pon
don := "s"  ; Key for don
chargeKey := "shift"  ; Key for charge
retreatKey := "ctrl"  ; Key for retreat
pauseKey := "p"  ; Key for pause
repeatKey := "F1"
allHotkeysDisabled := false  ; Flag to disable all hotkeys
allHotKeysExceptDisable := [pata, chika, pon, don, chargeKey, retreatKey, repeatKey]
allSongs := Map(
    "move", move,
    "attack", attack,
    "defense", defense,
    "retreat", retreat,
    "charge", charge,
    "miracle", miracle
)
beat := 500 ; ms per beat (adjust as needed)
tempo := beat*5 ; ms per beat (adjust as needed)


; =====================
Hotkey "$" pata,  (*) => QueueSong("move")    
Hotkey "$" chika, (*) => QueueSong("defense") 
Hotkey "$" pon,   (*) => QueueSong("attack")  
Hotkey "$" don,   (*) => QueueSong("miracle") 
Hotkey "$" chargeKey, (*) => QueueSong("charge")  
Hotkey "$" retreatKey,(*) => QueueSong("retreat") 
Hotkey "$" pauseKey, paused
Hotkey "$" repeatKey, ToggleRepeatMode

; =====================

SinglePress(key) {
    Send key
    return
}

DoublePress(key) {
    SinglePress(key)
    HP_Sleep(100)  ; Short delay between presses
    SinglePress(key)
}

paused(*) {
    global allHotkeysDisabled,current, queued
    allHotkeysDisabled := !allHotkeysDisabled
    if (allHotkeysDisabled) {
        Hotkey pata, "Off"
        Hotkey chika, "Off"
        Hotkey pon, "Off"
        Hotkey don, "Off"
        Hotkey chargeKey, "Off"
        Hotkey retreatKey, "Off"
        current := ""  ; Clear current song
        queued := ""   ; Clear queued song
        ShowToolTip("All hotkeys DISABLED")
        
    }
    else {
        Hotkey pata, "On"
        Hotkey chika, "On"
        Hotkey pon, "On"
        Hotkey don, "On"
        Hotkey chargeKey, "On"
        Hotkey retreatKey, "On"
        ShowToolTip("All hotkeys ENABLED")
    }
}

; --- Songs ---

; The March of Mobility
move(*) {
    SinglePress(pata)
    HP_Sleep(beat)
    SinglePress(pata)
    HP_Sleep(beat)
    SinglePress(pata)
    HP_Sleep(beat)
    SinglePress(pon)
}


; The Aria of Attack
attack(*) {
    SinglePress(pon)
    HP_Sleep(beat)
    SinglePress(pon)
    HP_Sleep(beat)
    SinglePress(pata)
    HP_Sleep(beat)
    SinglePress(pon)
}

; The Lament of Defense
defense(*) {
    SinglePress(chika)
    HP_Sleep(beat)
    SinglePress(chika)
    HP_Sleep(beat)
    SinglePress(pata)
    HP_Sleep(beat)
    SinglePress(pon)
}

; The Requiem of Retreat
retreat(*) {
    SinglePress(pon)
    HP_Sleep(beat)
    SinglePress(pata)
    HP_Sleep(beat)
    SinglePress(pon)
    HP_Sleep(beat)
    SinglePress(pata)
}

; The Hold-Tight Hoe-Down
charge(*) {
    SinglePress(pon)
    HP_Sleep(beat)
    SinglePress(pon)
    HP_Sleep(beat)
    SinglePress(chika)
    HP_Sleep(beat)
    SinglePress(chika)
}

; The Song of Miracles
miracle(*) {
    SinglePress(don)
    HP_Sleep(beat)
    DoublePress(don)
    HP_Sleep(beat)
    DoublePress(don)
}

; ==== repeatMode =====
repeatMode := false
current := ""
queued := ""
isPlaying := false


ToggleRepeatMode(*) {
    global repeatMode
    repeatMode := !repeatMode
    ShowToolTip("Repeat Mode: " (repeatMode ? "ON" : "OFF"))
    if (!repeatMode) {
        current := "" ; Stop repeating
        queued := ""
    }
}

QueueSong(funcName) {
    global repeatMode, current, queued, isPlaying
    
    ; If not in Repeat Mode, play once and exit
    if (!repeatMode) {
        PlayOnce(funcName)
        return
    }
    
    
    Critical 1000 ; Timeout after 1 second if deadlock occurs
    try {
        if (isPlaying) {
            ; If playing, queue next function
            if (funcName != current && funcName != queued) {
                queued := funcName
                ShowToolTip("Queued: " funcName)
            }
        } else {
            current := funcName
            SetTimer(PlayCurrent, -1) ; Defer playback to a new thread
        }
    } finally {
        Critical False ; Always turn off Critical when done
    }
}

; --- High-res timer functions ---
global tempoError := 0
HP_Sleep(timeInMs) {
    global tempoError
    static freq := 0, init := DllCall("QueryPerformanceFrequency", "Int64*", &freq)
    
    ; 1. Calculate adjusted sleep time (with error compensation)
    adjustedMS := timeInMs - tempoError
    adjustedMS := Max(adjustedMS, 10)  ; Enforce minimum 10ms sleep
    
    ; 2. Convert to QPC units (integer math only)
    DllCall("QueryPerformanceCounter", "Int64*", &start := 0)
    target := start + Round((adjustedMS * freq) / 1000)
    
    ; 3. High-precision wait (non-blocking)
    while (DllCall("QueryPerformanceCounter", "Int64*", &now := 0), now < target)
        Sleep 0
    
    ; 4. Calculate actual duration and update error
    actualMS := (now - start) * 1000 / freq  ; Floating-point for precision
    tempoError := actualMS - timeInMs        ; Positive = too slow, Negative = too fast
    
    ; 5. Optional debug display
    ; ShowToolTip("Target: " timeInMs "ms`nActual: " Round(actualMS,1) "ms`nError: " Round(tempoError,1) "ms")
    /*
    static freq := 0, init := DllCall("QueryPerformanceFrequency", "Int64*", &freq)
    DllCall("QueryPerformanceCounter", "Int64*", &start := 0)
    target := start + (timeInMs * freq) // 1000
    
    while (true) {
        DllCall("QueryPerformanceCounter", "Int64*", &now := 0)
        if (now >= target)
            break
        
        HP_Sleep(0)  ; Allows hotkeys to interrupt
    }
        */
}
; --- image detection ---
flashX := 116
flashY := 1062
flashInterval := 50    ; Time (ms) between checks (adjust based on game speed)
brightnessThreshold := 30
cooldownTime := 1000         ; Ignore flashes for 2s after 4-flash sequence

flashCount := 0
isFlashing := false
inCooldown := false
lastBrightness := 0  

; periodically check flash around the screen to determine tempos
SetTimer CheckFlash, flashInterval
CheckFlash() {
    global flashCount, isFlashing, inCooldown, lastBrightness
    
    if (inCooldown) {
        ; ShowToolTip("Flash ignored (cooldown)", 500)
        return
    }
    
    currentColor := PixelGetColor(flashX, flashY)
    currentBrightness := GetBrightness(currentColor)
    ; ShowToolTip("Current brightness: " currentBrightness, 300)
    
    ; Detect flash start
    if (currentBrightness - lastBrightness >= brightnessThreshold && !isFlashing) {
        isFlashing := true
        flashCount++
        ShowToolTip(flashCount " flashes detected", 500)
        
        if (flashCount == 1) {
            SetTimer defense, -1 ; testing
        }
        
        if (flashCount >= 4) {
            inCooldown := true
            SetTimer EndCooldown, -cooldownTime
            ; ShowToolTip("Starting cooldown...", 1000)
        }
    }
    ; Detect flash end
    else if (currentBrightness < lastBrightness) {
        isFlashing := false
    }
    
    lastBrightness := currentBrightness
}

; Calculate brightness from color (0-255)
GetBrightness(color) {
    ; Convert hex to RGB
    red := (color >> 16) & 0xFF
    green := (color >> 8) & 0xFF
    blue := color & 0xFF
    
    ; Perceived brightness formula
    return Floor(0.299 * red + 0.587 * green + 0.114 * blue)
}

; cooldown reset
EndCooldown() {
    global inCooldown, flashCount
    ShowToolTip("Cooldown ended, ready for next sequence!", 500)
    inCooldown := false
    flashCount := 0
}

PlayOnce(funcName) {
    %funcName%()
}

PlayCurrent() {
    global current, queued, isPlaying, repeatMode
    
    static running := false
    if (running)
        return
    running := true
    
    try {
        while (current && (repeatMode || queued != "")) {
            isPlaying := true
            PlayOnce(current)
            
            if (queued != "") {
                current := queued
                queued := ""
            } else if (!repeatMode) {
                break
            }
            
            /*; Small sleep to allow other threads to run
            if (A_TimeSincePriorHotkey < 100){
                HP_Sleep(10)
            }*/
                
        }
        
        isPlaying := false
        current := "" ; Clear current when done
    } finally {
        running := false
    }
}

ShowToolTip(text, timeout := 2000) {
    ToolTip(text, 10, 50)
    SetTimer(() => ToolTip(), -timeout)
}
; Display instructions
MsgBox "This is a Patapon2 automate Script, it saves your fingers`n`n" pata " - toggle move`n" chika " - toggle defend`n" pon " - toggle attack`n" don " - toggle miracle`n" retreatKey " - toggle retreat`n" chargeKey " - toggle charge`n" pauseKey " - disable hotkeys`n" repeatKey " - toggle repeat mode`n`nCreated by Weizhou Xue`nHave fun!"

