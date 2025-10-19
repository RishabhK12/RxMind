import 'med_model.dart';

class MedManager {
  final List<MedModel> _meds = [];

  List<MedModel> get meds => _meds;

  void addMed(MedModel med) {
    _meds.add(med);
  }

  void removeMed(String id) {
    _meds.removeWhere((m) => m.id == id);
  }

  void markDoseTaken(String id, DateTime takenAt) {
    final med = _meds.firstWhere((m) => m.id == id);
    med.doseHistory.add(takenAt);
  }

  void editMed(String id, MedModel updated) {
    final idx = _meds.indexWhere((m) => m.id == id);
    if (idx != -1) _meds[idx] = updated;
  }
}
