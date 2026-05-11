' ========================================
' iBridge - PowerShell OneDrive Fix (VBS)
' ========================================
' This VB script fixes the PowerShell OneDrive configuration issue
' It can be run by double-clicking in Windows File Explorer
' No command line or batch file permissions needed

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objWshShell = CreateObject("WScript.Shell")

REM Define paths
strOneDrivePath = objWshShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell"
strConfigFile = strOneDrivePath & "\powershell.config.json"
strBackupFile = strOneDrivePath & "\powershell.config.json.backup"
strDisabledFile = strOneDrivePath & "\powershell.config.json.disabled"

REM Show header
MsgBox "iBridge - PowerShell OneDrive Fix" & vbCrLf & vbCrLf & "This script will fix the PowerShell OneDrive configuration issue.", vbInformation, "iBridge Fix"

REM Check if OneDrive folder exists
If Not objFSO.FolderExists(strOneDrivePath) Then
    MsgBox "PowerShell OneDrive folder not found." & vbCrLf & "No issue to fix.", vbInformation, "iBridge - No Issue Found"
    WScript.Quit(0)
End If

REM Check if config file exists
If Not objFSO.FileExists(strConfigFile) Then
    MsgBox "PowerShell config file not found." & vbCrLf & "No issue to fix.", vbInformation, "iBridge - No Issue Found"
    WScript.Quit(0)
End If

REM Check if already fixed
If objFSO.FileExists(strDisabledFile) Then
    MsgBox "✓ Fix is already applied!" & vbCrLf & vbCrLf & "The problematic file has already been disabled." & vbCrLf & "Your system should work normally now.", vbInformation, "iBridge - Already Fixed"
    WScript.Quit(0)
End If

REM Create backup if it doesn't exist
If Not objFSO.FileExists(strBackupFile) Then
    On Error Resume Next
    objFSO.CopyFile strConfigFile, strBackupFile
    On Error Goto 0
End If

REM Rename the file
On Error Resume Next
objFSO.MoveFile strConfigFile, strDisabledFile
If Err.Number = 0 Then
    MsgBox "✓ Fix Applied Successfully!" & vbCrLf & vbCrLf & "The problematic PowerShell configuration file has been disabled." & vbCrLf & vbCrLf & "Your terminal and development environment should now work correctly.", vbInformation, "iBridge - Fix Complete"
    WScript.Quit(0)
Else
    MsgBox "✗ Error: Could not disable the file" & vbCrLf & vbCrLf & "Error: " & Err.Description & vbCrLf & vbCrLf & "This might require Administrator privileges." & vbCrLf & "Try running as Administrator.", vbCritical, "iBridge - Error"
    WScript.Quit(1)
End If
