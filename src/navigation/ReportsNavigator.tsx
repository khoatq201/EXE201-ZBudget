import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import ReportsScreen from '../screens/ReportsScreen';
import TransactionHistoryScreen from '../screens/home/TransactionHistoryScreen';
import { Colors } from '../constants/colors';

export type ReportsStackParamList = {
  ReportsMain: undefined;
  TransactionHistory:
    | {
        period?: string;
        category?: string;
        type?: 'expense' | 'income';
      }
    | undefined;
};

const Stack = createStackNavigator<ReportsStackParamList>();

const ReportsNavigator: React.FC = () => {
  return (
    <Stack.Navigator
      initialRouteName="ReportsMain"
      screenOptions={{
        headerStyle: {
          backgroundColor: Colors.background.primary,
          shadowColor: 'transparent',
          elevation: 0,
        },
        headerTintColor: Colors.text.primary,
        headerTitleStyle: {
          fontWeight: '600',
          fontSize: 18,
        },
        cardStyle: { backgroundColor: Colors.background.primary },
      }}
    >
      <Stack.Screen name="ReportsMain" component={ReportsScreen} options={{ headerShown: false }} />
      <Stack.Screen
        name="TransactionHistory"
        component={TransactionHistoryScreen}
        options={{
          headerShown: false,
        }}
      />
    </Stack.Navigator>
  );
};

export default ReportsNavigator;
