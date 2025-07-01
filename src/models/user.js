export class User {
  constructor({
    userId,
    sleepSchedule,
    eatingTimes,
    weight,
    height,
    baselineBP,
    dischargeUploaded,
  }) {
    this.userId = userId;
    this.sleepSchedule = sleepSchedule;
    this.eatingTimes = eatingTimes;
    this.weight = weight;
    this.height = height;
    this.baselineBP = baselineBP;
    this.dischargeUploaded = dischargeUploaded;
  }
}
