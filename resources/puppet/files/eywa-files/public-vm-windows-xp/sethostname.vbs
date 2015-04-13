nHOSTNAME = Wscript.Arguments(0)
sNewName = nHOSTNAME
Set oShell = CreateObject ("WSCript.shell")
sCCS = "HKLM\SYSTEM\CurrentControlSet\"
sTcpipParamsRegPath = sCCS & "Services\Tcpip\Parameters\"
nHOSTNAME = Wscript.Arguments(0)
sNewName = nHOSTNAME
Set oShell = CreateObject ("WSCript.shell")
sCCS = "HKLM\SYSTEM\CurrentControlSet\"
sTcpipParamsRegPath = sCCS & "Services\Tcpip\Parameters\"
sCompNameRegPath = sCCS & "Control\ComputerName\"
With oShell
.RegDelete sTcpipParamsRegPath & "Hostname"
.RegDelete sTcpipParamsRegPath & "NV Hostname"
.RegWrite sCompNameRegPath & "ComputerName\ComputerName", sNewName
.RegWrite sCompNameRegPath & "ActiveComputerName\ComputerName", sNewName
.RegWrite sTcpipParamsRegPath & "Hostname", sNewName
.RegWrite sTcpipParamsRegPath & "NV Hostname", sNewName
End With ' oShell
rem Dim objShell
rem Set objShell = WScript.CreateObject("WScript.Shell")
rem objShell.Run "C:\WINDOWS\system32\shutdown.exe -r -t 0"