export class Task {
  constructor({
    taskId,
    userId,
    title,
    description,
    type,
    time,
    frequency,
    nextTriggerTime,
    notes,
    flagged,
    completed,
    createdAt,
  }) {
    this.taskId = taskId;
    this.userId = userId;
    this.title = title;
    this.description = description;
    this.type = type;
    this.time = time;
    this.frequency = frequency;
    this.nextTriggerTime = nextTriggerTime;
    this.notes = notes;
    this.flagged = flagged;
    this.completed = completed;
    this.createdAt = createdAt;
  }
}
