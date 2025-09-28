import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import GroupListScreen from '../screens/group/GroupListScreen';
import CreateGroupScreen from '../screens/group/CreateGroupScreen';
import GroupDetailScreen from '../screens/group/GroupDetailScreen';
import InviteMembersScreen from '../screens/group/InviteMembersScreen';
import { GroupStackParamList } from '../types';
import { Colors } from '../constants/colors';

const Stack = createStackNavigator<GroupStackParamList>();

const GroupNavigator: React.FC = () => {
  return (
    <Stack.Navigator
      initialRouteName="GroupList"
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
      <Stack.Screen name="GroupList" component={GroupListScreen} options={{ headerShown: false }} />
      <Stack.Screen
        name="CreateGroup"
        component={CreateGroupScreen}
        options={{
          title: 'Tạo nhóm',
        }}
      />
      <Stack.Screen
        name="GroupDetail"
        component={GroupDetailScreen}
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="InviteMembers"
        component={InviteMembersScreen}
        options={{
          title: 'Mời thành viên',
        }}
      />
    </Stack.Navigator>
  );
};

export default GroupNavigator;
