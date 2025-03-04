import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getTotalCasesCount() {
    return _firestore
        .collection('missingPersons')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
