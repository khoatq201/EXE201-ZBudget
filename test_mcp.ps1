Write-Host "Testing MCP Connections..." -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

Write-Host "[1/3] Testing MongoDB Connection..." -ForegroundColor Yellow
try {
    $result = mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" --quiet 2>$null
    if ($result -match "ok.*1") {
        Write-Host "✓ MongoDB connection successful" -ForegroundColor Green
    } else {
        Write-Host "✗ MongoDB connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ MongoDB connection failed" -ForegroundColor Red
}

Write-Host "[2/3] Testing MongoDB MCP Server..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Admin\mongodb-mcp-server\dist\index.js") {
    Write-Host "✓ MongoDB MCP Server files found" -ForegroundColor Green
} else {
    Write-Host "✗ MongoDB MCP Server files not found" -ForegroundColor Red
}

Write-Host "[3/3] Testing Serena MCP Server..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Admin\serena") {
    Write-Host "✓ Serena MCP Server directory found" -ForegroundColor Green
} else {
    Write-Host "✗ Serena MCP Server directory not found" -ForegroundColor Red
}

Write-Host "MCP Test completed!" -ForegroundColor Cyan

