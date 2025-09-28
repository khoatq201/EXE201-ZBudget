import React from 'react';
import { TouchableOpacity, Text, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { accessibilityHelper, ACCESSIBILITY_LABELS } from '../utils/accessibility';

interface BackButtonProps {
  title?: string;
  onPress?: () => void;
  style?: object;
  showHomeIcon?: boolean;
  rightComponent?: React.ReactNode;
}

const BackButton: React.FC<BackButtonProps> = ({
  title,
  onPress,
  style,
  showHomeIcon = false,
  rightComponent,
}) => {
  const navigation = useNavigation();

  const handlePress = () => {
    if (onPress) {
      onPress();
    } else if (showHomeIcon) {
      // Navigate to Dashboard (Home)
      navigation.navigate('Dashboard' as never);
    } else {
      // Default back behavior
      navigation.goBack();
    }
  };

  return (
    <View style={[styles.container, style]}>
      <View style={styles.leftSection}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={handlePress}
          {...accessibilityHelper.createButtonProps(
            showHomeIcon ? 'Về trang chủ' : ACCESSIBILITY_LABELS.BACK_BUTTON,
            showHomeIcon ? 'Nhấn để về trang chủ' : 'Nhấn để quay lại trang trước'
          )}
        >
          <Ionicons name={showHomeIcon ? 'home' : 'arrow-back'} size={24} color="#FFFFFF" />
        </TouchableOpacity>
        {title && (
          <Text style={styles.title} {...accessibilityHelper.createTextProps(title, true)}>
            {title}
          </Text>
        )}
      </View>
      {rightComponent && <View style={styles.rightComponent}>{rightComponent}</View>}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
    backgroundColor: '#1A2E3A',
  },
  leftSection: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFFFFF',
    flex: 1,
  },
  rightComponent: {
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default BackButton;
