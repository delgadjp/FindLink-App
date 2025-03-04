import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/missing_person_model.dart';

class MissingPersonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'missingPersons';

  Stream<List<MissingPerson>> getMissingPersons() {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissingPerson.fromSnapshot(doc))
            .toList());
  }

  Future<MissingPerson?> getMissingPersonById(String caseId) async {
    final doc = await _firestore
        .collection(collection)
        .where('case_id', isEqualTo: caseId)
        .get();
    
    if (doc.docs.isEmpty) return null;
    return MissingPerson.fromSnapshot(doc.docs.first);
  }

  Future<void> updateMissingPerson(String caseId, Map<String, dynamic> data) async {
    final doc = await _firestore
        .collection(collection)
        .where('case_id', isEqualTo: caseId)
        .get();
    
    if (doc.docs.isNotEmpty) {
      await doc.docs.first.reference.update(data);
    }
  }
}
