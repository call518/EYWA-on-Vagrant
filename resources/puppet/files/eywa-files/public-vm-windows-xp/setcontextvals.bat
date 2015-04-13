REM @echo off
setlocal ENABLEDELAYEDEXPANSION
copy d:\context.sh c:\admin\context.sh
c:\admin\unix2dos c:\admin\context.sh
for /F "eol=# tokens=1,2* delims==" %%i in (c:\admin\context.sh) do (set %%i=%%j)
call d:\sethostname.vbs %HOSTNAME%
net user %USERNAME% %PASSWORD%
netsh int ip set address name="Local Area Connection" source=static addr=%IP_PUBLIC% mask=255.255.255.0 gateway=192.168.33.2 gwmetric=0
netsh int ip set dns name="Local Area Connection" source=static addr=192.168.33.11 primary
if exist C:\admin\first_initialization (
	echo Bypass Initialization
) else (
	echo "Completed Initialization" > C:\admin\first_initialization
	netsh firewall set icmpsetting 8 enable
	shutdown /r /t 1
)
