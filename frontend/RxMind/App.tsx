import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import Home from './Screens/Home';
import AddTask from './Screens/AddTask';
import Checklist from './Screens/Checklist';
import PainTracker from './Screens/PainTracker';

export type RootStackParamList = {
  Home: undefined;
  AddTask: undefined;
  Checklist: undefined;
  PainTracker: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Home">
        <Stack.Screen name="Home" component={Home} />
        <Stack.Screen name="AddTask" component={AddTask} />
        <Stack.Screen name="Checklist" component={Checklist} />
        <Stack.Screen name="PainTracker" component={PainTracker} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
