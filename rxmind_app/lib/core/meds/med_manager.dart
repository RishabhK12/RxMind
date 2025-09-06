import 'med_model.dart';

class MedManager {
  List<MedModel> _meds = [];

  List<MedModel> get meds => _meds;

  void addMed(MedModel med) {
    _meds.add(med);
    // TODO: Persist to local storage
  }

  void removeMed(String id) {
    _meds.removeWhere((m) => m.id == id);
    // TODO: Update local storage
  }

  void markDoseTaken(String id, DateTime takenAt) {
    final med = _meds.firstWhere((m) => m.id == id);
    med.doseHistory.add(takenAt);
    // TODO: Update adherence, local storage
  }

  void editMed(String id, MedModel updated) {
    final idx = _meds.indexWhere((m) => m.id == id);
    if (idx != -1) _meds[idx] = updated;
    // TODO: Update local storage
  }

  // TODO: Adherence analytics, dose scheduling, integration with TaskManager
}
