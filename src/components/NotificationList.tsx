import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../constants/colors';

interface Notification {
  id: string;
  type: 'debt' | 'group_fund' | 'feature' | 'budget' | 'reminder';
  title: string;
  message: string;
  time: string;
  isRead: boolean;
  icon: string;
  priority: 'high' | 'medium' | 'low';
}

interface NotificationListProps {
  visible: boolean;
  onClose: () => void;
  onNotificationPress?: (notification: Notification) => void;
}

const NotificationList: React.FC<NotificationListProps> = ({
  visible,
  onClose,
  onNotificationPress,
}) => {
  const notifications: Notification[] = [
    {
      id: '1',
      type: 'debt',
      title: 'Nhắc nhở đòi nợ',
      message: 'Minh Tú nợ bạn 150,000đ từ bữa ăn hôm qua. Hãy nhắc nhở bạn ấy!',
      time: '2 phút trước',
      isRead: false,
      icon: '💰',
      priority: 'high',
    },
    {
      id: '2',
      type: 'group_fund',
      title: 'Biến động quỹ nhóm',
      message: 'Nhóm "Du lịch Đà Lạt" đã có thêm 500,000đ từ Hoàng Nam',
      time: '1 giờ trước',
      isRead: false,
      icon: '👥',
      priority: 'medium',
    },
    {
      id: '3',
      type: 'feature',
      title: 'Tính năng mới',
      message: 'Tính năng quét hóa đơn bằng AI đã được cập nhật. Hãy thử ngay!',
      time: '3 giờ trước',
      isRead: true,
      icon: '🆕',
      priority: 'low',
    },
    {
      id: '4',
      type: 'budget',
      title: 'Vượt ngân sách',
      message: 'Bạn đã chi tiêu 85% ngân sách tháng này. Hãy cẩn thận!',
      time: '1 ngày trước',
      isRead: false,
      icon: '⚠️',
      priority: 'high',
    },
    {
      id: '5',
      type: 'reminder',
      title: 'Nhắc nhở tiết kiệm',
      message: 'Đừng quên mục tiêu tiết kiệm 2M đ trong tháng này!',
      time: '2 ngày trước',
      isRead: true,
      icon: '🎯',
      priority: 'medium',
    },
  ];

  const getNotificationColor = (type: Notification['type']) => {
    switch (type) {
      case 'debt':
        return '#FF6B6B';
      case 'group_fund':
        return '#4ECDC4';
      case 'feature':
        return '#45B7D1';
      case 'budget':
        return '#FFA726';
      case 'reminder':
        return Colors.primary[500];
      default:
        return Colors.primary[500];
    }
  };

  const getPriorityColor = (priority: Notification['priority']) => {
    switch (priority) {
      case 'high':
        return '#FF6B6B';
      case 'medium':
        return '#FFA726';
      case 'low':
        return '#66BB6A';
      default:
        return '#66BB6A';
    }
  };

  const renderNotification = (notification: Notification) => (
    <TouchableOpacity
      key={notification.id}
      style={[styles.notificationItem, !notification.isRead && styles.unreadNotification]}
      onPress={() => onNotificationPress?.(notification)}
    >
      <View style={styles.notificationIcon}>
        <Text style={styles.notificationEmoji}>{notification.icon}</Text>
        <View
          style={[styles.priorityDot, { backgroundColor: getPriorityColor(notification.priority) }]}
        />
      </View>

      <View style={styles.notificationContent}>
        <View style={styles.notificationHeader}>
          <Text style={styles.notificationTitle}>{notification.title}</Text>
          <Text style={styles.notificationTime}>{notification.time}</Text>
        </View>
        <Text style={styles.notificationMessage}>{notification.message}</Text>

        <View style={styles.notificationFooter}>
          <View
            style={[
              styles.typeIndicator,
              { backgroundColor: getNotificationColor(notification.type) },
            ]}
          >
            <Text style={styles.typeText}>
              {notification.type === 'debt' && 'Đòi nợ'}
              {notification.type === 'group_fund' && 'Quỹ nhóm'}
              {notification.type === 'feature' && 'Tính năng'}
              {notification.type === 'budget' && 'Ngân sách'}
              {notification.type === 'reminder' && 'Nhắc nhở'}
            </Text>
          </View>
          {!notification.isRead && <View style={styles.unreadDot} />}
        </View>
      </View>
    </TouchableOpacity>
  );

  if (!visible) return null;

  return (
    <View style={styles.overlay}>
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Thông báo</Text>
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <Ionicons name="close" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
          {notifications.map(renderNotification)}

          {notifications.length === 0 && (
            <View style={styles.emptyState}>
              <Text style={styles.emptyIcon}>🔔</Text>
              <Text style={styles.emptyTitle}>Không có thông báo</Text>
              <Text style={styles.emptyMessage}>
                Bạn sẽ nhận được thông báo về các hoạt động quan trọng tại đây
              </Text>
            </View>
          )}
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.markAllReadButton}>
            <Ionicons name="checkmark-done" size={16} color={Colors.primary[500]} />
            <Text style={styles.markAllReadText}>Đánh dấu tất cả đã đọc</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  container: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    width: '90%',
    maxHeight: '80%',
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  closeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollContainer: {
    maxHeight: 400,
  },
  notificationItem: {
    flexDirection: 'row',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
  },
  unreadNotification: {
    backgroundColor: 'rgba(61, 161, 61, 0.1)',
  },
  notificationIcon: {
    position: 'relative',
    marginRight: 12,
  },
  notificationEmoji: {
    fontSize: 24,
  },
  priorityDot: {
    position: 'absolute',
    top: -2,
    right: -2,
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  notificationContent: {
    flex: 1,
  },
  notificationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  notificationTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    flex: 1,
  },
  notificationTime: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  notificationMessage: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 18,
    marginBottom: 8,
  },
  notificationFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  typeIndicator: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
  },
  typeText: {
    fontSize: 10,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.primary[500],
  },
  emptyState: {
    alignItems: 'center',
    padding: 40,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  emptyMessage: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    lineHeight: 20,
  },
  footer: {
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  markAllReadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
  },
  markAllReadText: {
    fontSize: 14,
    color: Colors.primary[500],
    marginLeft: 6,
    fontWeight: '500',
  },
});

export default NotificationList;
