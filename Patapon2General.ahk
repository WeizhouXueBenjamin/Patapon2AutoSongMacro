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
    Send "{" key " down}"
    Sleep 50
    Send "{" key " up}"
}

DoublePress(key) {
    SinglePress(key)
    Sleep 100  ; Short delay between presses
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
    Sleep 430
    SinglePress(pata)
    Sleep 430
    SinglePress(pata)
    Sleep 430
    SinglePress(pon)
}


; The Aria of Attack
attack(*) {
    SinglePress(pon)
    Sleep 430
    SinglePress(pon)
    Sleep 430
    SinglePress(pata)
    Sleep 430
    SinglePress(pon)
}

; The Lament of Defense
defense(*) {
    SinglePress(chika)
    Sleep 430
    SinglePress(chika)
    Sleep 430
    SinglePress(pata)
    Sleep 430
    SinglePress(pon)
}

; The Requiem of Retreat
retreat(*) {
    SinglePress(pon)
    Sleep 430
    SinglePress(pata)
    Sleep 430
    SinglePress(pon)
    Sleep 430
    SinglePress(pata)
}

; The Hold-Tight Hoe-Down
charge(*) {
    SinglePress(pon)
    Sleep 430
    SinglePress(pon)
    Sleep 430
    SinglePress(chika)
    Sleep 430
    SinglePress(chika)
}

; The Song of Miracles
miracle(*) {
    SinglePress(don)
    Sleep 430
    DoublePress(don)
    Sleep 430
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

; === PLAYBACK allSongs ===
PlayOnce(funcName) {
    %funcName%()
    Sleep 2397 ; tempo gap
    return
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
            
            ; Small sleep to allow other threads to run
            if (A_TimeSincePriorHotkey < 100)
                Sleep(10)
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

