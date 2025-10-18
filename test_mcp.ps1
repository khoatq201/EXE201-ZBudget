Write-Host "Testing MCP Integration..." -ForegroundColor Cyan

# Test MongoDB connection
Write-Host "1. Testing MongoDB Connection..." -ForegroundColor Yellow
try {
    $result = mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" --quiet 2>$null
    if ($result -match "ok.*1") {
        Write-Host "MongoDB Database: Connected" -ForegroundColor Green
    } else {
        Write-Host "MongoDB Database: Not connected" -ForegroundColor Red
    }
} catch {
    Write-Host "MongoDB Database: Connection failed" -ForegroundColor Red
}

# Test file paths
Write-Host "2. Testing MCP Server Files..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Admin\mongodb-mcp-server\dist\index.js") {
    Write-Host "MongoDB MCP Server files: Found" -ForegroundColor Green
} else {
    Write-Host "MongoDB MCP Server files: Not found" -ForegroundColor Red
}

if (Test-Path "C:\Users\Admin\serena") {
    Write-Host "Serena MCP Server directory: Found" -ForegroundColor Green
} else {
    Write-Host "Serena MCP Server directory: Not found" -ForegroundColor Red
}

# Test VS Code config
Write-Host "3. Testing VS Code MCP Configuration..." -ForegroundColor Yellow
if (Test-Path ".vscode\mcp.json") {
    Write-Host "VS Code MCP configuration: Found" -ForegroundColor Green
} else {
    Write-Host "VS Code MCP configuration: Not found" -ForegroundColor Red
}

Write-Host "MCP Test completed!" -ForegroundColor Cyan
