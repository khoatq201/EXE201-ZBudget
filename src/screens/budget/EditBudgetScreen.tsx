import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../../constants/colors';
import { Typography } from '../../constants/typography';
import { Spacing } from '../../constants/spacing';
import { BackButton } from '../../components';

const EditBudgetScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <BackButton title="Chỉnh sửa ngân sách" />
      <View style={styles.content}>
        <Text style={styles.title}>Chỉnh sửa ngân sách</Text>
        <Text style={styles.subtitle}>Tính năng đang được phát triển</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing['2xl'],
  },
  title: {
    ...Typography.styles.h3,
    color: Colors.text.primary,
    marginBottom: Spacing.md,
  },
  subtitle: {
    ...Typography.styles.body,
    color: Colors.text.secondary,
    textAlign: 'center',
  },
});

export default EditBudgetScreen;
