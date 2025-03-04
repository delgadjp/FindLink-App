import 'package:cloud_firestore/cloud_firestore.dart';

class IRFModel {
  // Basic incident info
  final String? irfEntryNumber;
  final String? typeOfIncident;
  final String? copyFor;
  final DateTime? dateTimeReported;
  final DateTime? dateTimeIncident;
  final String? placeOfIncident;
  
  // Reporting person data
  final ReportingPersonData reportingPerson;
  
  // Suspect data
  final SuspectData suspect;
  
  // Victim data
  final VictimData victim;
  
  // Narrative
  final String? narrative;
  
  // Signatures and administrative data
  final String? nameOfReportingPerson;
  final String? signatureOfReportingPerson;
  final String? nameOfAdministeringOfficer;
  final String? signatureOfAdministeringOfficer;
  final String? rankNameOfPoliceOfficer;
  final String? signatureOfPoliceOfficer;
  final String? rankNameOfDeskOfficer;
  final String? signatureOfDeskOfficer;
  final String? blotterEntryNr;
  
  // Police station information
  final String? nameOfPoliceStation;
  final String? telephonePoliceStation;
  final String? investigatorOnCase;
  final String? mobilePhoneInvestigator;
  final String? nameOfChief;
  final String? mobilePhoneChief;

  IRFModel({
    this.irfEntryNumber,
    this.typeOfIncident,
    this.copyFor,
    this.dateTimeReported,
    this.dateTimeIncident,
    this.placeOfIncident,
    required this.reportingPerson,
    required this.suspect,
    required this.victim,
    this.narrative,
    this.nameOfReportingPerson,
    this.signatureOfReportingPerson,
    this.nameOfAdministeringOfficer,
    this.signatureOfAdministeringOfficer,
    this.rankNameOfPoliceOfficer,
    this.signatureOfPoliceOfficer,
    this.rankNameOfDeskOfficer,
    this.signatureOfDeskOfficer,
    this.blotterEntryNr,
    this.nameOfPoliceStation,
    this.telephonePoliceStation,
    this.investigatorOnCase,
    this.mobilePhoneInvestigator,
    this.nameOfChief,
    this.mobilePhoneChief,
  });

  // Convert model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'irfEntryNumber': irfEntryNumber,
      'typeOfIncident': typeOfIncident,
      'copyFor': copyFor,
      'dateTimeReported': dateTimeReported != null ? Timestamp.fromDate(dateTimeReported!) : null,
      'dateTimeIncident': dateTimeIncident != null ? Timestamp.fromDate(dateTimeIncident!) : null,
      'placeOfIncident': placeOfIncident,
      'reportingPerson': reportingPerson.toMap(),
      'suspect': suspect.toMap(),
      'victim': victim.toMap(),
      'narrative': narrative,
      'nameOfReportingPerson': nameOfReportingPerson,
      'signatureOfReportingPerson': signatureOfReportingPerson,
      'nameOfAdministeringOfficer': nameOfAdministeringOfficer,
      'signatureOfAdministeringOfficer': signatureOfAdministeringOfficer,
      'rankNameOfPoliceOfficer': rankNameOfPoliceOfficer,
      'signatureOfPoliceOfficer': signatureOfPoliceOfficer,
      'rankNameOfDeskOfficer': rankNameOfDeskOfficer,
      'signatureOfDeskOfficer': signatureOfDeskOfficer,
      'blotterEntryNr': blotterEntryNr,
      'nameOfPoliceStation': nameOfPoliceStation,
      'telephonePoliceStation': telephonePoliceStation,
      'investigatorOnCase': investigatorOnCase,
      'mobilePhoneInvestigator': mobilePhoneInvestigator,
      'nameOfChief': nameOfChief,
      'mobilePhoneChief': mobilePhoneChief,
    };
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'irfEntryNumber': irfEntryNumber,
      'typeOfIncident': typeOfIncident,
      'copyFor': copyFor,
      'dateTimeReported': dateTimeReported?.toIso8601String(),
      'dateTimeIncident': dateTimeIncident?.toIso8601String(),
      'placeOfIncident': placeOfIncident,
      'reportingPerson': reportingPerson.toJson(),
      'suspect': suspect.toJson(),
      'victim': victim.toJson(),
      'narrative': narrative,
      'nameOfReportingPerson': nameOfReportingPerson,
      'signatureOfReportingPerson': signatureOfReportingPerson,
      'nameOfAdministeringOfficer': nameOfAdministeringOfficer,
      'signatureOfAdministeringOfficer': signatureOfAdministeringOfficer,
      'rankNameOfPoliceOfficer': rankNameOfPoliceOfficer,
      'signatureOfPoliceOfficer': signatureOfPoliceOfficer,
      'rankNameOfDeskOfficer': rankNameOfDeskOfficer,
      'signatureOfDeskOfficer': signatureOfDeskOfficer,
      'blotterEntryNr': blotterEntryNr,
      'nameOfPoliceStation': nameOfPoliceStation,
      'telephonePoliceStation': telephonePoliceStation,
      'investigatorOnCase': investigatorOnCase,
      'mobilePhoneInvestigator': mobilePhoneInvestigator,
      'nameOfChief': nameOfChief,
      'mobilePhoneChief': mobilePhoneChief,
    };
  }

  // Create model from Map (Firestore document)
  factory IRFModel.fromMap(Map<String, dynamic> map) {
    return IRFModel(
      irfEntryNumber: map['irfEntryNumber'],
      typeOfIncident: map['typeOfIncident'],
      copyFor: map['copyFor'],
      dateTimeReported: map['dateTimeReported'] != null 
          ? (map['dateTimeReported'] as Timestamp).toDate() 
          : null,
      dateTimeIncident: map['dateTimeIncident'] != null 
          ? (map['dateTimeIncident'] as Timestamp).toDate() 
          : null,
      placeOfIncident: map['placeOfIncident'],
      reportingPerson: ReportingPersonData.fromMap(map['reportingPerson'] ?? {}),
      suspect: SuspectData.fromMap(map['suspect'] ?? {}),
      victim: VictimData.fromMap(map['victim'] ?? {}),
      narrative: map['narrative'],
      nameOfReportingPerson: map['nameOfReportingPerson'],
      signatureOfReportingPerson: map['signatureOfReportingPerson'],
      nameOfAdministeringOfficer: map['nameOfAdministeringOfficer'],
      signatureOfAdministeringOfficer: map['signatureOfAdministeringOfficer'],
      rankNameOfPoliceOfficer: map['rankNameOfPoliceOfficer'],
      signatureOfPoliceOfficer: map['signatureOfPoliceOfficer'],
      rankNameOfDeskOfficer: map['rankNameOfDeskOfficer'],
      signatureOfDeskOfficer: map['signatureOfDeskOfficer'],
      blotterEntryNr: map['blotterEntryNr'],
      nameOfPoliceStation: map['nameOfPoliceStation'],
      telephonePoliceStation: map['telephonePoliceStation'],
      investigatorOnCase: map['investigatorOnCase'],
      mobilePhoneInvestigator: map['mobilePhoneInvestigator'],
      nameOfChief: map['nameOfChief'],
      mobilePhoneChief: map['mobilePhoneChief'],
    );
  }

  factory IRFModel.fromJson(Map<String, dynamic> json) {
    return IRFModel(
      irfEntryNumber: json['irfEntryNumber'],
      typeOfIncident: json['typeOfIncident'],
      copyFor: json['copyFor'],
      dateTimeReported: json['dateTimeReported'] != null 
          ? DateTime.parse(json['dateTimeReported']) 
          : null,
      dateTimeIncident: json['dateTimeIncident'] != null 
          ? DateTime.parse(json['dateTimeIncident']) 
          : null,
      placeOfIncident: json['placeOfIncident'],
      reportingPerson: ReportingPersonData.fromJson(json['reportingPerson'] ?? {}),
      suspect: SuspectData.fromJson(json['suspect'] ?? {}),
      victim: VictimData.fromJson(json['victim'] ?? {}),
      narrative: json['narrative'],
      nameOfReportingPerson: json['nameOfReportingPerson'],
      signatureOfReportingPerson: json['signatureOfReportingPerson'],
      nameOfAdministeringOfficer: json['nameOfAdministeringOfficer'],
      signatureOfAdministeringOfficer: json['signatureOfAdministeringOfficer'],
      rankNameOfPoliceOfficer: json['rankNameOfPoliceOfficer'],
      signatureOfPoliceOfficer: json['signatureOfPoliceOfficer'],
      rankNameOfDeskOfficer: json['rankNameOfDeskOfficer'],
      signatureOfDeskOfficer: json['signatureOfDeskOfficer'],
      blotterEntryNr: json['blotterEntryNr'],
      nameOfPoliceStation: json['nameOfPoliceStation'],
      telephonePoliceStation: json['telephonePoliceStation'],
      investigatorOnCase: json['investigatorOnCase'],
      mobilePhoneInvestigator: json['mobilePhoneInvestigator'],
      nameOfChief: json['nameOfChief'],
      mobilePhoneChief: json['mobilePhoneChief'],
    );
  }
}

class ReportingPersonData {
  final String? familyName;
  final String? firstName;
  final String? middleName;
  final String? qualifier;
  final String? nickname;
  final String? citizenship;
  final String? gender;
  final String? civilStatus;
  final DateTime? dateOfBirth;
  final int? age;
  final String? placeOfBirth;
  final String? homePhone;
  final String? mobilePhone;
  final String? currentAddress;
  final String? villageSitio;
  
  // Current address details
  final AddressRegion? region;
  final AddressProvince? province;
  final AddressMunicipality? municipality;
  final String? barangay;
  
  // Other address
  final bool? hasOtherAddress;
  final String? otherAddress;
  final String? otherVillageSitio;
  final AddressRegion? otherRegion;
  final AddressProvince? otherProvince;
  final AddressMunicipality? otherMunicipality;
  final String? otherBarangay;
  
  final String? education;
  final String? occupation;
  final String? idCardPresented;
  final String? emailAddress;

  ReportingPersonData({
    this.familyName,
    this.firstName,
    this.middleName,
    this.qualifier,
    this.nickname,
    this.citizenship,
    this.gender,
    this.civilStatus,
    this.dateOfBirth,
    this.age,
    this.placeOfBirth,
    this.homePhone,
    this.mobilePhone,
    this.currentAddress,
    this.villageSitio,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.hasOtherAddress,
    this.otherAddress,
    this.otherVillageSitio,
    this.otherRegion,
    this.otherProvince,
    this.otherMunicipality,
    this.otherBarangay,
    this.education,
    this.occupation,
    this.idCardPresented,
    this.emailAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'gender': gender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region?.toMap(),
      'province': province?.toMap(),
      'municipality': municipality?.toMap(),
      'barangay': barangay,
      'hasOtherAddress': hasOtherAddress,
      'otherAddress': otherAddress,
      'otherVillageSitio': otherVillageSitio,
      'otherRegion': otherRegion?.toMap(),
      'otherProvince': otherProvince?.toMap(),
      'otherMunicipality': otherMunicipality?.toMap(),
      'otherBarangay': otherBarangay,
      'education': education,
      'occupation': occupation,
      'idCardPresented': idCardPresented,
      'emailAddress': emailAddress,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'familyName': familyName,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'gender': gender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region?.toJson(),
      'province': province?.toJson(),
      'municipality': municipality?.toJson(),
      'barangay': barangay,
      'hasOtherAddress': hasOtherAddress,
      'otherAddress': otherAddress,
      'otherVillageSitio': otherVillageSitio,
      'otherRegion': otherRegion?.toJson(),
      'otherProvince': otherProvince?.toJson(),
      'otherMunicipality': otherMunicipality?.toJson(),
      'otherBarangay': otherBarangay,
      'education': education,
      'occupation': occupation,
      'idCardPresented': idCardPresented,
      'emailAddress': emailAddress,
    };
  }

  factory ReportingPersonData.fromMap(Map<String, dynamic> map) {
    return ReportingPersonData(
      familyName: map['familyName'],
      firstName: map['firstName'],
      middleName: map['middleName'],
      qualifier: map['qualifier'],
      nickname: map['nickname'],
      citizenship: map['citizenship'],
      gender: map['gender'],
      civilStatus: map['civilStatus'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? (map['dateOfBirth'] as Timestamp).toDate() 
          : null,
      age: map['age'],
      placeOfBirth: map['placeOfBirth'],
      homePhone: map['homePhone'],
      mobilePhone: map['mobilePhone'],
      currentAddress: map['currentAddress'],
      villageSitio: map['villageSitio'],
      region: map['region'] != null ? AddressRegion.fromMap(map['region']) : null,
      province: map['province'] != null ? AddressProvince.fromMap(map['province']) : null,
      municipality: map['municipality'] != null ? AddressMunicipality.fromMap(map['municipality']) : null,
      barangay: map['barangay'],
      hasOtherAddress: map['hasOtherAddress'],
      otherAddress: map['otherAddress'],
      otherVillageSitio: map['otherVillageSitio'],
      otherRegion: map['otherRegion'] != null ? AddressRegion.fromMap(map['otherRegion']) : null,
      otherProvince: map['otherProvince'] != null ? AddressProvince.fromMap(map['otherProvince']) : null,
      otherMunicipality: map['otherMunicipality'] != null ? AddressMunicipality.fromMap(map['otherMunicipality']) : null,
      otherBarangay: map['otherBarangay'],
      education: map['education'],
      occupation: map['occupation'],
      idCardPresented: map['idCardPresented'],
      emailAddress: map['emailAddress'],
    );
  }

  factory ReportingPersonData.fromJson(Map<String, dynamic> json) {
    return ReportingPersonData(
      familyName: json['familyName'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      qualifier: json['qualifier'],
      nickname: json['nickname'],
      citizenship: json['citizenship'],
      gender: json['gender'],
      civilStatus: json['civilStatus'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      age: json['age'],
      placeOfBirth: json['placeOfBirth'],
      homePhone: json['homePhone'],
      mobilePhone: json['mobilePhone'],
      currentAddress: json['currentAddress'],
      villageSitio: json['villageSitio'],
      region: json['region'] != null ? AddressRegion.fromJson(json['region']) : null,
      province: json['province'] != null ? AddressProvince.fromJson(json['province']) : null,
      municipality: json['municipality'] != null ? AddressMunicipality.fromJson(json['municipality']) : null,
      barangay: json['barangay'],
      hasOtherAddress: json['hasOtherAddress'],
      otherAddress: json['otherAddress'],
      otherVillageSitio: json['otherVillageSitio'],
      otherRegion: json['otherRegion'] != null ? AddressRegion.fromJson(json['otherRegion']) : null,
      otherProvince: json['otherProvince'] != null ? AddressProvince.fromJson(json['otherProvince']) : null,
      otherMunicipality: json['otherMunicipality'] != null ? AddressMunicipality.fromJson(json['otherMunicipality']) : null,
      otherBarangay: json['otherBarangay'],
      education: json['education'],
      occupation: json['occupation'],
      idCardPresented: json['idCardPresented'],
      emailAddress: json['emailAddress'],
    );
  }
}

class SuspectData {
  final String? familyName;
  final String? firstName;
  final String? middleName;
  final String? qualifier;
  final String? nickname;
  final String? citizenship;
  final String? gender;
  final String? civilStatus;
  final DateTime? dateOfBirth;
  final int? age;
  final String? placeOfBirth;
  final String? homePhone;
  final String? mobilePhone;
  final String? currentAddress;
  final String? villageSitio;
  
  // Current address details
  final AddressRegion? region;
  final AddressProvince? province;
  final AddressMunicipality? municipality;
  final String? barangay;
  
  // Other address
  final bool? hasOtherAddress;
  final String? otherAddress;
  final String? otherVillageSitio;
  final AddressRegion? otherRegion;
  final AddressProvince? otherProvince;
  final AddressMunicipality? otherMunicipality;
  final String? otherBarangay;
  
  final String? education;
  final String? occupation;
  final String? workAddress;
  final String? relationToVictim;
  final String? emailAddress;
  
  // Criminal record
  final bool? hasPreviousCriminalRecord;
  final String? previousCriminalRecordDetails;
  final String? statusOfPreviousCase;
  
  // Physical description
  final String? height;
  final String? weight;
  final String? built;
  final String? colorOfEyes;
  final String? descriptionOfEyes;
  final String? colorOfHair;
  final String? descriptionOfHair;
  
  // Under influence
  final bool? noInfluence;
  final bool? drugsInfluence;
  final bool? liquorInfluence;
  final bool? othersInfluence;
  final String? othersInfluenceDetails;
  
  // Children in conflict with law
  final String? nameOfGuardian;
  final String? guardianAddress;
  final String? guardianHomePhone;
  final String? guardianMobilePhone;

  SuspectData({
    this.familyName,
    this.firstName,
    this.middleName,
    this.qualifier,
    this.nickname,
    this.citizenship,
    this.gender,
    this.civilStatus,
    this.dateOfBirth,
    this.age,
    this.placeOfBirth,
    this.homePhone,
    this.mobilePhone,
    this.currentAddress,
    this.villageSitio,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.hasOtherAddress,
    this.otherAddress,
    this.otherVillageSitio,
    this.otherRegion,
    this.otherProvince,
    this.otherMunicipality,
    this.otherBarangay,
    this.education,
    this.occupation,
    this.workAddress,
    this.relationToVictim,
    this.emailAddress,
    this.hasPreviousCriminalRecord,
    this.previousCriminalRecordDetails,
    this.statusOfPreviousCase,
    this.height,
    this.weight,
    this.built,
    this.colorOfEyes,
    this.descriptionOfEyes,
    this.colorOfHair,
    this.descriptionOfHair,
    this.noInfluence,
    this.drugsInfluence,
    this.liquorInfluence,
    this.othersInfluence,
    this.othersInfluenceDetails,
    this.nameOfGuardian,
    this.guardianAddress,
    this.guardianHomePhone,
    this.guardianMobilePhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'gender': gender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region?.toMap(),
      'province': province?.toMap(),
      'municipality': municipality?.toMap(),
      'barangay': barangay,
      'hasOtherAddress': hasOtherAddress,
      'otherAddress': otherAddress,
      'otherVillageSitio': otherVillageSitio,
      'otherRegion': otherRegion?.toMap(),
      'otherProvince': otherProvince?.toMap(),
      'otherMunicipality': otherMunicipality?.toMap(),
      'otherBarangay': otherBarangay,
      'education': education,
      'occupation': occupation,
      'workAddress': workAddress,
      'relationToVictim': relationToVictim,
      'emailAddress': emailAddress,
      'hasPreviousCriminalRecord': hasPreviousCriminalRecord,
      'previousCriminalRecordDetails': previousCriminalRecordDetails,
      'statusOfPreviousCase': statusOfPreviousCase,
      'height': height,
      'weight': weight,
      'built': built,
      'colorOfEyes': colorOfEyes,
      'descriptionOfEyes': descriptionOfEyes,
      'colorOfHair': colorOfHair,
      'descriptionOfHair': descriptionOfHair,
      'noInfluence': noInfluence,
      'drugsInfluence': drugsInfluence,
      'liquorInfluence': liquorInfluence,
      'othersInfluence': othersInfluence,
      'othersInfluenceDetails': othersInfluenceDetails,
      'nameOfGuardian': nameOfGuardian,
      'guardianAddress': guardianAddress,
      'guardianHomePhone': guardianHomePhone,
      'guardianMobilePhone': guardianMobilePhone,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'familyName': familyName,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'gender': gender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region?.toJson(),
      'province': province?.toJson(),
      'municipality': municipality?.toJson(),
      'barangay': barangay,
      'hasOtherAddress': hasOtherAddress,
      'otherAddress': otherAddress,
      'otherVillageSitio': otherVillageSitio,
      'otherRegion': otherRegion?.toJson(),
      'otherProvince': otherProvince?.toJson(),
      'otherMunicipality': otherMunicipality?.toJson(),
      'otherBarangay': otherBarangay,
      'education': education,
      'occupation': occupation,
      'workAddress': workAddress,
      'relationToVictim': relationToVictim,
      'emailAddress': emailAddress,
      'hasPreviousCriminalRecord': hasPreviousCriminalRecord,
      'previousCriminalRecordDetails': previousCriminalRecordDetails,
      'statusOfPreviousCase': statusOfPreviousCase,
      'height': height,
      'weight': weight,
      'built': built,
      'colorOfEyes': colorOfEyes,
      'descriptionOfEyes': descriptionOfEyes,
      'colorOfHair': colorOfHair,
      'descriptionOfHair': descriptionOfHair,
      'noInfluence': noInfluence,
      'drugsInfluence': drugsInfluence,
      'liquorInfluence': liquorInfluence,
      'othersInfluence': othersInfluence,
      'othersInfluenceDetails': othersInfluenceDetails,
      'nameOfGuardian': nameOfGuardian,
      'guardianAddress': guardianAddress,
      'guardianHomePhone': guardianHomePhone,
      'guardianMobilePhone': guardianMobilePhone,
    };
  }

  factory SuspectData.fromMap(Map<String, dynamic> map) {
    return SuspectData(
      familyName: map['familyName'],
      firstName: map['firstName'],
      middleName: map['middleName'],
      qualifier: map['qualifier'],
      nickname: map['nickname'],
      citizenship: map['citizenship'],
      gender: map['gender'],
      civilStatus: map['civilStatus'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? (map['dateOfBirth'] as Timestamp).toDate() 
          : null,
      age: map['age'],
      placeOfBirth: map['placeOfBirth'],
      homePhone: map['homePhone'],
      mobilePhone: map['mobilePhone'],
      currentAddress: map['currentAddress'],
      villageSitio: map['villageSitio'],
      region: map['region'] != null ? AddressRegion.fromMap(map['region']) : null,
      province: map['province'] != null ? AddressProvince.fromMap(map['province']) : null,
      municipality: map['municipality'] != null ? AddressMunicipality.fromMap(map['municipality']) : null,
      barangay: map['barangay'],
      hasOtherAddress: map['hasOtherAddress'],
      otherAddress: map['otherAddress'],
      otherVillageSitio: map['otherVillageSitio'],
      otherRegion: map['otherRegion'] != null ? AddressRegion.fromMap(map['otherRegion']) : null,
      otherProvince: map['otherProvince'] != null ? AddressProvince.fromMap(map['otherProvince']) : null,
      otherMunicipality: map['otherMunicipality'] != null ? AddressMunicipality.fromMap(map['otherMunicipality']) : null,
      otherBarangay: map['otherBarangay'],
      education: map['education'],
      occupation: map['occupation'],
      workAddress: map['workAddress'],
      relationToVictim: map['relationToVictim'],
      emailAddress: map['emailAddress'],
      hasPreviousCriminalRecord: map['hasPreviousCriminalRecord'],
      previousCriminalRecordDetails: map['previousCriminalRecordDetails'],
      statusOfPreviousCase: map['statusOfPreviousCase'],
      height: map['height'],
      weight: map['weight'],
      built: map['built'],
      colorOfEyes: map['colorOfEyes'],
      descriptionOfEyes: map['descriptionOfEyes'],
      colorOfHair: map['colorOfHair'],
      descriptionOfHair: map['descriptionOfHair'],
      noInfluence: map['noInfluence'],
      drugsInfluence: map['drugsInfluence'],
      liquorInfluence: map['liquorInfluence'],
      othersInfluence: map['othersInfluence'],
      othersInfluenceDetails: map['othersInfluenceDetails'],
      nameOfGuardian: map['nameOfGuardian'],
      guardianAddress: map['guardianAddress'],
      guardianHomePhone: map['guardianHomePhone'],
      guardianMobilePhone: map['guardianMobilePhone'],
    );
  }

  factory SuspectData.fromJson(Map<String, dynamic> json) {
    return SuspectData(
      familyName: json['familyName'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      qualifier: json['qualifier'],
      nickname: json['nickname'],
      citizenship: json['citizenship'],
      gender: json['gender'],
      civilStatus: json['civilStatus'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      age: json['age'],
      placeOfBirth: json['placeOfBirth'],
      homePhone: json['homePhone'],
      mobilePhone: json['mobilePhone'],
      currentAddress: json['currentAddress'],
      villageSitio: json['villageSitio'],
      region: json['region'] != null ? AddressRegion.fromJson(json['region']) : null,
      province: json['province'] != null ? AddressProvince.fromJson(json['province']) : null,
      municipality: json['municipality'] != null ? AddressMunicipality.fromJson(json['municipality']) : null,
      barangay: json['barangay'],
      hasOtherAddress: json['hasOtherAddress'],
      otherAddress: json['otherAddress'],
      otherVillageSitio: json['otherVillageSitio'],
      otherRegion: json['otherRegion'] != null ? AddressRegion.fromJson(json['otherRegion']) : null,
      otherProvince: json['otherProvince'] != null ? AddressProvince.fromJson(json['otherProvince']) : null,
      otherMunicipality: json['otherMunicipality'] != null ? AddressMunicipality.fromJson(json['otherMunicipality']) : null,
      otherBarangay: json['otherBarangay'],
      education: json['education'],
      occupation: json['occupation'],
      workAddress: json['workAddress'],
      relationToVictim: json['relationToVictim'],
      emailAddress: json['emailAddress'],
      hasPreviousCriminalRecord: json['hasPreviousCriminalRecord'],
      previousCriminalRecordDetails: json['previousCriminalRecordDetails'],
      statusOfPreviousCase: json['statusOfPreviousCase'],
      height: json['height'],
      weight: json['weight'],
      built: json['built'],
      colorOfEyes: json['colorOfEyes'],
      descriptionOfEyes: json['descriptionOfEyes'],
      colorOfHair: json['colorOfHair'],
      descriptionOfHair: json['descriptionOfHair'],
      noInfluence: json['noInfluence'],
      drugsInfluence: json['drugsInfluence'],
      liquorInfluence: json['liquorInfluence'],
      othersInfluence: json['othersInfluence'],
      othersInfluenceDetails: json['othersInfluenceDetails'],
      nameOfGuardian: json['nameOfGuardian'],
      guardianAddress: json['guardianAddress'],
      guardianHomePhone: json['guardianHomePhone'],
      guardianMobilePhone: json['guardianMobilePhone'],
    );
  }
}

class VictimData {
  final String? familyName;
  final String? firstName;
  final String? middleName;
  final String? qualifier;
  final String? nickname;
  final String? citizenship;
  final String? gender;
  final String? civilStatus;
  final DateTime? dateOfBirth;
  final int? age;
  final String? placeOfBirth;
  final String? homePhone;
  final String? mobilePhone;
  final String? currentAddress;
  final String? villageSitio;
  
  // Current address details
  final AddressRegion? region;
  final AddressProvince? province;
  final AddressMunicipality? municipality;
  final String? barangay;
  
  // Other address
  final bool? hasOtherAddress;
  final String? otherAddress;
  final String? otherVillageSitio;
  final AddressRegion? otherRegion;
  final AddressProvince? otherProvince;
  final AddressMunicipality? otherMunicipality;
  final String? otherBarangay;
  
  final String? education;
  final String? occupation;
  final String? workAddress;
  final String? emailAddress;

  VictimData({
    this.familyName,
    this.firstName,
    this.middleName,
    this.qualifier,
    this.nickname,
    this.citizenship,
    this.gender,
    this.civilStatus,
    this.dateOfBirth,
    this.age,
    this.placeOfBirth,
    this.homePhone,
    this.mobilePhone,
    this.currentAddress,
    this.villageSitio,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.hasOtherAddress,
    this.otherAddress,
    this.otherVillageSitio,
    this.otherRegion,
    this.otherProvince,
    this.otherMunicipality,
    this.otherBarangay,
    this.education,
    this.occupation,
    this.workAddress,
    this.emailAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'gender': gender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region?.toMap(),
      'province': province?.toMap(),
      'municipality': municipality?.toMap(),
      'barangay': barangay,
      'hasOtherAddress': hasOtherAddress,
      'otherAddress': otherAddress,
      'otherVillageSitio': otherVillageSitio,
      'otherRegion': otherRegion?.toMap(),
      'otherProvince': otherProvince?.toMap(),
      'otherMunicipality': otherMunicipality?.toMap(),
      'otherBarangay': otherBarangay,
      'education': education,
      'occupation': occupation,
      'workAddress': workAddress,
      'emailAddress': emailAddress,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'familyName': familyName,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'gender': gender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region?.toJson(),
      'province': province?.toJson(),
      'municipality': municipality?.toJson(),
      'barangay': barangay,
      'hasOtherAddress': hasOtherAddress,
      'otherAddress': otherAddress,
      'otherVillageSitio': otherVillageSitio,
      'otherRegion': otherRegion?.toJson(),
      'otherProvince': otherProvince?.toJson(),
      'otherMunicipality': otherMunicipality?.toJson(),
      'otherBarangay': otherBarangay,
      'education': education,
      'occupation': occupation,
      'workAddress': workAddress,
      'emailAddress': emailAddress,
    };
  }

  factory VictimData.fromMap(Map<String, dynamic> map) {
    return VictimData(
      familyName: map['familyName'],
      firstName: map['firstName'],
      middleName: map['middleName'],
      qualifier: map['qualifier'],
      nickname: map['nickname'],
      citizenship: map['citizenship'],
      gender: map['gender'],
      civilStatus: map['civilStatus'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? (map['dateOfBirth'] as Timestamp).toDate() 
          : null,
      age: map['age'],
      placeOfBirth: map['placeOfBirth'],
      homePhone: map['homePhone'],
      mobilePhone: map['mobilePhone'],
      currentAddress: map['currentAddress'],
      villageSitio: map['villageSitio'],
      region: map['region'] != null ? AddressRegion.fromMap(map['region']) : null,
      province: map['province'] != null ? AddressProvince.fromMap(map['province']) : null,
      municipality: map['municipality'] != null ? AddressMunicipality.fromMap(map['municipality']) : null,
      barangay: map['barangay'],
      hasOtherAddress: map['hasOtherAddress'],
      otherAddress: map['otherAddress'],
      otherVillageSitio: map['otherVillageSitio'],
      otherRegion: map['otherRegion'] != null ? AddressRegion.fromMap(map['otherRegion']) : null,
      otherProvince: map['otherProvince'] != null ? AddressProvince.fromMap(map['otherProvince']) : null,
      otherMunicipality: map['otherMunicipality'] != null ? AddressMunicipality.fromMap(map['otherMunicipality']) : null,
      otherBarangay: map['otherBarangay'],
      education: map['education'],
      occupation: map['occupation'],
      workAddress: map['workAddress'],
      emailAddress: map['emailAddress'],
    );
  }

  factory VictimData.fromJson(Map<String, dynamic> json) {
    return VictimData(
      familyName: json['familyName'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      qualifier: json['qualifier'],
      nickname: json['nickname'],
      citizenship: json['citizenship'],
      gender: json['gender'],
      civilStatus: json['civilStatus'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      age: json['age'],
      placeOfBirth: json['placeOfBirth'],
      homePhone: json['homePhone'],
      mobilePhone: json['mobilePhone'],
      currentAddress: json['currentAddress'],
      villageSitio: json['villageSitio'],
      region: json['region'] != null ? AddressRegion.fromJson(json['region']) : null,
      province: json['province'] != null ? AddressProvince.fromJson(json['province']) : null,
      municipality: json['municipality'] != null ? AddressMunicipality.fromJson(json['municipality']) : null,
      barangay: json['barangay'],
      hasOtherAddress: json['hasOtherAddress'],
      otherAddress: json['otherAddress'],
      otherVillageSitio: json['otherVillageSitio'],
      otherRegion: json['otherRegion'] != null ? AddressRegion.fromJson(json['otherRegion']) : null,
      otherProvince: json['otherProvince'] != null ? AddressProvince.fromJson(json['otherProvince']) : null,
      otherMunicipality: json['otherMunicipality'] != null ? AddressMunicipality.fromJson(json['otherMunicipality']) : null,
      otherBarangay: json['otherBarangay'],
      education: json['education'],
      occupation: json['occupation'],
      workAddress: json['workAddress'],
      emailAddress: json['emailAddress'],
    );
  }
}

// Address helper classes
class AddressRegion {
  final String code;
  final String name;
  
  AddressRegion({required this.code, required this.name});
  
  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
  };

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
  };
  
  factory AddressRegion.fromMap(Map<String, dynamic> map) => AddressRegion(
    code: map['code'] ?? '',
    name: map['name'] ?? '',
  );

  factory AddressRegion.fromJson(Map<String, dynamic> json) => AddressRegion(
    code: json['code'] ?? '',
    name: json['name'] ?? '',
  );
}

class AddressProvince {
  final String code;
  final String name;
  final String regionCode;
  
  AddressProvince({required this.code, required this.name, required this.regionCode});
  
  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'regionCode': regionCode,
  };

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'regionCode': regionCode,
  };
  
  factory AddressProvince.fromMap(Map<String, dynamic> map) => AddressProvince(
    code: map['code'] ?? '',
    name: map['name'] ?? '',
    regionCode: map['regionCode'] ?? '',
  );

  factory AddressProvince.fromJson(Map<String, dynamic> json) => AddressProvince(
    code: json['code'] ?? '',
    name: json['name'] ?? '',
    regionCode: json['regionCode'] ?? '',
  );
}

class AddressMunicipality {
  final String code;
  final String name;
  final String provinceCode;
  
  AddressMunicipality({required this.code, required this.name, required this.provinceCode});
  
  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'provinceCode': provinceCode,
  };

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'provinceCode': provinceCode,
  };
  
  factory AddressMunicipality.fromMap(Map<String, dynamic> map) => AddressMunicipality(
    code: map['code'] ?? '',
    name: map['name'] ?? '',
    provinceCode: map['provinceCode'] ?? '',
  );

  factory AddressMunicipality.fromJson(Map<String, dynamic> json) => AddressMunicipality(
    code: json['code'] ?? '',
    name: json['name'] ?? '',
    provinceCode: json['provinceCode'] ?? '',
  );
}
