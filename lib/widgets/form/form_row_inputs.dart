import '/core/app_export.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';

class FormRowInputs extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> formState;
  final Function(String, dynamic) onFieldChange;

  const FormRowInputs({
    Key? key,
    required this.fields,
    required this.formState,
    required this.onFieldChange,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: fields.map((field) {
        final fieldKey = field['key'] as Key?; // Extract the key

        // Handle specialized address fields
        if (field['section'] != null && field['label'] == 'REGION') {
          return _buildRegionField(field, fieldKey);
        } else if (field['section'] != null && field['label'] == 'PROVINCE') {
          return _buildProvinceField(field, fieldKey);
        } else if (field['section'] != null && field['label'] == 'TOWN/CITY') {
          return _buildMunicipalityField(field, fieldKey);
        } else if (field['section'] != null && field['label'] == 'BARANGAY') {
          return _buildBarangayField(field, fieldKey);
        }
        
        // Handle specialized education and occupation fields
        else if (field['label'] == 'HIGHEST EDUCATION ATTAINMENT') {
          return _buildEducationField(field, fieldKey);
        } else if (field['label'] == 'OCCUPATION') {
          return _buildOccupationField(field, fieldKey);
        } else if (field['label'] == 'CITIZENSHIP') {
          return _buildCitizenshipField(field, fieldKey);
        } else if (field['label'] == 'CIVIL STATUS') {
          return _buildCivilStatusField(field, fieldKey);
        }
        // Handle date dropdown fields for date of birth
        else if (field['label'] == 'DATE OF BIRTH' && field['isDateDropdown'] == true) {
          return _buildDateDropdownField(field, fieldKey);
        }
        // Handle incident date+time field
        else if (field['label'] == 'DATE/TIME OF INCIDENT' && field['isIncidentDateTime'] == true) {
          return _buildIncidentDateTimeField(field, fieldKey);
        }        // Handle standard fields
        return CustomInputField(
          key: fieldKey, // Pass the extracted key to the CustomInputField
          label: field['label'] ?? '',
          isRequired: field['required'] ?? false,
          keyboardType: field['keyboardType'],
          inputFormatters: field['inputFormatters'],
          validator: field['validator'],
          dropdownItems: field['dropdownItems'],
          controller: field['controller'],
          readOnly: field['readOnly'] ?? false,
          onTap: field['onTap'],
          onChanged: field['onChanged'],
          value: field['value'],
          hintText: field['hintText'],
        );
      }).toList(),
    );
  }  Widget _buildRegionField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final regionKey = section == 'reportingOther' ? 'reportingOtherRegion' : section == 'victimOther' ? 'victimOtherRegion' : '${section}Region';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineRegionDropdown(
              key: key, // Pass key to the dropdown
              value: formState[regionKey],
              onChanged: (Region? value) => onFieldChange(regionKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final provinceKey = section == 'reportingOther' ? 'reportingOtherProvince' : section == 'victimOther' ? 'victimOtherProvince' : '${section}Province';
    final regionKey = section == 'reportingOther' ? 'reportingOtherRegion' : section == 'victimOther' ? 'victimOtherRegion' : '${section}Region';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineProvinceDropdown(
              value: formState[provinceKey],
              provinces: (formState[regionKey] as Region?)?.provinces ?? [],
              onChanged: (Province? value) => onFieldChange(provinceKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMunicipalityField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final municipalityKey = section == 'reportingOther' ? 'reportingOtherMunicipality' : section == 'victimOther' ? 'victimOtherMunicipality' : '${section}Municipality';
    final provinceKey = section == 'reportingOther' ? 'reportingOtherProvince' : section == 'victimOther' ? 'victimOtherProvince' : '${section}Province';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineMunicipalityDropdown(
              value: formState[municipalityKey],
              municipalities: (formState[provinceKey] as Province?)?.municipalities ?? [],
              onChanged: (Municipality? value) => onFieldChange(municipalityKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarangayField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final barangayKey = section == 'reportingOther' ? 'reportingOtherBarangay' : section == 'victimOther' ? 'victimOtherBarangay' : '${section}Barangay';
    final municipalityKey = section == 'reportingOther' ? 'reportingOtherMunicipality' : section == 'victimOther' ? 'victimOtherMunicipality' : '${section}Municipality';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineBarangayDropdown(
              value: formState[barangayKey],
              barangays: (formState[municipalityKey] as Municipality?)?.barangays ?? [],
              onChanged: (String? value) => onFieldChange(barangayKey, value),
            ),
          ],
        ),
      ),
    );
  }Widget _buildEducationField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final educationKey = '${section}Education';
    final educationOptions = field['dropdownItems'] ?? [];
    
    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: educationOptions,
      controller: field['controller'],
      value: formState[educationKey],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select education level';
        }
        return null;
      },
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        onFieldChange(educationKey, value);
      },
    );
  }  Widget _buildOccupationField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final occupationKey = '${section}Occupation';
    final occupationOptions = field['dropdownItems'] ?? [];
    
    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: occupationOptions,
      controller: field['controller'],
      value: formState[occupationKey],
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        onFieldChange(occupationKey, value);
      },
    );
  }  Widget _buildCitizenshipField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final citizenshipKey = '${section}Citizenship';
    final citizenshipOptions = field['dropdownItems'] ?? [];

    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: citizenshipOptions,
      controller: field['controller'],
      value: formState[citizenshipKey],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select citizenship';
        }
        return null;
      },
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        onFieldChange(citizenshipKey, value);
      },
    );
  }  Widget _buildCivilStatusField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String?;
    String? civilStatusKey;
    if (section == 'reporting') {
      civilStatusKey = 'reportingPersonCivilStatus';
    } else if (section == 'victim') {
      civilStatusKey = 'victimCivilStatus';
    }
    final civilStatusOptions = field['dropdownItems'] ?? [];
    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: civilStatusOptions,
      controller: field['controller'],
      value: civilStatusKey != null ? formState[civilStatusKey] : null,
      validator: (value) {
        if ((field['required'] ?? false) && (value == null || value.isEmpty)) {
          return 'Please select civil status';
        }
        return null;
      },
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        if (civilStatusKey != null) {
          onFieldChange(civilStatusKey == 'reportingPersonCivilStatus' ? 'civilStatusReporting' : 'civilStatusVictim', value);
        }
      },
    );
  }

  Widget _buildDateDropdownField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String?;
    final isReporting = section == 'reporting';
    
    // Get the callback functions passed from the parent
    final List<int> Function() getDaysInMonth = field['getDaysInMonth'];
    final void Function() updateDateFromDropdowns = field['updateDateFromDropdowns'];
    final int? selectedDay = field['selectedDay'];
    final int? selectedMonth = field['selectedMonth'];
    final int? selectedYear = field['selectedYear'];
    final void Function(String, dynamic) onDateFieldChange = field['onDateFieldChange'];
    final BuildContext context = field['context']; // Get context from field
    
    // Format date display text
    String getDateDisplayText() {
      if (selectedMonth != null && selectedDay != null && selectedYear != null) {
        String month = selectedMonth.toString().padLeft(2, '0');
        String day = selectedDay.toString().padLeft(2, '0');
        return '$month/$day/$selectedYear';
      }
      return 'Select';
    }
    
    return Expanded(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 35,
              child: Row(
                children: [
                  Text(
                    '* ',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      field['label'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 35,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 188, 188, 188)),
                  borderRadius: BorderRadius.circular(5),
                  color: isReporting ? Colors.grey.shade100 : Colors.white,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: isReporting ? null : () => _showDatePicker(
                      context,
                      field, 
                      selectedDay, 
                      selectedMonth, 
                      selectedYear, 
                      onDateFieldChange, 
                      updateDateFromDropdowns, 
                      getDaysInMonth, 
                      isReporting
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              getDateDisplayText(),
                              style: TextStyle(
                                color: (selectedMonth != null && selectedDay != null && selectedYear != null) 
                                    ? (isReporting ? Colors.grey.shade700 : Colors.black)
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(
    BuildContext context,
    Map<String, dynamic> field,
    int? selectedDay,
    int? selectedMonth,
    int? selectedYear,
    void Function(String, dynamic) onDateFieldChange,
    void Function() updateDateFromDropdowns,
    List<int> Function() getDaysInMonth,
    bool isReporting,
  ) {
    // Track local state for the dialog
    int? localMonth = selectedMonth;
    int? localDay = selectedDay;
    int? localYear = selectedYear;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Container(
                width: 380,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Color(0xFF0D47A1),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Date selection row
                    Row(
                      children: [
                        // Month dropdown
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: localMonth,
                              decoration: InputDecoration(
                                labelText: 'Month',
                                labelStyle: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: List.generate(12, (index) {
                                int month = index + 1;
                                List<String> monthNames = [
                                  'January', 'February', 'March', 'April', 'May', 'June',
                                  'July', 'August', 'September', 'October', 'November', 'December'
                                ];
                                return DropdownMenuItem<int>(
                                  value: month,
                                  child: Text(
                                    monthNames[index],
                                    style: TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                );
                              }),
                              onChanged: (int? newValue) {
                                setState(() {
                                  localMonth = newValue;
                                  // Reset day if it's invalid for new month
                                  if (localDay != null && newValue != null) {
                                    int daysInNewMonth = DateTime(localYear ?? DateTime.now().year, newValue + 1, 0).day;
                                    if (localDay! > daysInNewMonth) {
                                      localDay = null;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        
                        // Day dropdown
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: localDay,
                              decoration: InputDecoration(
                                labelText: 'Day',
                                labelStyle: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: localMonth != null ? 
                                List.generate(DateTime(localYear ?? DateTime.now().year, localMonth! + 1, 0).day, (index) {
                                  int day = index + 1;
                                  return DropdownMenuItem<int>(
                                    value: day,
                                    child: Text(
                                      '$day',
                                      style: TextStyle(fontSize: 14, color: Colors.black),
                                    ),
                                  );
                                }) : [],
                              onChanged: (int? newValue) {
                                setState(() {
                                  localDay = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        
                        // Year dropdown
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: localYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                labelStyle: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: List.generate(100, (index) {
                                int year = DateTime.now().year - index;
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(
                                    '$year',
                                    style: TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                );
                              }),
                              onChanged: (int? newValue) {
                                setState(() {
                                  localYear = newValue;
                                  // Reset day if it's invalid for new year (leap year changes)
                                  if (localDay != null && localMonth != null && newValue != null) {
                                    int daysInNewYear = DateTime(newValue, localMonth! + 1, 0).day;
                                    if (localDay! > daysInNewYear) {
                                      localDay = null;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Selected date preview
                    if (localMonth != null && localDay != null && localYear != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF0D47A1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF0D47A1).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Date:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${localMonth.toString().padLeft(2, '0')}/${localDay.toString().padLeft(2, '0')}/$localYear',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (localMonth != null && localDay != null && localYear != null) ? () {
                            // Update the actual values
                            onDateFieldChange(isReporting ? 'selectedMonthReporting' : 'selectedMonthVictim', localMonth);
                            onDateFieldChange(isReporting ? 'selectedDayReporting' : 'selectedDayVictim', localDay);
                            onDateFieldChange(isReporting ? 'selectedYearReporting' : 'selectedYearVictim', localYear);
                            updateDateFromDropdowns();
                            Navigator.of(dialogContext).pop();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncidentDateTimeField(Map<String, dynamic> field, Key? key) {
    // Get the callback functions passed from the parent
    final void Function() onTap = field['onTap'];
    final String displayText = field['displayText'] ?? 'Select Date & Time';
    
    return Expanded(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 35,
              child: Row(
                children: [
                  Text(
                    '* ',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      field['label'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 35,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 188, 188, 188)),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: onTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            color: Color(0xFF0D47A1),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayText,
                              style: TextStyle(
                                color: displayText != 'Select Date & Time' 
                                    ? Colors.black87 
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
