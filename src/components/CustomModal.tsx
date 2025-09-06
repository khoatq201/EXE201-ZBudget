import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TouchableWithoutFeedback,
  Animated,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../constants/colors';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

interface CustomModalProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  type?: 'default' | 'success' | 'error' | 'warning' | 'info';
  showCloseButton?: boolean;
  closeOnBackdrop?: boolean;
  size?: 'small' | 'medium' | 'large' | 'fullscreen';
  animationType?: 'slide' | 'fade' | 'scale';
}

interface ActionButton {
  text: string;
  onPress: () => void;
  type?: 'primary' | 'secondary' | 'danger';
  icon?: keyof typeof Ionicons.glyphMap;
}

interface CustomAlertProps {
  visible: boolean;
  onClose: () => void;
  title: string;
  message: string;
  type?: 'success' | 'error' | 'warning' | 'info';
  buttons?: ActionButton[];
}

// Custom Modal Component
export const CustomModal: React.FC<CustomModalProps> = ({
  visible,
  onClose,
  title,
  children,
  type = 'default',
  showCloseButton = true,
  closeOnBackdrop = true,
  size = 'medium',
  animationType = 'slide',
}) => {
  const fadeAnim = React.useRef(new Animated.Value(0)).current;
  const scaleAnim = React.useRef(new Animated.Value(0.8)).current;

  React.useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.spring(scaleAnim, {
          toValue: 1,
          tension: 100,
          friction: 8,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(fadeAnim, {
          toValue: 0,
          duration: 200,
          useNativeDriver: true,
        }),
        Animated.spring(scaleAnim, {
          toValue: 0.8,
          tension: 100,
          friction: 8,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible]);

  const getModalSize = () => {
    switch (size) {
      case 'small':
        return { width: screenWidth * 0.8, maxHeight: screenHeight * 0.4 };
      case 'medium':
        return { width: screenWidth * 0.9, maxHeight: screenHeight * 0.6 };
      case 'large':
        return { width: screenWidth * 0.95, maxHeight: screenHeight * 0.8 };
      case 'fullscreen':
        return { width: screenWidth, height: screenHeight };
      default:
        return { width: screenWidth * 0.9, maxHeight: screenHeight * 0.6 };
    }
  };

  const getTypeColor = () => {
    switch (type) {
      case 'success':
        return '#4CAF50';
      case 'error':
        return '#FF6B6B';
      case 'warning':
        return '#FF9800';
      case 'info':
        return '#2196F3';
      default:
        return Colors.primary[500];
    }
  };

  const getTypeIcon = () => {
    switch (type) {
      case 'success':
        return 'checkmark-circle';
      case 'error':
        return 'close-circle';
      case 'warning':
        return 'warning';
      case 'info':
        return 'information-circle';
      default:
        return undefined;
    }
  };

  return (
    <Modal visible={visible} transparent animationType="none" statusBarTranslucent>
      <TouchableWithoutFeedback onPress={closeOnBackdrop ? onClose : undefined}>
        <Animated.View style={[styles.overlay, { opacity: fadeAnim }]}>
          <TouchableWithoutFeedback onPress={() => {}}>
            <Animated.View
              style={[
                styles.modalContainer,
                getModalSize(),
                {
                  transform: [{ scale: scaleAnim }],
                  opacity: fadeAnim,
                },
                size === 'fullscreen' && styles.fullscreenModal,
              ]}
            >
              {/* Header */}
              {(title || showCloseButton) && (
                <View style={styles.header}>
                  <View style={styles.titleContainer}>
                    {getTypeIcon() && (
                      <Ionicons
                        name={getTypeIcon()!}
                        size={24}
                        color={getTypeColor()}
                        style={styles.typeIcon}
                      />
                    )}
                    {title && (
                      <Text style={[styles.title, { color: getTypeColor() }]}>{title}</Text>
                    )}
                  </View>
                  {showCloseButton && (
                    <TouchableOpacity style={styles.closeButton} onPress={onClose}>
                      <Ionicons name="close" size={24} color="#666" />
                    </TouchableOpacity>
                  )}
                </View>
              )}

              {/* Content */}
              <View style={styles.content}>{children}</View>

              {/* Accent line */}
              <LinearGradient
                colors={[getTypeColor(), `${getTypeColor()}80`]}
                style={styles.accentLine}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
              />
            </Animated.View>
          </TouchableWithoutFeedback>
        </Animated.View>
      </TouchableWithoutFeedback>
    </Modal>
  );
};

// Custom Alert Component
export const CustomAlert: React.FC<CustomAlertProps> = ({
  visible,
  onClose,
  title,
  message,
  type = 'info',
  buttons = [{ text: 'OK', onPress: onClose, type: 'primary' }],
}) => {
  const renderButton = (button: ActionButton, index: number) => {
    const buttonStyle = [
      styles.alertButton,
      button.type === 'primary' && styles.primaryButton,
      button.type === 'secondary' && styles.secondaryButton,
      button.type === 'danger' && styles.dangerButton,
    ];

    const textStyle = [
      styles.alertButtonText,
      button.type === 'primary' && styles.primaryButtonText,
      button.type === 'secondary' && styles.secondaryButtonText,
      button.type === 'danger' && styles.dangerButtonText,
    ];

    return (
      <TouchableOpacity key={index} style={buttonStyle} onPress={button.onPress}>
        {button.icon && (
          <Ionicons
            name={button.icon}
            size={16}
            color={
              button.type === 'primary'
                ? '#FFFFFF'
                : button.type === 'danger'
                  ? '#FF6B6B'
                  : Colors.primary[500]
            }
            style={styles.buttonIcon}
          />
        )}
        <Text style={textStyle}>{button.text}</Text>
      </TouchableOpacity>
    );
  };

  return (
    <CustomModal
      visible={visible}
      onClose={onClose}
      title={title}
      type={type}
      size="small"
      showCloseButton={false}
      closeOnBackdrop={false}
    >
      <View style={styles.alertContent}>
        <Text style={styles.alertMessage}>{message}</Text>
        <View style={styles.alertButtons}>
          {buttons.map((button, index) => renderButton(button, index))}
        </View>
      </View>
    </CustomModal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContainer: {
    backgroundColor: '#2A4A5A',
    borderRadius: 20,
    overflow: 'hidden',
    elevation: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
  },
  fullscreenModal: {
    borderRadius: 0,
    marginTop: 50,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  typeIcon: {
    marginRight: 8,
  },
  title: {
    fontSize: 18,
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
  content: {
    padding: 20,
  },
  accentLine: {
    height: 3,
    width: '100%',
  },
  alertContent: {
    alignItems: 'center',
  },
  alertMessage: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.9)',
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 24,
  },
  alertButtons: {
    flexDirection: 'row',
    gap: 12,
    width: '100%',
  },
  alertButton: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  primaryButton: {
    backgroundColor: Colors.primary[500],
  },
  secondaryButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  dangerButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#FF6B6B',
  },
  alertButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.9)',
  },
  primaryButtonText: {
    color: '#FFFFFF',
  },
  secondaryButtonText: {
    color: Colors.primary[500],
  },
  dangerButtonText: {
    color: '#FF6B6B',
  },
  buttonIcon: {
    marginRight: 6,
  },
});
