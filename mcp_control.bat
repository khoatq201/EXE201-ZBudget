@echo off
title MCP Control Center - ZBudget Project
color 0A

:menu
cls
echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                    MCP Control Center                       ║
echo  ║                   ZBudget Project                           ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  [1] Test MCP Connections
echo  [2] Start MCP Servers
echo  [3] Check Integration Status
echo  [4] View MCP Configuration
echo  [5] Open VS Code with MCP
echo  [6] Exit
echo.
set /p choice="Select an option (1-6): "

if "%choice%"=="1" goto test
if "%choice%"=="2" goto start
if "%choice%"=="3" goto check
if "%choice%"=="4" goto config
if "%choice%"=="5" goto vscode
if "%choice%"=="6" goto exit
goto menu

:test
cls
echo Testing MCP Connections...
echo ==========================
call test_mcp_connections.bat
pause
goto menu

:start
cls
echo Starting MCP Servers...
echo ======================
call start_mcp_servers.bat
pause
goto menu

:check
cls
echo Checking Integration Status...
echo =============================
call check_integration.bat
pause
goto menu

:config
cls
echo MCP Configuration:
echo ==================
type .vscode\mcp.json
echo.
pause
goto menu

:vscode
cls
echo Opening VS Code with MCP integration...
echo ======================================
code .
goto menu

:exit
echo.
echo Thank you for using MCP Control Center!
echo MCP servers are now integrated with your ZBudget project.
echo.
pause
exit

