import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/irf_model.dart';
import 'package:intl/intl.dart';

class IRFService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference - Uses only irf-test collection
  CollectionReference get irfCollection => _firestore.collection('irf-test');
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Generate a formal document ID format: IRF-YYYYMMDD-XXXX (where XXXX is sequential)
  Future<String> generateFormalDocumentId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    
    // Use a special document in the irf-test collection for counters
    final String counterDocId = 'counter_$dateStr';
    final counterDocRef = irfCollection.doc(counterDocId);
    
    // Use transaction to safely increment counter
    return _firestore.runTransaction<String>((transaction) async {
      DocumentSnapshot counterDoc = await transaction.get(counterDocRef);
      
      int currentCount = 1;
      if (counterDoc.exists) {
        // Increment existing counter
        currentCount = (counterDoc.data() as Map<String, dynamic>)['count'] + 1;
        transaction.update(counterDocRef, {'count': currentCount});
      } else {
        // Create counter if it doesn't exist
        transaction.set(counterDocRef, {
          'count': currentCount, 
          'date': dateStr,
          'type': 'counter', // Mark this document as a counter to distinguish it from IRF documents
          'updatedAt': FieldValue.serverTimestamp()
        });
      }
      
      // Format sequential number with leading zeros
      String sequentialNumber = currentCount.toString().padLeft(4, '0');
      return 'IRF-$dateStr-$sequentialNumber';
    });
  }
  
  // Submit new IRF with formal document ID
  Future<DocumentReference> submitIRF(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Generate formal document ID
    final String formalId = await generateFormalDocumentId();
    
    // Add user ID and timestamps
    final dataWithMetadata = {
      ...irfData.toMap(),
      'documentId': formalId,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'submitted', // pending, submitted, approved, rejected
      'type': 'report' // Mark this document as an IRF report
    };
    
    // Use the formal ID as the document ID
    return await irfCollection.doc(formalId).set(dataWithMetadata).then((_) {
      return irfCollection.doc(formalId);
    });
  }
  
  // Save IRF draft with formal document ID prefixed with DRAFT-
  Future<DocumentReference> saveIRFDraft(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Generate formal document ID for draft
    final String formalId = await generateFormalDocumentId();
    final String draftId = 'DRAFT-$formalId';
    
    final dataWithMetadata = {
      ...irfData.toMap(),
      'documentId': draftId,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'draft',
      'type': 'draft' // Mark this document as a draft
    };
    
    // Use the draft ID as the document ID
    return await irfCollection.doc(draftId).set(dataWithMetadata).then((_) {
      return irfCollection.doc(draftId);
    });
  }
  
  // Update existing IRF
  Future<void> updateIRF(String irfId, IRFModel irfData, {bool isDraft = false}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final dataWithMetadata = {
      ...irfData.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': isDraft ? 'draft' : 'submitted'
    };
    
    return await irfCollection.doc(irfId).update(dataWithMetadata);
  }
  
  // Get IRF by ID
  Future<DocumentSnapshot> getIRF(String irfId) async {
    return await irfCollection.doc(irfId).get();
  }
  
  // Get user's IRFs
  Stream<QuerySnapshot> getUserIRFs() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    return irfCollection
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: 'report') // Only get reports, not counters
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
  
  // Get user's IRF drafts
  Stream<QuerySnapshot> getUserDrafts() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    return irfCollection
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'draft')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
  
  // Delete IRF
  Future<void> deleteIRF(String irfId) async {
    return await irfCollection.doc(irfId).delete();
  }
}
