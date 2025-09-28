import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

import { Colors } from '../constants/colors';
import { Spacing, Layout } from '../constants/spacing';
import { Typography } from '../constants/typography';

interface ProgressBarProps {
  progress: number; // 0-100
  height?: number;
  showLabel?: boolean;
  label?: string;
  color?: 'primary' | 'secondary' | 'success' | 'warning' | 'error';
  style?: ViewStyle;
  animated?: boolean;
}

const ProgressBar: React.FC<ProgressBarProps> = ({
  progress,
  height = 8,
  showLabel = false,
  label,
  color = 'primary',
  style,
  animated = true,
}) => {
  const clampedProgress = Math.max(0, Math.min(100, progress));

  const getProgressColor = () => {
    switch (color) {
      case 'primary':
        return Colors.gradients.primary;
      case 'secondary':
        return Colors.gradients.secondary;
      case 'success':
        return [Colors.success, Colors.success];
      case 'warning':
        return [Colors.warning, Colors.warning];
      case 'error':
        return [Colors.error, Colors.error];
      default:
        return Colors.gradients.primary;
    }
  };

  return (
    <View style={[styles.container, style]}>
      {showLabel && (
        <View style={styles.labelContainer}>
          <Text style={styles.label}>{label || `${Math.round(clampedProgress)}%`}</Text>
        </View>
      )}
      <View style={[styles.track, { height }]}>
        <LinearGradient
          colors={getProgressColor() as readonly [string, string]}
          style={[
            styles.progress,
            {
              height,
              width: `${clampedProgress}%`,
            },
          ]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  labelContainer: {
    marginBottom: Spacing.xs,
  },
  label: {
    ...Typography.styles.bodySmall,
    color: Colors.text.secondary,
    textAlign: 'right',
  },
  track: {
    backgroundColor: Colors.background.secondary,
    borderRadius: Layout.radius.sm,
    overflow: 'hidden',
  },
  progress: {
    borderRadius: Layout.radius.sm,
  },
});

export default ProgressBar;
