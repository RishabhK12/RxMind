import 'package:flutter/material.dart';

class UserProfile {
  TimeOfDay? sleepStart;
  TimeOfDay? sleepEnd;
  String? eatingTimes;
  double? height;
  double? weight;
  int? sysBP;
  int? diaBP;
  String? dischargeImagePath;

  UserProfile({
    this.sleepStart,
    this.sleepEnd,
    this.eatingTimes,
    this.height,
    this.weight,
    this.sysBP,
    this.diaBP,
    this.dischargeImagePath,
  });
}
