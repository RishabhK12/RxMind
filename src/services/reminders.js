import { addDays, addHours, addWeeks } from 'date-fns';

export function calculateNextTrigger(time, frequency) {
  const date = new Date(time);
  if (frequency === 'daily') return addDays(date, 1);
  const match = frequency.match(/every (\d+) hours?/i);
  if (match) return addHours(date, parseInt(match[1], 10));
  if (frequency === 'weekly') return addWeeks(date, 1);
  return date;
}
