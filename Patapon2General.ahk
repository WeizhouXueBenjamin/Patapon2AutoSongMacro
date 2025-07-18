#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreads 1


; === CONFIGURATION ===
; Change these keys if your controls are different
pata := "a"    ; Key for pata
chika := "w"   ; Key for chika
pon := "d"  ; Key for pon
don := "s"  ; Key for don
chargeKey := "shift"  ; Key for charge
retreatKey := "ctrl"  ; Key for retreat
pauseKey := "p"  ; Key for pause
allHotkeysDisabled := false  ; Flag to disable all hotkeys

; =====================
Hotkey "$" pata, move
Hotkey "$" chika, defense
Hotkey "$" pon, attack
Hotkey "$" don, miracle
Hotkey "$" chargeKey, charge
Hotkey "$" retreatKey, retreat
Hotkey "$" pauseKey, paused

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
    global allHotkeysDisabled
    allHotkeysDisabled := !allHotkeysDisabled
    if (allHotkeysDisabled) {
        Hotkey pata, "Off"
        Hotkey chika, "Off"
        Hotkey pon, "Off"
        Hotkey don, "Off"
        Hotkey chargeKey, "Off"
        Hotkey retreatKey, "Off"
        ToolTip "All hotkeys DISABLED", 10, 10
        
    }
    else {
        Hotkey pata, "On"
        Hotkey chika, "On"
        Hotkey pon, "On"
        Hotkey don, "On"
        Hotkey chargeKey, "On"
        Hotkey retreatKey, "On"
        ToolTip "All hotkeys ENABLED", 10, 10
    }
    SetTimer (*) => ToolTip(), -2000
}

; --- Songs ---

; The March of Mobility
move(*) {
    SinglePress(pata)
    Sleep 420
    SinglePress(pata)
    Sleep 420
    SinglePress(pata)
    Sleep 420
    SinglePress(pon)
}


; The Aria of Attack
attack(*) {
    SinglePress(pon)
    Sleep 420
    SinglePress(pon)
    Sleep 420
    SinglePress(pata)
    Sleep 420
    SinglePress(pon)
}

; The Lament of Defense
defense(*) {
    SinglePress(chika)
    Sleep 420
    SinglePress(chika)
    Sleep 420
    SinglePress(pata)
    Sleep 420
    SinglePress(pon)
}

; The Requiem of Retreat
retreat(*) {
    SinglePress(pon)
    Sleep 420
    SinglePress(pata)
    Sleep 420
    SinglePress(pon)
    Sleep 420
    SinglePress(pata)
}

; The Hold-Tight Hoe-Down
charge(*) {
    SinglePress(pon)
    Sleep 420
    SinglePress(pon)
    Sleep 420
    SinglePress(chika)
    Sleep 420
    SinglePress(chika)
}

; The Song of Miracles
miracle(*) {
    SinglePress(don)
    Sleep 420
    DoublePress(don)
    Sleep 420
    DoublePress(don)
}

; Display instructions
MsgBox "This is a Patapon2 automate Script, it saves your fingers`n`n" pata " - toggle move`n" chika " - toggle defend`n" pon " - toggle attack`n" don " - toggle miracle`n" retreatKey " - toggle retreat`n" chargeKey " - toggle charge`n" pauseKey " - disable hotkeys`n`nCreated by Weizhou Xue`nHave fun!"

