# MCP (Model Context Protocol) Setup Guide

## Tổng quan
Dự án ZBudget đã được tích hợp với các MCP server để cải thiện khả năng phát triển và quản lý dự án.

## Các MCP Server được cấu hình

### 1. Serena MCP Server
- **Mục đích**: Hỗ trợ phát triển với AI assistant
- **Context**: ide-assistant
- **Project**: D:\Document\EXE201
- **Command**: `uv run --directory C:\Users\Admin\serena serena-mcp-server --context ide-assistant --project D:\Document\EXE201`

### 2. MongoDB MCP Server
- **Mục đích**: Quản lý và truy vấn database MongoDB
- **Database**: mongodb://localhost:27017/zbudget
- **Command**: `node C:\Users\Admin\mongodb-mcp-server\dist\index.js`

## Cách sử dụng

### Khởi động MCP Servers

#### Cách 1: Sử dụng PowerShell Manager (Khuyến nghị)
```powershell
# Kiểm tra trạng thái
.\mcp_manager.ps1 -Action status

# Khởi động tất cả servers
.\mcp_manager.ps1 -Action start

# Dừng tất cả servers
.\mcp_manager.ps1 -Action stop

# Khởi động lại
.\mcp_manager.ps1 -Action restart

# Test kết nối
.\mcp_manager.ps1 -Action test
```

#### Cách 2: Sử dụng Batch Script
```cmd
# Khởi động tất cả servers
start_mcp_servers.bat

# Test kết nối
test_mcp_connections.bat
```

### Cấu hình trong VS Code

File `.vscode/mcp.json` đã được cấu hình với:
```json
{
  "servers": {
    "serena": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "C:\\Users\\Admin\\serena",
        "serena-mcp-server",
        "--context",
        "ide-assistant",
        "--project",
        "${workspaceFolder}"
      ]
    },
    "mongodb": {
      "type": "stdio",
      "command": "node",
      "args": ["C:/Users/Admin/mongodb-mcp-server/dist/index.js"],
      "env": {
        "MONGODB_URI": "mongodb://localhost:27017/zbudget"
      }
    }
  }
}
```

## Yêu cầu hệ thống

### Phần mềm cần thiết
- **Node.js**: v24.9.0 (đã cài đặt)
- **UV**: v0.8.22 (đã cài đặt)
- **MongoDB**: Đang chạy trên localhost:27017
- **PowerShell**: Để chạy mcp_manager.ps1

### Thư mục cần thiết
- `C:\Users\Admin\serena` - Serena MCP Server
- `C:\Users\Admin\mongodb-mcp-server\dist\index.js` - MongoDB MCP Server

## Troubleshooting

### Lỗi thường gặp

1. **MongoDB không kết nối được**
   ```powershell
   # Kiểm tra MongoDB service
   net start MongoDB
   
   # Test kết nối
   mongosh "mongodb://localhost:27017/zbudget" --eval "db.runCommand('ping')"
   ```

2. **Serena MCP Server không khởi động**
   ```powershell
   # Kiểm tra UV installation
   uv --version
   
   # Test Serena server
   uv run --directory "C:\Users\Admin\serena" serena-mcp-server --help
   ```

3. **MongoDB MCP Server không tìm thấy**
   ```powershell
   # Kiểm tra file tồn tại
   Test-Path "C:\Users\Admin\mongodb-mcp-server\dist\index.js"
   ```

### Logs và Debugging

- **MongoDB logs**: Kiểm tra MongoDB service logs
- **Serena logs**: Chạy với `--log-level DEBUG`
- **MCP logs**: Kiểm tra VS Code output panel

## Tính năng MCP

### Serena MCP Server
- Hỗ trợ code completion và suggestions
- Context-aware development assistance
- Project-specific recommendations

### MongoDB MCP Server
- Database query assistance
- Schema management
- Data analysis tools
- Collection operations

## Lưu ý quan trọng

1. **Luôn khởi động MongoDB trước** khi sử dụng MongoDB MCP Server
2. **Kiểm tra kết nối** trước khi bắt đầu phát triển
3. **Sử dụng PowerShell Manager** để quản lý servers một cách hiệu quả
4. **Backup cấu hình** trước khi thay đổi settings

## Hỗ trợ

Nếu gặp vấn đề, hãy:
1. Chạy `.\mcp_manager.ps1 -Action test` để kiểm tra
2. Kiểm tra logs trong VS Code output panel
3. Đảm bảo tất cả dependencies đã được cài đặt đúng

