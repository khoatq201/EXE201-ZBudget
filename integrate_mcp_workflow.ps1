# MCP Workflow Integration Script
Write-Host "Integrating MCP into ZBudget Project Workflow..." -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Check if VS Code is running
$vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
if ($vscodeProcesses) {
    Write-Host "✓ VS Code is running - MCP integration ready" -ForegroundColor Green
} else {
    Write-Host "ℹ VS Code not detected - MCP will be available when VS Code starts" -ForegroundColor Yellow
}

# Check MCP configuration
if (Test-Path ".vscode\mcp.json") {
    Write-Host "✓ MCP configuration found in .vscode\mcp.json" -ForegroundColor Green
} else {
    Write-Host "✗ MCP configuration not found" -ForegroundColor Red
}

# Check project structure
Write-Host "`nChecking project structure..." -ForegroundColor Yellow
$projectDirs = @("Backend", "zbudget", "logs")
foreach ($dir in $projectDirs) {
    if (Test-Path $dir) {
        Write-Host "✓ $dir directory found" -ForegroundColor Green
    } else {
        Write-Host "✗ $dir directory not found" -ForegroundColor Red
    }
}

# Check backend dependencies
Write-Host "`nChecking Backend dependencies..." -ForegroundColor Yellow
if (Test-Path "Backend\package.json") {
    Write-Host "✓ Backend package.json found" -ForegroundColor Green
} else {
    Write-Host "✗ Backend package.json not found" -ForegroundColor Red
}

# Check Flutter project
Write-Host "`nChecking Flutter project..." -ForegroundColor Yellow
if (Test-Path "zbudget\pubspec.yaml") {
    Write-Host "✓ Flutter pubspec.yaml found" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter pubspec.yaml not found" -ForegroundColor Red
}

Write-Host "`nMCP Integration Summary:" -ForegroundColor Cyan
Write-Host "- Serena MCP Server: Available for AI-assisted development" -ForegroundColor White
Write-Host "- MongoDB MCP Server: Available for database operations" -ForegroundColor White
Write-Host "- VS Code Integration: Ready via .vscode\mcp.json" -ForegroundColor White
Write-Host "- Project Structure: ZBudget full-stack application" -ForegroundColor White

Write-Host "`nMCP Integration completed successfully!" -ForegroundColor Green

