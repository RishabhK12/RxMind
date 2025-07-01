import { format, isToday, isThisWeek, parseISO } from 'date-fns';

export function formatDate(date) {
  return format(new Date(date), 'yyyy-MM-dd');
}

export function isDateToday(date) {
  return isToday(new Date(date));
}

export function isDateThisWeek(date) {
  return isThisWeek(new Date(date));
}

export function parseDate(dateString) {
  return parseISO(dateString);
}
