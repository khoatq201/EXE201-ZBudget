import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { Colors } from '../constants/colors';
import { Typography } from '../constants/typography';
import { Spacing } from '../constants/spacing';

interface LoadingStateProps {
  message?: string;
  size?: 'small' | 'large';
  color?: string;
  backgroundColor?: string;
}

export const LoadingState: React.FC<LoadingStateProps> = ({
  message = 'Đang tải...',
  size = 'large',
  color = Colors.primary[500],
  backgroundColor = Colors.background.primary,
}) => {
  return (
    <View style={[styles.container, { backgroundColor }]}>
      <ActivityIndicator size={size} color={color} />
      {message && <Text style={[styles.message, { color: Colors.text.secondary }]}>{message}</Text>}
    </View>
  );
};

interface LoadingOverlayProps {
  visible: boolean;
  message?: string;
  children: React.ReactNode;
}

export const LoadingOverlay: React.FC<LoadingOverlayProps> = ({
  visible,
  message = 'Đang xử lý...',
  children,
}) => {
  return (
    <View style={styles.overlayContainer}>
      {children}
      {visible && (
        <View style={styles.overlay}>
          <View style={styles.overlayContent}>
            <ActivityIndicator size="large" color={Colors.primary[500]} />
            <Text style={styles.overlayMessage}>{message}</Text>
          </View>
        </View>
      )}
    </View>
  );
};

interface LoadingButtonProps {
  loading: boolean;
  title: string;
  onPress: () => void;
  disabled?: boolean;
  style?: any;
  textStyle?: any;
}

export const LoadingButton: React.FC<LoadingButtonProps> = ({
  loading,
  title,
  onPress,
  disabled = false,
  style,
  textStyle,
}) => {
  return (
    <View style={[styles.button, style, (disabled || loading) && styles.buttonDisabled]}>
      {loading ? (
        <ActivityIndicator size="small" color={Colors.text.inverse} />
      ) : (
        <Text style={[styles.buttonText, textStyle]}>{title}</Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.lg,
  },
  message: {
    ...Typography.styles.body,
    marginTop: Spacing.md,
    textAlign: 'center',
  },
  overlayContainer: {
    flex: 1,
    position: 'relative',
  },
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
  overlayContent: {
    backgroundColor: Colors.background.primary,
    padding: Spacing.xl,
    borderRadius: 12,
    alignItems: 'center',
    minWidth: 120,
  },
  overlayMessage: {
    ...Typography.styles.body,
    color: Colors.text.primary,
    marginTop: Spacing.md,
    textAlign: 'center',
  },
  button: {
    backgroundColor: Colors.primary[500],
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  buttonDisabled: {
    backgroundColor: Colors.primary[300],
    opacity: 0.7,
  },
  buttonText: {
    ...Typography.styles.button,
    color: Colors.text.inverse,
  },
});
