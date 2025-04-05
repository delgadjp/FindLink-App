import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/irf_model.dart';
import 'package:intl/intl.dart';
import '../storage/local_draft_service.dart';  // Import the new local draft service

class IRFService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDraftService _localDraftService = LocalDraftService();  // Add local draft service
  
  // Expose the local draft service for direct access
  LocalDraftService get localDraftService => _localDraftService;
  
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
    
    try {
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
    } catch (e) {
      print('Error generating document ID: $e');
      // Fallback to a timestamp-based ID if transaction fails
      return 'IRF-$dateStr-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }
  
  // Submit new IRF with formal document ID
  Future<DocumentReference> submitIRF(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
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
      final docRef = irfCollection.doc(formalId);
      await docRef.set(dataWithMetadata);
      return docRef;
    } catch (e) {
      print('Error submitting IRF: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Save IRF draft locally using LocalDraftService
  Future<String> saveIRFDraft(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Save draft locally instead of to Firebase
      final String draftId = await _localDraftService.saveDraft(irfData);
      return draftId;
    } catch (e) {
      print('Error saving local draft: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Update existing IRF
  Future<void> updateIRF(String irfId, IRFModel irfData, {bool isDraft = false}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // If it's a draft, update locally instead of in Firebase
    if (isDraft) {
      await _localDraftService.updateDraft(irfId, irfData);
      return;
    }
    
    // Otherwise update in Firebase
    final dataWithMetadata = {
      ...irfData.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'submitted'
    };
    
    return await irfCollection.doc(irfId).update(dataWithMetadata);
  }
  
  // Get IRF by ID - check local drafts first, then Firebase
  Future<dynamic> getIRF(String irfId) async {
    // Check if it's a local draft
    if (irfId.startsWith('LOCAL_DRAFT_')) {
      return await _localDraftService.getDraft(irfId);
    }
    
    // Otherwise get from Firebase
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
  
  // Get user's IRF drafts from local storage
  Future<List<IRFModel>> getUserDrafts() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get drafts from local storage
    List<Map<String, dynamic>> localDrafts = await _localDraftService.getLocalDrafts();
    
    // Convert to IRF models
    return localDrafts.map((draft) => _localDraftService.draftToModel(draft)).toList();
  }
  
  // Delete IRF - check if it's a local draft first
  Future<void> deleteIRF(String irfId) async {
    // If it's a local draft, delete locally
    if (irfId.startsWith('LOCAL_DRAFT_')) {
      bool success = await _localDraftService.deleteDraft(irfId);
      if (!success) {
        throw Exception('Failed to delete local draft');
      }
      return;
    }
    
    // Otherwise delete from Firebase
    return await irfCollection.doc(irfId).delete();
  }
}
