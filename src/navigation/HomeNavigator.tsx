import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { useApp } from '../context/AppContext';
import { ThemeColors } from '../constants/colors';

import DashboardScreen from '../screens/home/DashboardScreen';
import AddExpenseScreen from '../screens/home/AddExpenseScreen';
import AddIncomeScreen from '../screens/home/AddIncomeScreen';
import ScanReceiptScreen from '../screens/home/ScanReceiptScreen';
import ExpenseDetailScreen from '../screens/home/ExpenseDetailScreen';
import ChatScreen from '../screens/home/ChatScreen';
import TransactionHistoryScreen from '../screens/home/TransactionHistoryScreen';
import SavingsGoalsScreen from '../screens/SavingsGoalsScreen';

// Budget screens
import BudgetListScreen from '../screens/budget/BudgetListScreen';
import BudgetOverviewScreen from '../screens/budget/BudgetOverviewScreen';
import CreateBudgetScreen from '../screens/budget/CreateBudgetScreen';
import EditBudgetScreen from '../screens/budget/EditBudgetScreen';
import BudgetDetailScreen from '../screens/budget/BudgetDetailScreen';

// Group screens
import GroupListScreen from '../screens/group/GroupListScreen';
import CreateGroupScreen from '../screens/group/CreateGroupScreen';
import GroupDetailScreen from '../screens/group/GroupDetailScreen';
import InviteMembersScreen from '../screens/group/InviteMembersScreen';

// Other screens
import ReportsScreen from '../screens/ReportsScreen';
import ChallengeScreen from '../screens/ChallengeScreen';
import SettingsScreen from '../screens/SettingsScreen';
import ProfileScreen from '../screens/ProfileScreen';
import PremiumScreen from '../screens/PremiumScreen';
import AIChatScreen from '../screens/AIChatScreen';
import OnboardingScreen from '../screens/OnboardingScreen';
import { HomeStackParamList } from '../types';
import { Colors } from '../constants/colors';

const Stack = createStackNavigator<HomeStackParamList>();

const HomeNavigator: React.FC = () => {
  const { state } = useApp();
  const isDarkMode = state.theme === 'dark' || state.theme === 'system';
  const theme = isDarkMode ? ThemeColors.dark : ThemeColors.light;

  return (
    <Stack.Navigator
      initialRouteName="Dashboard"
      screenOptions={{
        headerStyle: {
          backgroundColor: theme.background,
          shadowColor: 'transparent',
          elevation: 0,
        },
        headerTintColor: theme.text,
        headerTitleStyle: {
          fontWeight: '600',
          fontSize: 18,
        },
        cardStyle: { backgroundColor: theme.background },
      }}
    >
      <Stack.Screen name="Dashboard" component={DashboardScreen} options={{ headerShown: false }} />
      <Stack.Screen
        name="AddExpense"
        component={AddExpenseScreen}
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="AddIncome"
        component={AddIncomeScreen}
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="ScanReceipt"
        component={ScanReceiptScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="ExpenseDetail"
        component={ExpenseDetailScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen name="Chat" component={ChatScreen} options={{ headerShown: false }} />
      <Stack.Screen
        name="SavingsGoals"
        component={SavingsGoalsScreen}
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="TransactionHistory"
        component={TransactionHistoryScreen}
        options={{
          headerShown: false,
        }}
      />

      {/* Budget Screens */}
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
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="EditBudget"
        component={EditBudgetScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="BudgetDetail"
        component={BudgetDetailScreen}
        options={{ headerShown: false }}
      />

      {/* Group Screens */}
      <Stack.Screen name="GroupList" component={GroupListScreen} options={{ headerShown: false }} />
      <Stack.Screen
        name="CreateGroup"
        component={CreateGroupScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="GroupDetail"
        component={GroupDetailScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="InviteMembers"
        component={InviteMembersScreen}
        options={{ headerShown: false }}
      />

      {/* Other Screens */}
      <Stack.Screen name="Reports" component={ReportsScreen} options={{ headerShown: false }} />
      <Stack.Screen name="Challenge" component={ChallengeScreen} options={{ headerShown: false }} />
      <Stack.Screen name="Settings" component={SettingsScreen} options={{ headerShown: false }} />
      <Stack.Screen name="Profile" component={ProfileScreen} options={{ headerShown: false }} />
      <Stack.Screen name="Premium" component={PremiumScreen} options={{ headerShown: false }} />
      <Stack.Screen name="AIChat" component={AIChatScreen} options={{ headerShown: false }} />
      <Stack.Screen
        name="Onboarding"
        component={OnboardingScreen}
        options={{ headerShown: false }}
      />
    </Stack.Navigator>
  );
};

export default HomeNavigator;
