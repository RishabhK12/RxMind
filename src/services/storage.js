import AsyncStorage from '@react-native-async-storage/async-storage';

export async function saveUser(user) {
  await AsyncStorage.setItem('user', JSON.stringify(user));
}

export async function getUser() {
  const user = await AsyncStorage.getItem('user');
  return user ? JSON.parse(user) : null;
}

export async function saveTasks(tasks) {
  await AsyncStorage.setItem('tasks', JSON.stringify(tasks));
}

export async function getTasks() {
  const tasks = await AsyncStorage.getItem('tasks');
  return tasks ? JSON.parse(tasks) : [];
}

export async function saveCompliance(compliance) {
  await AsyncStorage.setItem('compliance', JSON.stringify(compliance));
}

export async function getCompliance() {
  const compliance = await AsyncStorage.getItem('compliance');
  return compliance ? JSON.parse(compliance) : [];
}
