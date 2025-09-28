import React from 'react';
import { View, StyleSheet, ViewStyle, Text, TouchableOpacity } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';

import { Colors } from '../constants/colors';
import { Spacing, Layout } from '../constants/spacing';
import { Typography } from '../constants/typography';

interface CardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  padding?: 'none' | 'small' | 'medium' | 'large';
  elevated?: boolean;
  variant?: 'default' | 'gradient' | 'outlined' | 'glass';
  onPress?: () => void;
  disabled?: boolean;
  accessibilityLabel?: string;
  accessibilityHint?: string;
}

interface CardHeaderProps {
  title: string;
  subtitle?: string;
  icon?: string;
  iconColor?: string;
  action?: {
    icon: string;
    onPress: () => void;
  };
}

interface CardFooterProps {
  children: React.ReactNode;
  separated?: boolean;
}

const Card: React.FC<CardProps> = ({
  children,
  style,
  padding = 'medium',
  elevated = true,
  variant = 'default',
  onPress,
  disabled = false,
  accessibilityLabel,
  accessibilityHint,
}) => {
  const cardStyle = [
    styles.card,
    elevated && styles.elevated,
    styles[padding],
    styles[variant],
    disabled && styles.disabled,
    style,
  ];

  const CardContent = () => <View style={cardStyle}>{children}</View>;

  if (variant === 'gradient') {
    return (
      <TouchableOpacity
        onPress={onPress}
        disabled={disabled || !onPress}
        activeOpacity={0.8}
        accessibilityLabel={accessibilityLabel}
        accessibilityHint={accessibilityHint}
        accessibilityRole={onPress ? 'button' : undefined}
      >
        <LinearGradient
          colors={Colors.gradients.primary}
          style={[cardStyle, styles.gradientCard]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          {children}
        </LinearGradient>
      </TouchableOpacity>
    );
  }

  if (onPress) {
    return (
      <TouchableOpacity
        onPress={onPress}
        disabled={disabled}
        activeOpacity={0.8}
        accessibilityLabel={accessibilityLabel}
        accessibilityHint={accessibilityHint}
        accessibilityRole="button"
      >
        <CardContent />
      </TouchableOpacity>
    );
  }

  return <CardContent />;
};

// Card Header Component
export const CardHeader: React.FC<CardHeaderProps> = ({
  title,
  subtitle,
  icon,
  iconColor = Colors.primary[500],
  action,
}) => {
  return (
    <View style={styles.header}>
      <View style={styles.headerContent}>
        {icon && (
          <View style={styles.headerIcon}>
            <Ionicons name={icon as any} size={24} color={iconColor} />
          </View>
        )}
        <View style={styles.headerText}>
          <Text style={styles.headerTitle}>{title}</Text>
          {subtitle && <Text style={styles.headerSubtitle}>{subtitle}</Text>}
        </View>
      </View>
      {action && (
        <TouchableOpacity
          style={styles.headerAction}
          onPress={action.onPress}
          accessibilityLabel={`Action for ${title}`}
        >
          <Ionicons name={action.icon as any} size={20} color={Colors.text.secondary} />
        </TouchableOpacity>
      )}
    </View>
  );
};

// Card Footer Component
export const CardFooter: React.FC<CardFooterProps> = ({ children, separated = true }) => {
  return <View style={[styles.footer, separated && styles.footerSeparated]}>{children}</View>;
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.background.primary,
    borderRadius: Layout.radius.lg,
    borderWidth: 1,
    borderColor: Colors.background.secondary,
  },
  elevated: {
    shadowColor: Colors.dark[900],
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  disabled: {
    opacity: 0.6,
  },
  // Variants
  default: {},
  gradient: {},
  outlined: {
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: Colors.primary[500],
  },
  glass: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  gradientCard: {
    borderWidth: 0,
  },
  // Padding variants
  none: {
    padding: 0,
  },
  small: {
    padding: Spacing.md,
  },
  medium: {
    padding: Spacing.lg,
  },
  large: {
    padding: Spacing.xl,
  },
  // Header styles
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: Spacing.md,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  headerIcon: {
    marginRight: Spacing.sm,
  },
  headerText: {
    flex: 1,
  },
  headerTitle: {
    ...Typography.styles.h4,
    color: Colors.text.primary,
    marginBottom: 2,
  },
  headerSubtitle: {
    ...Typography.styles.caption,
    color: Colors.text.secondary,
  },
  headerAction: {
    padding: Spacing.xs,
    marginLeft: Spacing.sm,
  },
  // Footer styles
  footer: {
    marginTop: Spacing.md,
  },
  footerSeparated: {
    borderTopWidth: 1,
    borderTopColor: Colors.background.secondary,
    paddingTop: Spacing.md,
  },
});

export default Card;

// Utility components for common card patterns
export const InfoCard: React.FC<{
  title: string;
  value: string;
  icon?: string;
  color?: string;
  onPress?: () => void;
}> = ({ title, value, icon, color = Colors.primary[500], onPress }) => {
  return (
    <Card onPress={onPress} padding="medium" style={{ minHeight: 80 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        {icon && (
          <View
            style={{
              marginRight: Spacing.sm,
              width: 40,
              height: 40,
              borderRadius: 20,
              backgroundColor: `${color}20`,
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <Ionicons name={icon as any} size={20} color={color} />
          </View>
        )}
        <View style={{ flex: 1 }}>
          <Text
            style={{
              ...Typography.styles.caption,
              color: Colors.text.secondary,
              marginBottom: 4,
            }}
          >
            {title}
          </Text>
          <Text
            style={{
              ...Typography.styles.h4,
              color: Colors.text.primary,
            }}
          >
            {value}
          </Text>
        </View>
      </View>
    </Card>
  );
};

export const ActionCard: React.FC<{
  title: string;
  subtitle?: string;
  icon: string;
  color?: string;
  onPress: () => void;
}> = ({ title, subtitle, icon, color = Colors.primary[500], onPress }) => {
  return (
    <Card onPress={onPress} padding="medium" elevated>
      <View style={{ alignItems: 'center' }}>
        <View
          style={{
            width: 48,
            height: 48,
            borderRadius: 24,
            backgroundColor: `${color}20`,
            justifyContent: 'center',
            alignItems: 'center',
            marginBottom: Spacing.sm,
          }}
        >
          <Ionicons name={icon as any} size={24} color={color} />
        </View>
        <Text
          style={{
            ...Typography.styles.bodyBold,
            color: Colors.text.primary,
            textAlign: 'center',
            marginBottom: 4,
          }}
        >
          {title}
        </Text>
        {subtitle && (
          <Text
            style={{
              ...Typography.styles.caption,
              color: Colors.text.secondary,
              textAlign: 'center',
            }}
          >
            {subtitle}
          </Text>
        )}
      </View>
    </Card>
  );
};
