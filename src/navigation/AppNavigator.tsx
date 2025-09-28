import React, { useEffect, useRef } from 'react';
import { NavigationContainer, NavigationContainerRef } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { StatusBar } from 'expo-status-bar';
import { View, StyleSheet } from 'react-native';

import OnboardingScreen from '../screens/OnboardingScreen';
import AuthNavigator from './AuthNavigator';
import HomeNavigator from './HomeNavigator';
import { RootStackParamList } from '../types';
import { Colors, ThemeColors } from '../constants/colors';

const Stack = createStackNavigator<RootStackParamList>();

interface AppNavigatorProps {
  isFirstLaunch: boolean;
  isAuthenticated: boolean;
  theme: any;
  isDarkMode: boolean;
}

const AppNavigator: React.FC<AppNavigatorProps> = ({ isFirstLaunch, isAuthenticated, theme, isDarkMode }) => {
  const navigationRef = useRef<NavigationContainerRef<RootStackParamList>>(null);
  const isFirstRun = useRef(true);

  const getInitialRouteName = (): keyof RootStackParamList => {
    if (isFirstLaunch) return 'Onboarding';
    if (!isAuthenticated) return 'Auth';
    return 'Main';
  };

  useEffect(() => {
    // Skip navigation on first run as initialRouteName handles it
    if (isFirstRun.current) {
      isFirstRun.current = false;
      return;
    }

    // Handle navigation changes based on authentication state
    if (navigationRef.current?.isReady()) {
      if (isFirstLaunch) {
        navigationRef.current.reset({
          index: 0,
          routes: [{ name: 'Onboarding' }],
        });
      } else if (!isAuthenticated) {
        navigationRef.current.reset({
          index: 0,
          routes: [{ name: 'Auth' }],
        });
      } else {
        navigationRef.current.reset({
          index: 0,
          routes: [{ name: 'Main' }],
        });
      }
    }
  }, [isFirstLaunch, isAuthenticated]);

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <NavigationContainer ref={navigationRef}>
        <StatusBar style={isDarkMode ? "light" : "dark"} />
        <Stack.Navigator
          initialRouteName={getInitialRouteName()}
          screenOptions={{
            headerShown: false,
            cardStyle: { backgroundColor: theme.background },
          }}
        >
          <Stack.Screen name="Onboarding" component={OnboardingScreen} />
          <Stack.Screen name="Auth" component={AuthNavigator} />
          <Stack.Screen name="Main" component={HomeNavigator} />
        </Stack.Navigator>
      </NavigationContainer>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export default AppNavigator;
