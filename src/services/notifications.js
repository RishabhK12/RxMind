import PushNotification from "react-native-push-notification";

// Call this once in your app entry point (e.g., App.js)
export function configureNotifications() {
  PushNotification.configure({
    onNotification: function (notification) {
      // Handle notification tap if needed
    },
    requestPermissions: true,
  });
}

// Schedule a notification for a task
export function scheduleTaskNotification(task) {
  if (!task.nextTriggerTime) return;
  PushNotification.localNotificationSchedule({
    title: task.title,
    message: task.description || "Task Reminder",
    date: new Date(task.nextTriggerTime), // JS Date object
    allowWhileIdle: true,
    userInfo: { taskId: task.taskId },
  });
}

// Cancel all notifications for a user (e.g., on logout or data reset)
export function cancelAllNotifications() {
  PushNotification.cancelAllLocalNotifications();
}

// Reschedule notifications for all tasks (e.g., after editing tasks)
export async function rescheduleAllTaskNotifications(tasks) {
  cancelAllNotifications();
  tasks.forEach(scheduleTaskNotification);
}
