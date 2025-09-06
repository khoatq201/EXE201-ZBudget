import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';

import HomeNavigator from './HomeNavigator';
import BudgetNavigator from './BudgetNavigator';
import GroupNavigator from './GroupNavigator';
import SettingsNavigator from './SettingsNavigator';
import ReportsNavigator from './ReportsNavigator';
import ChallengeScreen from '../screens/ChallengeScreen';
import { MainTabParamList } from '../types';
import { Colors } from '../constants/colors';
import { VietnameseText } from '../constants/vietnamese';

const Tab = createBottomTabNavigator<MainTabParamList>();

const MainNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap;

          switch (route.name) {
            case 'Home':
              iconName = focused ? 'home' : 'home-outline';
              break;
            case 'Budget':
              iconName = focused ? 'wallet' : 'wallet-outline';
              break;
            case 'Group':
              iconName = focused ? 'people' : 'people-outline';
              break;
            case 'Challenge':
              iconName = focused ? 'trophy' : 'trophy-outline';
              break;
            case 'Reports':
              iconName = focused ? 'bar-chart' : 'bar-chart-outline';
              break;
            case 'Settings':
              iconName = focused ? 'settings' : 'settings-outline';
              break;
            default:
              iconName = 'home-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: Colors.primary[500],
        tabBarInactiveTintColor: Colors.text.secondary,
        tabBarStyle: {
          backgroundColor: Colors.background.primary,
          borderTopWidth: 1,
          borderTopColor: Colors.dark[200],
          paddingTop: 8,
          paddingBottom: 8,
          height: 60,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
          marginTop: 4,
        },
        headerShown: false,
      })}
    >
      <Tab.Screen
        name="Home"
        component={HomeNavigator}
        options={{ tabBarLabel: VietnameseText.navigation.home }}
      />
      <Tab.Screen
        name="Budget"
        component={BudgetNavigator}
        options={{ tabBarLabel: VietnameseText.navigation.budget }}
      />
      <Tab.Screen
        name="Group"
        component={GroupNavigator}
        options={{ tabBarLabel: VietnameseText.navigation.group }}
      />
      <Tab.Screen
        name="Challenge"
        component={ChallengeScreen}
        options={{ tabBarLabel: 'Thử thách' }}
      />
      <Tab.Screen
        name="Reports"
        component={ReportsNavigator}
        options={{ tabBarLabel: VietnameseText.navigation.reports }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsNavigator}
        options={{ tabBarLabel: VietnameseText.navigation.settings }}
      />
    </Tab.Navigator>
  );
};

export default MainNavigator;
