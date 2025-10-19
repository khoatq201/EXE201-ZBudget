# System Message Migration

## Mục đích

Migration này được tạo để tách system message ra khỏi messages array trong ChatSession model, ngăn system message xuất hiện trong lịch sử chat của người dùng.

## Thay đổi

### 1. Model Changes

- **ChatSession.js**: Thêm field `systemMessage` để lưu system message riêng biệt
- **aiChatbotService.js**: Cập nhật logic để sử dụng system message từ field riêng

### 2. Migration Process

1. **Di chuyển system message**: Tìm và di chuyển system message từ `messages` array sang `systemMessage` field
2. **Tạo system message mới**: Tạo system message cho các session chưa có
3. **Cập nhật message count**: Giảm message count khi xóa system message khỏi messages array

## Cách chạy migration

### Option 1: Chạy trực tiếp

```bash
cd Backend
node scripts/run-migration.js
```

### Option 2: Chạy từng bước

```bash
cd Backend
node -e "import('./scripts/migrateSystemMessage.js').then(m => m.runMigration())"
```

## Kết quả mong đợi

### Trước migration:

```json
{
  "sessionId": "abc123",
  "messages": [
    {
      "role": "system",
      "content": "Bạn là trợ lý AI...",
      "timestamp": "2024-01-01T00:00:00Z"
    },
    {
      "role": "user",
      "content": "Xin chào",
      "timestamp": "2024-01-01T00:01:00Z"
    }
  ],
  "messageCount": 2
}
```

### Sau migration:

```json
{
  "sessionId": "abc123",
  "systemMessage": "Bạn là trợ lý AI...",
  "messages": [
    {
      "role": "user",
      "content": "Xin chào",
      "timestamp": "2024-01-01T00:01:00Z"
    }
  ],
  "messageCount": 1
}
```

## Lợi ích

1. **Lịch sử chat sạch hơn**: System message không xuất hiện trong lịch sử chat
2. **Hiệu suất tốt hơn**: Không cần lọc system message khi hiển thị lịch sử
3. **Quản lý dễ dàng**: System message được quản lý riêng biệt
4. **Tương thích ngược**: Các session cũ vẫn hoạt động bình thường

## Rollback (nếu cần)

Nếu cần rollback, có thể chạy script sau:

```javascript
// Rollback script (chỉ để tham khảo)
const sessions = await ChatSession.find({ systemMessage: { $exists: true } });
for (const session of sessions) {
  if (session.systemMessage) {
    session.messages.unshift({
      role: "system",
      content: session.systemMessage,
      timestamp: session.createdAt,
    });
    session.systemMessage = "";
    session.messageCount += 1;
    await session.save();
  }
}
```

## Lưu ý

- Migration này là **one-way** và **không thể hoàn tác** dễ dàng
- Backup database trước khi chạy migration
- Test trên môi trường development trước
- Monitor logs trong quá trình migration
