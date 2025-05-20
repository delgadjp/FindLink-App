import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModalUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Screen types for tracking separate acceptances
  static const String SCREEN_FILL_UP_FORM = 'fill_up_form';
  static const String SCREEN_SUBMIT_TIP = 'submit_tip';
  static const String SCREEN_SUBMIT_TIP_COMPLIANCE = 'submitTipComplianceAccepted';
  static const String SCREEN_FILL_UP_FORM_COMPLIANCE = 'fillUpFormComplianceAccepted';

  // Show legal disclaimer modal before privacy policy
  static void showLegalDisclaimerModal(
    BuildContext context, {
    required Function onAccept,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            title: Text(
              'Important Notice',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: Text(
                'Submitting false information in this Report Form is a criminal offense. Misuse of this form can lead to legal consequences, including imprisonment. Ensure all details provided are accurate and truthful.\n\nBy proceeding, you acknowledge and agree to these terms.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'I Understand',
                  style: TextStyle(color: Color(0xFF0D47A1)),
                ),
                onPressed: () {
                  // Close the disclaimer modal
                  Navigator.of(context).pop();
                  // Call the onAccept callback
                  onAccept();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show privacy policy modal
  static void showPrivacyPolicyModal(
    BuildContext context, {
    required Function(bool) onAcceptanceUpdate,
    Function? onCancel,
    String screenType = '', // Added screenType parameter
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Less rounded corners
            ),
            title: Text(
              'Data Privacy Act Compliance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(text: 'In accordance with '),
                    TextSpan(
                      text: 'Republic Act No. 10173',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ', the '),
                    TextSpan(
                      text: 'Data Privacy Act of 2012',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ', we ensure that your personal data will be processed securely and used solely for law enforcement purposes.\n\n'
                        'By submitting this form, you ',
                    ),
                    TextSpan(
                      text: 'voluntarily provide your personal data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' for official police use. Your information will not be disclosed to unauthorized entities.\n\n'
                        'For more details, visit the ',
                    ),
                    TextSpan(
                      text: 'National Privacy Commission',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Disagree',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  // Update the user's privacy policy status
                  updatePrivacyPolicyAcceptance(false, onAcceptanceUpdate, screenType);
                  // Close the dialog
                  Navigator.of(context).pop();
                  // Call the onCancel callback if provided
                  if (onCancel != null) {
                    onCancel();
                  }
                },
              ),
              TextButton(
                child: Text(
                  'Accept',
                  style: TextStyle(color: Color(0xFF0D47A1)),
                ),
                onPressed: () {
                  // Update the user's privacy policy status
                  updatePrivacyPolicyAcceptance(true, onAcceptanceUpdate, screenType);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to check if user has accepted privacy policy for a specific screen
  static Future<bool> checkPrivacyPolicyAcceptance({String screenType = ''}) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final QuerySnapshot userDoc = await _firestore
            .collection('users')
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data() as Map<String, dynamic>;
          return userData['privacyPolicyAccepted'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking privacy policy acceptance: $e');
      return false;
    }
  }

  // New method to update privacy policy acceptance status in Firestore
  static Future<void> updatePrivacyPolicyAcceptance(
    bool accepted,
    Function(bool) onAcceptanceUpdate,
    String screenType,
  ) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final QuerySnapshot userDoc = await _firestore
            .collection('users')
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          await userDoc.docs.first.reference.update({
            'privacyPolicyAccepted': accepted,
            'privacyPolicyAcceptedAt': accepted ? FieldValue.serverTimestamp() : null,
          });
          onAcceptanceUpdate(accepted);
        }
      }
    } catch (e) {
      print('Error updating privacy policy acceptance: $e');
      onAcceptanceUpdate(false);
    }
  }

  // Helper method to check if user has accepted compliance for a specific screen
  static Future<bool> checkScreenComplianceAccepted(String screenKey) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final QuerySnapshot userDoc = await _firestore
            .collection('users')
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data() as Map<String, dynamic>;
          return userData[screenKey] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking compliance acceptance for $screenKey: $e');
      return false;
    }
  }

  // New method to update compliance acceptance for a specific screen
  static Future<void> updateScreenComplianceAccepted(
    String screenKey,
    bool accepted,
    Function(bool) onAcceptanceUpdate,
  ) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final QuerySnapshot userDoc = await _firestore
            .collection('users')
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          await userDoc.docs.first.reference.update({
            screenKey: accepted,
            screenKey + 'At': accepted ? FieldValue.serverTimestamp() : null,
          });
          onAcceptanceUpdate(accepted);
        }
      }
    } catch (e) {
      print('Error updating compliance acceptance for $screenKey: $e');
      onAcceptanceUpdate(false);
    }
  }
}