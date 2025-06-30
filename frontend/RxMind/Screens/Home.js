import { View, Text, Button } from 'react-native';

export default function Home({ navigation }) {
  return (
    <View style={{ padding: 30 }}>
      <Text style={{ fontSize: 24, marginBottom: 20 }}>🏥 Welcome to RxMind!</Text>
      <Button title="➕ Add Task" onPress={() => navigation.navigate('AddTask')} />
      <Button title="📋 Checklist" onPress={() => navigation.navigate('Checklist')} />
      <Button title="🩺 Pain Tracker" onPress={() => navigation.navigate('PainTracker')} />
    </View>
  );
}
