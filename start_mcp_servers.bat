@echo off
echo Starting MCP Servers for Cursor IDE...

echo.
echo [1/3] Checking prerequisites...

REM Check if UV is installed
uv --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: UV is not installed or not in PATH
    echo Please install UV: https://github.com/astral-sh/uv
    pause
    exit /b 1
)

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js: https://nodejs.org/
    pause
    exit /b 1
)

REM Check if MongoDB is running
mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: MongoDB might not be running
    echo Please start MongoDB service
)

echo.
echo [2/3] Starting Serena MCP Server...
start "Serena MCP Server" cmd /k "uv run --directory C:\Users\Admin\serena serena-mcp-server --context ide-assistant --project %CD%"

echo.
echo [3/3] Starting MongoDB MCP Server...
start "MongoDB MCP Server" cmd /k "node C:\Users\Admin\mongodb-mcp-server\dist\index.js"

echo.
echo ✅ MCP Servers started successfully!
echo.
echo Serena MCP Server: AI development assistance
echo MongoDB MCP Server: Database operations
echo.
echo You can now use MCP tools in Cursor IDE
echo.
pause
