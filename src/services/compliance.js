import { getTasks, saveCompliance, getCompliance } from './storage';
import { formatDate } from '../utils/dateUtils';

// Record a task completion or miss event
export async function recordTaskHistory(userId, taskId, completed) {
  const compliance = await getCompliance();
  const today = formatDate(new Date());
  let day = compliance.find(d => d.date === today && d.userId === userId);
  if (!day) {
    day = {
      date: today,
      userId,
      total: 0,
      completed: 0,
      missed: 0,
      percent: 0,
    };
    compliance.push(day);
  }
  day.total += 1;
  if (completed) day.completed += 1;
  else day.missed += 1;
  day.percent = day.total ? (day.completed / day.total) * 100 : 0;
  await saveCompliance(compliance);
}

// Get compliance stats for today
export async function getTodayCompliance(userId) {
  const compliance = await getCompliance();
  const today = formatDate(new Date());
  return (
    compliance.find(d => d.date === today && d.userId === userId) || {
      date: today,
      total: 0,
      completed: 0,
      missed: 0,
      percent: 0,
    }
  );
}

// Get compliance history (last N days)
export async function getComplianceHistory(userId, days = 7) {
  const compliance = await getCompliance();
  const today = new Date();
  const history = [];
  for (let i = 0; i < days; i++) {
    const date = formatDate(
      new Date(today.getFullYear(), today.getMonth(), today.getDate() - i),
    );
    const day = compliance.find(
      d => d.date === date && d.userId === userId,
    ) || { date, total: 0, completed: 0, missed: 0, percent: 0 };
    history.unshift(day);
  }
  return history;
}
