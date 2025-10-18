@echo off
echo Testing MCP Server Connections...

echo.
echo [1/4] Testing UV installation...
uv --version
if %errorlevel% neq 0 (
    echo ❌ UV not found
    exit /b 1
) else (
    echo ✅ UV is installed
)

echo.
echo [2/4] Testing Node.js installation...
node --version
if %errorlevel% neq 0 (
    echo ❌ Node.js not found
    exit /b 1
) else (
    echo ✅ Node.js is installed
)

echo.
echo [3/4] Testing MongoDB connection...
mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" --quiet
if %errorlevel% neq 0 (
    echo ❌ MongoDB connection failed
    echo Please ensure MongoDB is running on localhost:27017
    exit /b 1
) else (
    echo ✅ MongoDB connection successful
)

echo.
echo [4/4] Testing MCP server files...
if exist "C:\Users\Admin\serena" (
    echo ✅ Serena directory found
) else (
    echo ❌ Serena directory not found at C:\Users\Admin\serena
)

if exist "C:\Users\Admin\mongodb-mcp-server\dist\index.js" (
    echo ✅ MongoDB MCP server file found
) else (
    echo ❌ MongoDB MCP server file not found
)

echo.
echo ✅ All MCP prerequisites are ready!
echo.
echo You can now:
echo 1. Run start_mcp_servers.bat to start MCP servers
echo 2. Open Cursor IDE and use MCP tools
echo.
pause
