export class ComplianceDay {
  constructor({ date, total, completed, missed, percent }) {
    this.date = date;
    this.total = total;
    this.completed = completed;
    this.missed = missed;
    this.percent = percent;
  }
}
