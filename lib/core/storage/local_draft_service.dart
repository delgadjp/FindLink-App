import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/irf_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalDraftService {
  static const String _draftKey = 'irf_drafts';
  
  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Convert IRF model to a JSON-serializable map
  Map<String, dynamic> _irfModelToSerializableMap(IRFModel irfData) {
    final Map<String, dynamic> data = irfData.toMap();
    // Convert Timestamp to ISO string for all DateTime fields
    if (data['dateTimeReported'] != null && data['dateTimeReported'] is Timestamp) {
      data['dateTimeReported'] = (data['dateTimeReported'] as Timestamp).toDate().toIso8601String();
    }
    if (data['dateTimeIncident'] != null && data['dateTimeIncident'] is Timestamp) {
      data['dateTimeIncident'] = (data['dateTimeIncident'] as Timestamp).toDate().toIso8601String();
    }
    if (data['dateTimeIncidentD'] != null && data['dateTimeIncidentD'] is Timestamp) {
      data['dateTimeIncidentD'] = (data['dateTimeIncidentD'] as Timestamp).toDate().toIso8601String();
    }
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
      data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    // Ensure all fields are present in the draft, even if null
    final allFields = IRFModel().toMap().keys;
    for (final key in allFields) {
      if (!data.containsKey(key)) {
        data[key] = null;
      }
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
    // Ensure all fields are present in the draft map
    final allFields = IRFModel().toMap().keys;
    for (final key in allFields) {
      if (!draft.containsKey(key)) {
        draft[key] = null;
      }
    }
    return IRFModel(
      id: draft['id'],
      documentId: draft['documentId'],
      typeOfIncident: draft['typeOfIncident'],
      copyFor: draft['copyFor'],
      dateTimeReported: draft['dateTimeReported'] != null ? DateTime.tryParse(draft['dateTimeReported']) : null,
      dateTimeIncident: draft['dateTimeIncident'] != null ? DateTime.tryParse(draft['dateTimeIncident']) : null,
      placeOfIncident: draft['placeOfIncident'],
      // Item A
      surnameA: draft['surnameA'],
      firstNameA: draft['firstNameA'],
      middleNameA: draft['middleNameA'],
      qualifierA: draft['qualifierA'],
      nicknameA: draft['nicknameA'],
      citizenshipA: draft['citizenshipA'],
      sexGenderA: draft['sexGenderA'],
      civilStatusA: draft['civilStatusA'],
      dateOfBirthA: draft['dateOfBirthA'],
      ageA: draft['ageA'] is int ? draft['ageA'] : int.tryParse(draft['ageA']?.toString() ?? ''),
      placeOfBirthA: draft['placeOfBirthA'],
      homePhoneA: draft['homePhoneA'],
      mobilePhoneA: draft['mobilePhoneA'],
      currentAddressA: draft['currentAddressA'],
      villageA: draft['villageA'],
      regionA: draft['regionA'],
      provinceA: draft['provinceA'],
      townCityA: draft['townCityA'],
      barangayA: draft['barangayA'],
      otherAddressA: draft['otherAddressA'],
      otherVillageA: draft['otherVillageA'],
      otherRegionA: draft['otherRegionA'],
      otherProvinceA: draft['otherProvinceA'],
      otherTownCityA: draft['otherTownCityA'],
      otherBarangayA: draft['otherBarangayA'],
      highestEducationAttainmentA: draft['highestEducationAttainmentA'],
      occupationA: draft['occupationA'],
      idCardPresentedA: draft['idCardPresentedA'],
      emailAddressA: draft['emailAddressA'],
      // Item B
      surnameB: draft['surnameB'],
      firstNameB: draft['firstNameB'],
      middleNameB: draft['middleNameB'],
      qualifierB: draft['qualifierB'],
      nicknameB: draft['nicknameB'],
      citizenshipB: draft['citizenshipB'],
      sexGenderB: draft['sexGenderB'],
      civilStatusB: draft['civilStatusB'],
      dateOfBirthB: draft['dateOfBirthB'],
      ageB: draft['ageB'] is int ? draft['ageB'] : int.tryParse(draft['ageB']?.toString() ?? ''),
      placeOfBirthB: draft['placeOfBirthB'],
      homePhoneB: draft['homePhoneB'],
      mobilePhoneB: draft['mobilePhoneB'],
      currentAddressB: draft['currentAddressB'],
      villageB: draft['villageB'],
      regionB: draft['regionB'],
      provinceB: draft['provinceB'],
      townCityB: draft['townCityB'],
      barangayB: draft['barangayB'],
      otherAddressB: draft['otherAddressB'],
      otherVillageB: draft['otherVillageB'],
      otherRegionB: draft['otherRegionB'],
      otherProvinceB: draft['otherProvinceB'],
      otherTownCityB: draft['otherTownCityB'],
      otherBarangayB: draft['otherBarangayB'],
      highestEducationAttainmentB: draft['highestEducationAttainmentB'],
      occupationB: draft['occupationB'],
      workAddressB: draft['workAddressB'],
      emailAddressB: draft['emailAddressB'],
      // Narrative
      narrative: draft['narrative'],
      typeOfIncidentD: draft['typeOfIncidentD'],
      dateTimeIncidentD: draft['dateTimeIncidentD'] != null ? DateTime.tryParse(draft['dateTimeIncidentD']) : null,
      placeOfIncidentD: draft['placeOfIncidentD'],
      // Metadata
      status: draft['status'],
      userId: draft['userId'],
      createdAt: draft['createdAt'] != null ? DateTime.tryParse(draft['createdAt']) : null,
      updatedAt: draft['updatedAt'] != null ? DateTime.tryParse(draft['updatedAt']) : null,
    );
  }
}
