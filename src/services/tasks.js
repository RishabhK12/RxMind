import { v4 as uuidv4 } from 'uuid';
import { calculateNextTrigger } from './reminders';
import { getTasks, saveTasks } from './storage';

// Add a new task (manual or AI/OCR)
export async function addTask(taskData) {
  const tasks = await getTasks();
  const newTask = {
    ...taskData,
    taskId: uuidv4(),
    nextTriggerTime: calculateNextTrigger(taskData.time, taskData.frequency),
    createdAt: new Date().toISOString(),
    completed: false,
    flagged: false,
  };
  tasks.push(newTask);
  await saveTasks(tasks);
  return newTask;
}

// Get all tasks for a user, ordered by next trigger time
export async function getUserTasks(userId) {
  const tasks = await getTasks();
  return tasks
    .filter(t => t.userId === userId)
    .sort((a, b) => new Date(a.nextTriggerTime) - new Date(b.nextTriggerTime));
}

// Get today's tasks for a user
export async function getTodayTasks(userId) {
  const tasks = await getUserTasks(userId);
  const today = new Date().toISOString().slice(0, 10);
  return tasks.filter(t => t.time.slice(0, 10) === today);
}

// Update a task (edit, mark complete, flag)
export async function updateTask(taskId, updates) {
  const tasks = await getTasks();
  const idx = tasks.findIndex(t => t.taskId === taskId);
  if (idx === -1) return null;
  tasks[idx] = { ...tasks[idx], ...updates };
  await saveTasks(tasks);
  return tasks[idx];
}

// Delete a task
export async function deleteTask(taskId) {
  let tasks = await getTasks();
  tasks = tasks.filter(t => t.taskId !== taskId);
  await saveTasks(tasks);
  return true;
}
