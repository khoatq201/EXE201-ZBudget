import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';

import { Colors } from '../../constants/colors';
import { Spacing, Layout } from '../../constants/spacing';
import { Typography } from '../../constants/typography';

const ForgotPasswordScreen: React.FC = () => {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigation = useNavigation();

  const handleResetPassword = async () => {
    if (!email) {
      Alert.alert('Lỗi', 'Vui lòng nhập email');
      return;
    }

    setIsLoading(true);
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      Alert.alert('Thành công', 'Link đặt lại mật khẩu đã được gửi đến email của bạn', [
        { text: 'OK', onPress: () => navigation.goBack() },
      ]);
    } catch (error) {
      Alert.alert('Lỗi', 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color={Colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Quên mật khẩu</Text>
      </View>

      <View style={styles.content}>
        <Text style={styles.description}>
          Nhập email của bạn và chúng tôi sẽ gửi link đặt lại mật khẩu
        </Text>

        <View style={styles.inputContainer}>
          <Ionicons name="mail-outline" size={20} color={Colors.text.secondary} />
          <TextInput
            style={styles.input}
            placeholder="Nhập email của bạn"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
          />
        </View>

        <TouchableOpacity
          style={styles.resetButton}
          onPress={handleResetPassword}
          disabled={isLoading}
        >
          <LinearGradient
            colors={Colors.gradients.primary}
            style={styles.resetButtonGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
          >
            <Text style={styles.resetButtonText}>
              {isLoading ? 'Đang gửi...' : 'Gửi link đặt lại'}
            </Text>
          </LinearGradient>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background.primary,
    paddingHorizontal: Spacing['2xl'],
    paddingTop: Spacing['2xl'],
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing['3xl'],
  },
  backButton: {
    padding: Spacing.sm,
    marginRight: Spacing.md,
  },
  title: {
    ...Typography.styles.h3,
    color: Colors.text.primary,
    flex: 1,
  },
  content: {
    flex: 1,
  },
  description: {
    ...Typography.styles.body,
    color: Colors.text.secondary,
    textAlign: 'center',
    marginBottom: Spacing['2xl'],
    lineHeight: 24,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.dark[200],
    borderRadius: Layout.radius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    marginBottom: Spacing['2xl'],
    backgroundColor: Colors.background.secondary,
  },
  input: {
    flex: 1,
    marginLeft: Spacing.sm,
    ...Typography.styles.body,
    color: Colors.text.primary,
  },
  resetButton: {
    borderRadius: Layout.radius.md,
    overflow: 'hidden',
  },
  resetButtonGradient: {
    paddingVertical: Spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  resetButtonText: {
    ...Typography.styles.button,
    color: Colors.text.inverse,
  },
});

export default ForgotPasswordScreen;
