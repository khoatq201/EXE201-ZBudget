@echo off
echo Testing MCP Server Connections...
echo.

echo [1/3] Testing MongoDB Connection...
mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" --quiet
if %errorlevel% equ 0 (
    echo ✓ MongoDB connection successful
) else (
    echo ✗ MongoDB connection failed
)

echo.
echo [2/3] Testing MongoDB MCP Server...
echo Testing MongoDB MCP Server availability...
if exist "C:\Users\Admin\mongodb-mcp-server\dist\index.js" (
    echo ✓ MongoDB MCP Server files found
) else (
    echo ✗ MongoDB MCP Server files not found
)

echo.
echo [3/3] Testing Serena MCP Server...
echo Testing Serena MCP Server availability...
if exist "C:\Users\Admin\serena" (
    echo ✓ Serena MCP Server directory found
) else (
    echo ✗ Serena MCP Server directory not found
)

echo.
echo MCP Connection Test Complete!
pause

