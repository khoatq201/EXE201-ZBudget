# Simple MCP Test Script
Write-Host "Testing MCP Integration..." -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Test MongoDB connection
Write-Host "`n1. Testing MongoDB Connection..." -ForegroundColor Yellow
try {
    $mongodbTest = mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" --quiet 2>$null
    if ($mongodbTest -match "ok.*1") {
        Write-Host "✓ MongoDB Database: Connected" -ForegroundColor Green
    } else {
        Write-Host "✗ MongoDB Database: Not connected" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ MongoDB Database: Connection failed" -ForegroundColor Red
}

# Test MongoDB MCP Server files
Write-Host "`n2. Testing MongoDB MCP Server Files..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Admin\mongodb-mcp-server\dist\index.js") {
    Write-Host "✓ MongoDB MCP Server files found" -ForegroundColor Green
} else {
    Write-Host "✗ MongoDB MCP Server files not found" -ForegroundColor Red
}

# Test Serena MCP Server directory
Write-Host "`n3. Testing Serena MCP Server..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Admin\serena") {
    Write-Host "✓ Serena MCP Server directory found" -ForegroundColor Green
} else {
    Write-Host "✗ Serena MCP Server directory not found" -ForegroundColor Red
}

# Test UV installation
Write-Host "`n4. Testing UV Installation..." -ForegroundColor Yellow
try {
    $uvVersion = uv --version 2>$null
    if ($uvVersion) {
        Write-Host "✓ UV installed: $uvVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ UV not found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ UV not available" -ForegroundColor Red
}

# Test Node.js installation
Write-Host "`n5. Testing Node.js Installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✓ Node.js installed: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ Node.js not found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Node.js not available" -ForegroundColor Red
}

# Test VS Code MCP configuration
Write-Host "`n6. Testing VS Code MCP Configuration..." -ForegroundColor Yellow
if (Test-Path ".vscode\mcp.json") {
    Write-Host "✓ VS Code MCP configuration found" -ForegroundColor Green
    $mcpConfig = Get-Content ".vscode\mcp.json" -Raw
    if ($mcpConfig -match "serena" -and $mcpConfig -match "mongodb") {
        Write-Host "✓ Both Serena and MongoDB MCP servers configured" -ForegroundColor Green
    } else {
        Write-Host "✗ MCP configuration incomplete" -ForegroundColor Red
    }
} else {
    Write-Host "✗ VS Code MCP configuration not found" -ForegroundColor Red
}

Write-Host "`nMCP Test completed!" -ForegroundColor Cyan
