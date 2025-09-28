import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';

import { AppProvider, useApp } from './src/context/AppContext';
import AppNavigator from './src/navigation/AppNavigator';
import { Colors } from './src/constants/colors';
import { Typography } from './src/constants/typography';

export default function App() {
  return (
    <AppProvider>
      <View style={styles.container}>
        <StatusBar style="auto" />
        <AppContent />
      </View>
    </AppProvider>
  );
}

const AppContent: React.FC = () => {
  const { state } = useApp();

  if (state.isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>ZBudget</Text>
      </View>
    );
  }

  return (
    <AppNavigator 
      isFirstLaunch={state.isFirstLaunch} 
      isAuthenticated={state.isAuthenticated} 
    />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background.primary,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.background.primary,
  },
  loadingText: {
    ...Typography.styles.h2,
    color: Colors.primary[500],
    fontWeight: 'bold',
  },
});
