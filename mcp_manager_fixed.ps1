# MCP Server Manager for ZBudget Project
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "status", "test", "restart")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"

# MCP Server configurations
$MCP_SERVERS = @{
    "mongodb" = @{
        "name" = "MongoDB MCP Server"
        "command" = "node"
        "args" = @("C:\Users\Admin\mongodb-mcp-server\dist\index.js")
        "env" = @{
            "MONGODB_URI" = "mongodb://localhost:27017/zbudget"
        }
        "process_name" = "node"
    }
    "serena" = @{
        "name" = "Serena MCP Server"
        "command" = "uv"
        "args" = @("run", "--directory", "C:\Users\Admin\serena", "serena-mcp-server", "--context", "ide-assistant", "--project", "D:\Document\EXE201")
        "env" = @{}
        "process_name" = "serena-mcp-server"
    }
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-MongoDBConnection {
    try {
        $result = mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')" --quiet 2>$null
        return $result -match "ok.*1"
    }
    catch {
        return $false
    }
}

function Start-MCPServer {
    param([string]$ServerName, [hashtable]$Config)
    
    Write-ColorOutput "Starting $($Config.name)..." "Yellow"
    
    try {
        $envVars = $Config.env.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
        
        if ($envVars) {
            foreach ($env in $envVars) {
                $key, $value = $env.Split("=", 2)
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
        
        Start-Process -FilePath $Config.command -ArgumentList $Config.args -WindowStyle Minimized
        Write-ColorOutput "✓ $($Config.name) started successfully" "Green"
    }
    catch {
        Write-ColorOutput "✗ Failed to start $($Config.name): $($_.Exception.Message)" "Red"
    }
}

function Stop-MCPServer {
    param([string]$ServerName, [hashtable]$Config)
    
    Write-ColorOutput "Stopping $($Config.name)..." "Yellow"
    
    try {
        $processes = Get-Process -Name $Config.process_name -ErrorAction SilentlyContinue
        if ($processes) {
            $processes | Stop-Process -Force
            Write-ColorOutput "✓ $($Config.name) stopped successfully" "Green"
        } else {
            Write-ColorOutput "ℹ $($Config.name) was not running" "Blue"
        }
    }
    catch {
        Write-ColorOutput "✗ Failed to stop $($Config.name): $($_.Exception.Message)" "Red"
    }
}

function Get-MCPStatus {
    Write-ColorOutput "MCP Server Status:" "Cyan"
    Write-ColorOutput "=================" "Cyan"
    
    # Check MongoDB connection
    if (Test-MongoDBConnection) {
        Write-ColorOutput "✓ MongoDB Database: Connected" "Green"
    } else {
        Write-ColorOutput "✗ MongoDB Database: Not connected" "Red"
    }
    
    # Check MCP server processes
    foreach ($server in $MCP_SERVERS.GetEnumerator()) {
        $processes = Get-Process -Name $server.Value.process_name -ErrorAction SilentlyContinue
        if ($processes) {
            Write-ColorOutput "✓ $($server.Value.name): Running" "Green"
        } else {
            Write-ColorOutput "✗ $($server.Value.name): Not running" "Red"
        }
    }
}

function Test-MCPConnections {
    Write-ColorOutput "Testing MCP Connections..." "Cyan"
    Write-ColorOutput "=========================" "Cyan"
    
    # Test MongoDB
    if (Test-MongoDBConnection) {
        Write-ColorOutput "✓ MongoDB connection successful" "Green"
    } else {
        Write-ColorOutput "✗ MongoDB connection failed" "Red"
    }
    
    # Test file availability
    if (Test-Path "C:\Users\Admin\mongodb-mcp-server\dist\index.js") {
        Write-ColorOutput "✓ MongoDB MCP Server files found" "Green"
    } else {
        Write-ColorOutput "✗ MongoDB MCP Server files not found" "Red"
    }
    
    if (Test-Path "C:\Users\Admin\serena") {
        Write-ColorOutput "✓ Serena MCP Server directory found" "Green"
    } else {
        Write-ColorOutput "✗ Serena MCP Server directory not found" "Red"
    }
}

# Main execution
switch ($Action) {
    "start" {
        Write-ColorOutput "Starting MCP Servers..." "Cyan"
        foreach ($server in $MCP_SERVERS.GetEnumerator()) {
            Start-MCPServer -ServerName $server.Key -Config $server.Value
        }
    }
    "stop" {
        Write-ColorOutput "Stopping MCP Servers..." "Cyan"
        foreach ($server in $MCP_SERVERS.GetEnumerator()) {
            Stop-MCPServer -ServerName $server.Key -Config $server.Value
        }
    }
    "restart" {
        Write-ColorOutput "Restarting MCP Servers..." "Cyan"
        foreach ($server in $MCP_SERVERS.GetEnumerator()) {
            Stop-MCPServer -ServerName $server.Key -Config $server.Value
            Start-Sleep -Seconds 2
            Start-MCPServer -ServerName $server.Key -Config $server.Value
        }
    }
    "test" {
        Test-MCPConnections
    }
    "status" {
        Get-MCPStatus
    }
}

Write-ColorOutput "`nMCP Manager operation completed!" "Cyan"


