import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/missing_person_model.dart';

class MissingPersonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection = 'missingPersons';

  Stream<List<MissingPerson>> getMissingPersons() {
    // Check if user is authenticated first
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('User not authenticated - returning empty stream');
      return Stream.value(<MissingPerson>[]);
    }
    
    print('User authenticated: ${currentUser.uid}');
    
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) {
          try {
            print('Received ${snapshot.docs.length} missing person documents');
            return snapshot.docs
                .map((doc) => MissingPerson.fromSnapshot(doc))
                .toList();
          } catch (e) {
            print('Error parsing missing persons: $e');
            return <MissingPerson>[];
          }
        })
        .handleError((error) {
          print('Stream error in getMissingPersons: $error');
          return <MissingPerson>[];
        });
  }
  Future<MissingPerson?> getMissingPersonById(String alarmId) async {
    final doc = await _firestore
        .collection(collection)
        .where('alarm_id', isEqualTo: alarmId)
        .get();
    
    if (doc.docs.isEmpty) return null;
    return MissingPerson.fromSnapshot(doc.docs.first);
  }

  Future<void> updateMissingPerson(String alarmId, Map<String, dynamic> data) async {
    final doc = await _firestore
        .collection(collection)
        .where('alarm_id', isEqualTo: alarmId)
        .get();
    
    if (doc.docs.isNotEmpty) {
      await doc.docs.first.reference.update(data);
    }
  }
    // New method to get user's missing person cases
  Future<List<Map<String, dynamic>>> getUserMissingPersonCases() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          return null;
        }
          return {
          'id': doc.id,
          'caseNumber': data['alarm_id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown Person',
          'dateCreated': _formatTimestamp(data['datetime_reported']),
          'status': status,
          'source': 'missingPersons',
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
          'progress': _generateProgressSteps(status),
        };
      }).where((element) => element != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching missing person cases: $e');
      return [];
    }
  }
  
  // Helper method to format timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is Map && timestamp['seconds'] != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return '';
    }
  }
  
  // Generate progress steps based on status
  List<Map<String, String>> _generateProgressSteps(String currentStatus) {
    // Map to convert status to step number (1-indexed)
    final Map<String, int> statusToStep = {
      'Reported': 1,
      'Under Review': 2,
      'Case Verified': 3,
      'In Progress': 4,
      'Resolved Case': 5,
      'Unresolved Case': 6,
      'Resolved': 5, // Map 'Resolved' to 'Resolved Case' step
    };
    
    final List<Map<String, String>> caseProgressSteps = [
      {'stage': 'Reported', 'status': 'Pending'},
      {'stage': 'Under Review', 'status': 'Pending'},
      {'stage': 'Case Verified', 'status': 'Pending'},
      {'stage': 'In Progress', 'status': 'Pending'},
      {'stage': 'Resolved Case', 'status': 'Pending'},
      {'stage': 'Unresolved Case', 'status': 'Pending'},
    ];
    
    final int currentStep = statusToStep[currentStatus] ?? 1;
    
    return caseProgressSteps.map((step) {
      final int stepNumber = caseProgressSteps.indexOf(step) + 1;
      String status;
      
      if (stepNumber < currentStep) {
        status = 'Completed';
      } else if (stepNumber == currentStep) {
        status = 'In Progress';
      } else {
        status = 'Pending';
      }
      
      return {
        'stage': step['stage'] ?? '',
        'status': status,
      };
    }).toList();
  }
}
