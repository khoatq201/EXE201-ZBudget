import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Audio } from 'expo-av';

import { Colors } from '../../constants/colors';
import { Spacing, Layout } from '../../constants/spacing';
import { Typography } from '../../constants/typography';
import { VietnameseText } from '../../constants/vietnamese';
import { ChatMessage, MessageType, ExpenseCategory } from '../../types';
import { BackButton } from '../../components';

interface QuickAction {
  id: string;
  text: string;
  action: string;
}

const quickActions: QuickAction[] = [
  { id: '1', text: 'Thêm chi tiêu ăn uống', action: 'add_food_expense' },
  { id: '2', text: 'Xem ngân sách tháng này', action: 'view_budget' },
  { id: '3', text: 'Chi tiêu di chuyển hôm nay', action: 'add_transport_expense' },
  { id: '4', text: 'Báo cáo chi tiêu tuần', action: 'weekly_report' },
];

const ChatScreen: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      userId: 'bot',
      message: VietnameseText.chatbot.welcome,
      type: MessageType.BOT,
      timestamp: new Date(),
    },
  ]);
  const [inputText, setInputText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const flatListRef = useRef<FlatList>(null);
  const [recording, setRecording] = useState<Audio.Recording | null>(null);

  useEffect(() => {
    // Request audio permissions on mount
    requestAudioPermissions();
  }, []);

  const requestAudioPermissions = async () => {
    try {
      const { status } = await Audio.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Thông báo', 'Cần quyền truy cập microphone để sử dụng ghi âm');
      }
    } catch (error) {
      console.error('Error requesting audio permissions:', error);
    }
  };

  const simulateAIResponse = (userMessage: string): string => {
    const lowerMessage = userMessage.toLowerCase();

    // Check for expense-related keywords
    if (
      lowerMessage.includes('chi') ||
      lowerMessage.includes('tiền') ||
      lowerMessage.includes('mua')
    ) {
      if (
        lowerMessage.includes('ăn') ||
        lowerMessage.includes('cơm') ||
        lowerMessage.includes('quán')
      ) {
        return `Tôi hiểu bạn muốn ghi lại chi tiêu ăn uống. Bạn đã chi bao nhiều tiền?`;
      } else if (
        lowerMessage.includes('xe') ||
        lowerMessage.includes('bus') ||
        lowerMessage.includes('grab')
      ) {
        return `Tôi thấy bạn có chi phí di chuyển. Số tiền là bao nhiều vậy?`;
      } else {
        return `${VietnameseText.chatbot.askAmount} Và khoản chi này thuộc danh mục nào?`;
      }
    }

    // Check for numbers (amounts)
    const numbers = userMessage.match(/\d+/g);
    if (numbers && numbers.length > 0) {
      const amount = numbers[0];
      return `Vậy là ${new Intl.NumberFormat('vi-VN').format(parseInt(amount))} VND phải không? Khoản chi này thuộc danh mục nào?`;
    }

    // Check for categories
    if (lowerMessage.includes('ăn') || lowerMessage.includes('food')) {
      return `Đã hiểu! Tôi sẽ ghi lại chi tiêu ăn uống cho bạn. Bạn có muốn thêm ghi chú gì không?`;
    }

    // Default responses
    const responses = [
      'Tôi có thể giúp bạn ghi lại chi tiêu, xem ngân sách, hoặc phân tích thói quen chi tiêu. Bạn cần làm gì?',
      'Hãy cho tôi biết bạn đã chi tiêu gì hôm nay nhé!',
      'Tôi sẵn sàng giúp bạn quản lý tài chính. Bạn muốn làm gì?',
    ];

    return responses[Math.floor(Math.random() * responses.length)];
  };

  const handleSendMessage = async () => {
    if (!inputText.trim()) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      userId: 'user',
      message: inputText,
      type: MessageType.USER,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    setInputText('');
    setIsProcessing(true);

    // Simulate AI processing delay
    setTimeout(() => {
      const aiResponse: ChatMessage = {
        id: (Date.now() + 1).toString(),
        userId: 'bot',
        message: simulateAIResponse(inputText),
        type: MessageType.BOT,
        timestamp: new Date(),
      };

      setMessages(prev => [...prev, aiResponse]);
      setIsProcessing(false);
    }, 1500);
  };

  const handleQuickAction = (action: string) => {
    let message = '';
    switch (action) {
      case 'add_food_expense':
        message = 'Tôi muốn thêm chi tiêu ăn uống';
        break;
      case 'view_budget':
        message = 'Cho tôi xem ngân sách tháng này';
        break;
      case 'add_transport_expense':
        message = 'Thêm chi tiêu di chuyển hôm nay';
        break;
      case 'weekly_report':
        message = 'Báo cáo chi tiêu tuần này';
        break;
      default:
        return;
    }
    setInputText(message);
  };

  const startRecording = async () => {
    try {
      setIsRecording(true);

      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      const { recording } = await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );
      setRecording(recording);
    } catch (error) {
      console.error('Failed to start recording:', error);
      Alert.alert('Lỗi', 'Không thể bắt đầu ghi âm');
      setIsRecording(false);
    }
  };

  const stopRecording = async () => {
    try {
      setIsRecording(false);
      if (!recording) return;

      await recording.stopAndUnloadAsync();
      const uri = recording.getURI();
      setRecording(null);

      // Simulate voice processing
      setIsProcessing(true);
      setTimeout(() => {
        setInputText('Chi 45,000 VND cho cơm trưa');
        setIsProcessing(false);
        Alert.alert('Thành công', 'Đã chuyển đổi giọng nói thành văn bản');
      }, 2000);
    } catch (error) {
      console.error('Failed to stop recording:', error);
      Alert.alert('Lỗi', 'Không thể dừng ghi âm');
    }
  };

  const renderMessage = ({ item }: { item: ChatMessage }) => {
    const isBot = item.type === MessageType.BOT;

    return (
      <View style={[styles.messageContainer, isBot ? styles.botMessage : styles.userMessage]}>
        {isBot && (
          <View style={styles.botAvatar}>
            <Ionicons name="chatbubble" size={16} color={Colors.text.inverse} />
          </View>
        )}
        <View style={[styles.messageBubble, isBot ? styles.botBubble : styles.userBubble]}>
          <Text style={[styles.messageText, isBot ? styles.botText : styles.userText]}>
            {item.message}
          </Text>
          <Text style={[styles.messageTime, isBot ? styles.botTime : styles.userTime]}>
            {item.timestamp.toLocaleTimeString('vi-VN', {
              hour: '2-digit',
              minute: '2-digit',
            })}
          </Text>
        </View>
      </View>
    );
  };

  const renderQuickAction = ({ item }: { item: QuickAction }) => (
    <TouchableOpacity
      style={styles.quickActionButton}
      onPress={() => handleQuickAction(item.action)}
    >
      <Text style={styles.quickActionText}>{item.text}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <BackButton title="Trợ lý AI" />
      <KeyboardAvoidingView
        style={styles.keyboardContainer}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={item => item.id}
          style={styles.messagesList}
          contentContainerStyle={styles.messagesContent}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
          showsVerticalScrollIndicator={false}
        />

        {isProcessing && (
          <View style={styles.processingContainer}>
            <View style={styles.processingBubble}>
              <Text style={styles.processingText}>{VietnameseText.chatbot.processing}</Text>
              <View style={styles.typingIndicator}>
                <View style={[styles.dot, styles.dot1]} />
                <View style={[styles.dot, styles.dot2]} />
                <View style={[styles.dot, styles.dot3]} />
              </View>
            </View>
          </View>
        )}

        <View style={styles.quickActionsContainer}>
          <FlatList
            data={quickActions}
            renderItem={renderQuickAction}
            keyExtractor={item => item.id}
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.quickActionsList}
          />
        </View>

        <View style={styles.inputContainer}>
          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.textInput}
              placeholder="Nhập tin nhắn..."
              value={inputText}
              onChangeText={setInputText}
              multiline
              maxLength={500}
            />
            <TouchableOpacity
              style={styles.voiceButton}
              onPressIn={startRecording}
              onPressOut={stopRecording}
              disabled={isProcessing}
            >
              <Ionicons
                name={isRecording ? 'mic' : 'mic-outline'}
                size={24}
                color={isRecording ? Colors.error : Colors.primary[500]}
              />
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            style={styles.sendButton}
            onPress={handleSendMessage}
            disabled={!inputText.trim() || isProcessing}
          >
            <LinearGradient
              colors={Colors.gradients.primary}
              style={styles.sendButtonGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Ionicons name="send" size={20} color={Colors.text.inverse} />
            </LinearGradient>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  keyboardContainer: {
    flex: 1,
  },
  messagesList: {
    flex: 1,
  },
  messagesContent: {
    paddingVertical: Spacing.md,
  },
  messageContainer: {
    flexDirection: 'row',
    marginBottom: Spacing.md,
    paddingHorizontal: Spacing.md,
  },
  botMessage: {
    justifyContent: 'flex-start',
  },
  userMessage: {
    justifyContent: 'flex-end',
  },
  botAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.sm,
  },
  messageBubble: {
    maxWidth: '80%',
    borderRadius: Layout.radius.md,
    padding: Spacing.md,
  },
  botBubble: {
    backgroundColor: Colors.background.secondary,
    borderBottomLeftRadius: 4,
  },
  userBubble: {
    backgroundColor: Colors.primary[500],
    borderBottomRightRadius: 4,
  },
  messageText: {
    ...Typography.styles.body,
    lineHeight: 20,
  },
  botText: {
    color: Colors.text.primary,
  },
  userText: {
    color: Colors.text.inverse,
  },
  messageTime: {
    ...Typography.styles.caption,
    marginTop: Spacing.xs,
  },
  botTime: {
    color: Colors.text.secondary,
  },
  userTime: {
    color: 'rgba(255, 255, 255, 0.7)',
  },
  processingContainer: {
    paddingHorizontal: Spacing.md,
    marginBottom: Spacing.md,
  },
  processingBubble: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.background.secondary,
    borderRadius: Layout.radius.md,
    borderBottomLeftRadius: 4,
    padding: Spacing.md,
    alignSelf: 'flex-start',
  },
  processingText: {
    ...Typography.styles.body,
    color: Colors.text.secondary,
    marginRight: Spacing.sm,
  },
  typingIndicator: {
    flexDirection: 'row',
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: Colors.text.secondary,
    marginHorizontal: 1,
  },
  dot1: {
    opacity: 0.4,
  },
  dot2: {
    opacity: 0.7,
  },
  dot3: {
    opacity: 1,
  },
  quickActionsContainer: {
    paddingVertical: Spacing.sm,
    borderTopWidth: 1,
    borderTopColor: Colors.dark[200],
  },
  quickActionsList: {
    paddingHorizontal: Spacing.md,
  },
  quickActionButton: {
    backgroundColor: Colors.background.secondary,
    borderRadius: Layout.radius.lg,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    marginRight: Spacing.sm,
    borderWidth: 1,
    borderColor: Colors.dark[200],
  },
  quickActionText: {
    ...Typography.styles.bodySmall,
    color: Colors.text.primary,
  },
  inputContainer: {
    flexDirection: 'row',
    padding: Spacing.md,
    alignItems: 'flex-end',
    borderTopWidth: 1,
    borderTopColor: Colors.dark[200],
    backgroundColor: Colors.background.primary,
  },
  inputWrapper: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'flex-end',
    backgroundColor: Colors.background.secondary,
    borderRadius: Layout.radius.lg,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    marginRight: Spacing.sm,
    maxHeight: 100,
  },
  textInput: {
    flex: 1,
    ...Typography.styles.body,
    color: Colors.text.primary,
    maxHeight: 80,
    textAlignVertical: 'center',
  },
  voiceButton: {
    padding: Spacing.xs,
    marginLeft: Spacing.sm,
  },
  sendButton: {
    borderRadius: 20,
    overflow: 'hidden',
  },
  sendButtonGradient: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default ChatScreen;
