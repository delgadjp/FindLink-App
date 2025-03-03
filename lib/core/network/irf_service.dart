import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/irf_model.dart';

class IRFService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference
  CollectionReference get irfCollection => _firestore.collection('irf-app');
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Submit new IRF
  Future<DocumentReference> submitIRF(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Add user ID and timestamps
    final dataWithMetadata = {
      ...irfData.toMap(),
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'submitted' // pending, submitted, approved, rejected
    };
    
    return await irfCollection.add(dataWithMetadata);
  }
  
  // Save IRF draft
  Future<DocumentReference> saveIRFDraft(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final dataWithMetadata = {
      ...irfData.toMap(),
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'draft'
    };
    
    return await irfCollection.add(dataWithMetadata);
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
