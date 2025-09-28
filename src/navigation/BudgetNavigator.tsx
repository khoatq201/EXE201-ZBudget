import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import BudgetListScreen from '../screens/budget/BudgetListScreen';
import BudgetOverviewScreen from '../screens/budget/BudgetOverviewScreen';
import CreateBudgetScreen from '../screens/budget/CreateBudgetScreen';
import EditBudgetScreen from '../screens/budget/EditBudgetScreen';
import BudgetDetailScreen from '../screens/budget/BudgetDetailScreen';
import { BudgetStackParamList } from '../types';
import { Colors } from '../constants/colors';

const Stack = createStackNavigator<BudgetStackParamList>();

const BudgetNavigator: React.FC = () => {
  return (
    <Stack.Navigator
      initialRouteName="BudgetList"
      screenOptions={{
        headerStyle: {
          backgroundColor: Colors.primary[500],
          shadowColor: 'transparent',
          elevation: 0,
        },
        headerTintColor: '#FFFFFF',
        headerTitleStyle: {
          fontWeight: '600',
          fontSize: 18,
          color: '#FFFFFF',
        },
        cardStyle: { backgroundColor: '#1A2E3A' },
      }}
    >
      <Stack.Screen
        name="BudgetList"
        component={BudgetListScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="BudgetOverview"
        component={BudgetOverviewScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="CreateBudget"
        component={CreateBudgetScreen}
        options={{
          title: 'Tạo ngân sách',
        }}
      />
      <Stack.Screen
        name="EditBudget"
        component={EditBudgetScreen}
        options={{
          title: 'Chỉnh sửa ngân sách',
        }}
      />
      <Stack.Screen
        name="BudgetDetail"
        component={BudgetDetailScreen}
        options={{
          headerShown: false,
        }}
      />
    </Stack.Navigator>
  );
};

export default BudgetNavigator;
