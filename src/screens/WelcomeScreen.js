import React, { useEffect, useState } from 'react';
import { View, Text, Button, TextInput } from 'react-native';
import { generateUserId } from '../services/uuid';
import { saveUser, getUser } from '../services/storage';

export default function WelcomeScreen({ navigation }) {
  const [userId, setUserId] = useState('');
  const [weight, setWeight] = useState('');
  const [height, setHeight] = useState('');
  const [sleepSchedule, setSleepSchedule] = useState('');
  const [eatingTimes, setEatingTimes] = useState('');
  const [baselineBP, setBaselineBP] = useState('');
  const [dischargeUploaded, setDischargeUploaded] = useState(false);

  useEffect(() => {
    getUser().then(user => {
      if (user) {
        setUserId(user.userId);
        navigation.replace('Home');
      }
    });
  }, []);

  const handleStart = async () => {
    const id = generateUserId();
    setUserId(id);
    const user = {
      userId: id,
      weight,
      height,
      sleepSchedule,
      eatingTimes,
      baselineBP,
      dischargeUploaded,
    };
    await saveUser(user);
    navigation.replace('Home');
  };

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
      <Text style={{ fontSize: 24, marginBottom: 20 }}>Welcome to RxMind</Text>
      <TextInput
        placeholder="Weight"
        value={weight}
        onChangeText={setWeight}
        style={{ marginBottom: 10, borderWidth: 1, padding: 8 }}
      />
      <TextInput
        placeholder="Height"
        value={height}
        onChangeText={setHeight}
        style={{ marginBottom: 10, borderWidth: 1, padding: 8 }}
      />
      <TextInput
        placeholder="Sleep Schedule"
        value={sleepSchedule}
        onChangeText={setSleepSchedule}
        style={{ marginBottom: 10, borderWidth: 1, padding: 8 }}
      />
      <TextInput
        placeholder="Eating Times"
        value={eatingTimes}
        onChangeText={setEatingTimes}
        style={{ marginBottom: 10, borderWidth: 1, padding: 8 }}
      />
      <TextInput
        placeholder="Baseline Blood Pressure"
        value={baselineBP}
        onChangeText={setBaselineBP}
        style={{ marginBottom: 10, borderWidth: 1, padding: 8 }}
      />
      <Button title="Start" onPress={handleStart} />
    </View>
  );
}
