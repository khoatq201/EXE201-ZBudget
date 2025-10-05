@echo off
echo Starting MCP Servers for ZBudget Project...
echo.

echo [1/2] Starting MongoDB MCP Server...
start "MongoDB MCP Server" cmd /k "cd /d D:\Document\EXE201 && set MONGODB_URI=mongodb://localhost:27017/zbudget && node C:\Users\Admin\mongodb-mcp-server\dist\index.js"

echo [2/2] Starting Serena MCP Server...
start "Serena MCP Server" cmd /k "cd /d D:\Document\EXE201 && uv run --directory C:\Users\Admin\serena serena-mcp-server --context ide-assistant --project D:\Document\EXE201"

echo.
echo MCP Servers started successfully!
echo - MongoDB MCP Server: Running on stdio
echo - Serena MCP Server: Running on stdio
echo.
echo You can now use these MCP servers in your IDE.
pause

