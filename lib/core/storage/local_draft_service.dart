import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/irf_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocalDraftService {
  static const String _draftKey = 'irf_drafts';
  
  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Convert IRF model to a JSON-serializable map
  Map<String, dynamic> _irfModelToSerializableMap(IRFModel irfData) {
    final Map<String, dynamic> data = irfData.toMap();
    
    // Convert DateTime fields to strings
    if (data['dateTimeReported'] != null) {
      data['dateTimeReported'] = data['dateTimeReported'].toIso8601String();
    }
    
    if (data['dateTimeIncident'] != null) {
      data['dateTimeIncident'] = data['dateTimeIncident'].toIso8601String();
    }
    
    if (data['dateTimeIncidentD'] != null) {
      data['dateTimeIncidentD'] = data['dateTimeIncidentD'].toIso8601String();
    }
    
    // Handle nested DateTime objects in item A and item C
    if (data['itemA'] != null && data['itemA'] is Map) {
      final Map<String, dynamic> itemA = Map<String, dynamic>.from(data['itemA']);
      if (itemA['dateOfBirth'] != null && itemA['dateOfBirth'] is DateTime) {
        itemA['dateOfBirth'] = (itemA['dateOfBirth'] as DateTime).toIso8601String();
      }
      data['itemA'] = itemA;
    }
    
    if (data['itemC'] != null && data['itemC'] is Map) {
      final Map<String, dynamic> itemC = Map<String, dynamic>.from(data['itemC']);
      if (itemC['dateOfBirth'] != null && itemC['dateOfBirth'] is DateTime) {
        itemC['dateOfBirth'] = (itemC['dateOfBirth'] as DateTime).toIso8601String();
      }
      data['itemC'] = itemC;
    }
    
    return data;
  }

  // Save a draft locally
  Future<String> saveDraft(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a local draft ID
      final draftId = 'LOCAL_DRAFT_${DateTime.now().millisecondsSinceEpoch}';
      
      // Convert IRF model to a serializable map
      Map<String, dynamic> serializableData = _irfModelToSerializableMap(irfData);
      
      // Add metadata to the draft
      final dataWithMetadata = {
        ...serializableData,
        'id': draftId,
        'documentId': draftId,
        'userId': currentUserId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'status': 'draft',
        'type': 'local_draft'
      };
      
      // Get existing drafts
      List<Map<String, dynamic>> drafts = await getLocalDrafts();
      
      // Add new draft
      drafts.add(dataWithMetadata);
      
      // Save all drafts
      await prefs.setString(_draftKey, jsonEncode(drafts));
      
      return draftId;
    } catch (e) {
      print('Error saving local draft: $e');
      rethrow;
    }
  }
  
  // Get all drafts for the current user
  Future<List<Map<String, dynamic>>> getLocalDrafts() async {
    if (currentUserId == null) {
      return [];
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? draftsJson = prefs.getString(_draftKey);
      
      if (draftsJson == null || draftsJson.isEmpty) {
        return [];
      }
      
      List<dynamic> allDrafts = jsonDecode(draftsJson);
      
      // Filter drafts for current user
      return allDrafts
          .where((draft) => draft['userId'] == currentUserId)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error getting local drafts: $e');
      return [];
    }
  }
  
  // Get a specific draft by ID
  Future<Map<String, dynamic>?> getDraft(String draftId) async {
    try {
      List<Map<String, dynamic>> drafts = await getLocalDrafts();
      return drafts.firstWhere(
        (draft) => draft['id'] == draftId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      print('Error getting draft: $e');
      return null;
    }
  }
  
  // Update an existing draft
  Future<bool> updateDraft(String draftId, IRFModel irfData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> drafts = await getLocalDrafts();
      
      // Find the draft to update
      int index = drafts.indexWhere((draft) => draft['id'] == draftId);
      
      if (index == -1) {
        return false; // Draft not found
      }
      
      // Convert IRF model to a serializable map
      Map<String, dynamic> serializableData = _irfModelToSerializableMap(irfData);
      
      // Update the draft
      Map<String, dynamic> updatedDraft = {
        ...drafts[index],
        ...serializableData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      drafts[index] = updatedDraft;
      
      // Save all drafts
      await prefs.setString(_draftKey, jsonEncode(drafts));
      
      return true;
    } catch (e) {
      print('Error updating draft: $e');
      return false;
    }
  }
  
  // Delete a draft
  Future<bool> deleteDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> drafts = await getLocalDrafts();
      
      // Filter out the draft to delete
      drafts.removeWhere((draft) => draft['id'] == draftId);
      
      // Save remaining drafts
      await prefs.setString(_draftKey, jsonEncode(drafts));
      
      return true;
    } catch (e) {
      print('Error deleting draft: $e');
      return false;
    }
  }
  
  // Convert local draft to IRF model
  IRFModel draftToModel(Map<String, dynamic> draft) {
    return IRFModel(
      id: draft['id'],
      documentId: draft['documentId'],
      typeOfIncident: draft['typeOfIncident'],
      copyFor: draft['copyFor'],
      dateTimeReported: draft['dateTimeReported'] != null 
          ? DateTime.parse(draft['dateTimeReported']) 
          : null,
      dateTimeIncident: draft['dateTimeIncident'] != null 
          ? DateTime.parse(draft['dateTimeIncident']) 
          : null,
      placeOfIncident: draft['placeOfIncident'],
      itemA: draft['itemA'],
      itemC: draft['itemC'],
      narrative: draft['narrative'],
      typeOfIncidentD: draft['typeOfIncidentD'],
      dateTimeIncidentD: draft['dateTimeIncidentD'] != null 
          ? DateTime.parse(draft['dateTimeIncidentD']) 
          : null,
      placeOfIncidentD: draft['placeOfIncidentD'],
      status: draft['status'],
      userId: draft['userId'],
      createdAt: draft['createdAt'] != null 
          ? DateTime.parse(draft['createdAt']) 
          : null,
      updatedAt: draft['updatedAt'] != null 
          ? DateTime.parse(draft['updatedAt']) 
          : null,
    );
  }
}
