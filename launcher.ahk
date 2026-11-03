#Requires AutoHotkey v2.0
#SingleInstance Force

Loop Files, "C:\Users\Markus\Documents\AutoHotkey\*.ahk" {
    if (A_LoopFilePath != A_ScriptFullPath)
        Run('"' A_AhkPath '" "' A_LoopFilePath '"')
}
