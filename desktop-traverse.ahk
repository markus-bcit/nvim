#Requires AutoHotkey v2.0
#SingleInstance Force

SetKeyDelay(20, 20)

SwitchDesktop(n, *) {
    SendEvent("^#{Left 10}")           ; jump to desktop 1
    if (n > 1)
        SendEvent("^#{Right " (n - 1) "}")
}

Loop 9
    Hotkey("#" A_Index, SwitchDesktop.Bind(A_Index))
