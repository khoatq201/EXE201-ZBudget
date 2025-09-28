import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ViewStyle, TextStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';

import { Colors } from '../constants/colors';
import { Spacing, Layout } from '../constants/spacing';
import { Typography } from '../constants/typography';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  icon?: keyof typeof Ionicons.glyphMap;
  iconPosition?: 'left' | 'right';
  style?: ViewStyle;
  textStyle?: TextStyle;
  fullWidth?: boolean;
}

const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  icon,
  iconPosition = 'left',
  style,
  textStyle,
  fullWidth = false,
}) => {
  const getButtonStyle = () => {
    const baseStyle = [styles.button, styles[size], fullWidth && styles.fullWidth, style];

    if (disabled) {
      baseStyle.push(styles.disabled);
    }

    return baseStyle;
  };

  const getTextStyle = () => {
    const baseTextStyle = [styles.text, styles[`${size}Text`], styles[`${variant}Text`], textStyle];

    if (disabled) {
      baseTextStyle.push(styles.disabledText);
    }

    return baseTextStyle;
  };

  const renderContent = () => (
    <>
      {icon && iconPosition === 'left' && (
        <Ionicons
          name={icon}
          size={size === 'small' ? 16 : size === 'large' ? 24 : 20}
          color={disabled ? Colors.text.tertiary : getIconColor()}
          style={styles.iconLeft}
        />
      )}
      <Text style={getTextStyle()}>{loading ? 'Loading...' : title}</Text>
      {icon && iconPosition === 'right' && (
        <Ionicons
          name={icon}
          size={size === 'small' ? 16 : size === 'large' ? 24 : 20}
          color={disabled ? Colors.text.tertiary : getIconColor()}
          style={styles.iconRight}
        />
      )}
    </>
  );

  const getIconColor = () => {
    switch (variant) {
      case 'primary':
        return Colors.text.inverse;
      case 'secondary':
        return Colors.text.inverse;
      case 'outline':
        return Colors.primary[500];
      case 'ghost':
        return Colors.primary[500];
      default:
        return Colors.text.inverse;
    }
  };

  if (variant === 'primary') {
    return (
      <TouchableOpacity
        style={getButtonStyle()}
        onPress={onPress}
        disabled={disabled || loading}
        activeOpacity={0.8}
      >
        <LinearGradient
          colors={Colors.gradients.primary}
          style={[styles.gradientButton, fullWidth && styles.fullWidth]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
        >
          {renderContent()}
        </LinearGradient>
      </TouchableOpacity>
    );
  }

  return (
    <TouchableOpacity
      style={[getButtonStyle(), styles[variant]]}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.8}
    >
      {renderContent()}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    borderRadius: Layout.radius.md,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
  },
  gradientButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.lg,
  },
  fullWidth: {
    width: '100%',
  },
  small: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    minHeight: 32,
  },
  medium: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    minHeight: 44,
  },
  large: {
    paddingHorizontal: Spacing.xl,
    paddingVertical: Spacing.lg,
    minHeight: 52,
  },
  secondary: {
    backgroundColor: Colors.secondary[500],
  },
  outline: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    textAlign: 'center',
    fontWeight: '600',
  },
  smallText: {
    ...Typography.styles.bodySmall,
  },
  mediumText: {
    ...Typography.styles.button,
  },
  largeText: {
    ...Typography.styles.button,
    fontSize: 18,
  },
  primaryText: {
    color: Colors.text.inverse,
  },
  secondaryText: {
    color: Colors.text.inverse,
  },
  outlineText: {
    color: Colors.primary[500],
  },
  ghostText: {
    color: Colors.primary[500],
  },
  disabledText: {
    color: Colors.text.tertiary,
  },
  iconLeft: {
    marginRight: Spacing.sm,
  },
  iconRight: {
    marginLeft: Spacing.sm,
  },
});

export default Button;
