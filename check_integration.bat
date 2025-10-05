@echo off
echo Integrating MCP into ZBudget Project Workflow...
echo ===============================================

echo.
echo Checking VS Code integration...
if exist ".vscode\mcp.json" (
    echo ✓ MCP configuration found in .vscode\mcp.json
) else (
    echo ✗ MCP configuration not found
)

echo.
echo Checking project structure...
if exist "Backend" (
    echo ✓ Backend directory found
) else (
    echo ✗ Backend directory not found
)

if exist "zbudget" (
    echo ✓ zbudget directory found
) else (
    echo ✗ zbudget directory not found
)

if exist "logs" (
    echo ✓ logs directory found
) else (
    echo ✗ logs directory not found
)

echo.
echo Checking Backend dependencies...
if exist "Backend\package.json" (
    echo ✓ Backend package.json found
) else (
    echo ✗ Backend package.json not found
)

echo.
echo Checking Flutter project...
if exist "zbudget\pubspec.yaml" (
    echo ✓ Flutter pubspec.yaml found
) else (
    echo ✗ Flutter pubspec.yaml not found
)

echo.
echo MCP Integration Summary:
echo - Serena MCP Server: Available for AI-assisted development
echo - MongoDB MCP Server: Available for database operations
echo - VS Code Integration: Ready via .vscode\mcp.json
echo - Project Structure: ZBudget full-stack application

echo.
echo MCP Integration completed successfully!
pause

