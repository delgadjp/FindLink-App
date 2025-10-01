import '/core/app_export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MissingPersonScreen extends StatefulWidget {
  @override
  _MissingPersonScreenState createState() => _MissingPersonScreenState();
}

class _MissingPersonScreenState extends State<MissingPersonScreen> {
  String searchQuery = '';
  String sortBy = 'Recent';
  DateTime? startDate;
  DateTime? endDate;
  String statusFilter = 'All';
  String locationFilter = '';
  bool showAdvancedFilters = false;
  
  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _missingPersonsSubscription;
  List<MissingPerson> _allMissingPersons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMissingPersonsStream();
  }

  @override
  void dispose() {
    _missingPersonsSubscription?.cancel();
    super.dispose();
  }

  // Initialize the stream for real-time updates
  void _initializeMissingPersonsStream() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stream = FirebaseFirestore.instance
          .collection('missingPersons')
          .snapshots();
      
      _missingPersonsSubscription = stream.listen(
        (QuerySnapshot snapshot) {
          final persons = snapshot.docs
              .map((doc) => MissingPerson.fromSnapshot(doc))
              .toList();
          
          setState(() {
            _allMissingPersons = persons;
            _isLoading = false;
            _errorMessage = null;
          });
        },
        onError: (error) {
          print('Error listening to missing persons stream: $error');
          setState(() {
            _isLoading = false;
            _errorMessage = error.toString();
          });
        },
      );
    } catch (e) {
      print('Error setting up missing persons stream: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Missing Persons",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF0D47A1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
        actions: [
          // Filter indicator badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog(context);
                },
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100],
            stops: [0.0, 50],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Reinitialize the stream to force a refresh
            _initializeMissingPersonsStream();
            // Wait a bit for the stream to fetch new data
            await Future.delayed(Duration(milliseconds: 500));
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Color(0xFF0D47A1),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, case ID, or description...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              
              // Active filters indicator
              if (_hasActiveFilters())
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Color(0xFF0D47A1),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getActiveFiltersText(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            sortBy = 'Recent';
                            statusFilter = 'All';
                            locationFilter = '';
                            startDate = null;
                            endDate = null;
                            showAdvancedFilters = false;
                          });
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _buildMissingPersonsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the missing persons list with filtering, sorting and real-time updates
  Widget _buildMissingPersonsList() {
    // Handle loading state
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (_errorMessage != null) {
      print('Error displaying missing persons: $_errorMessage');
      // Check if it's a permission error and show appropriate message
      if (_errorMessage!.contains('permission-denied')) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Database Access Issue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'There is a problem with the database rules.\nThe admin check is failing because user documents use custom IDs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry by reinitializing the stream
                  _initializeMissingPersonsStream();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _initializeMissingPersonsStream();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Handle empty state
    if (_allMissingPersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No missing persons found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'There are currently no missing person cases.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Debug print (can be removed in production)
    for (var person in _allMissingPersons) {
      person.debugPrint();
    }
    
    // Filter persons based on search query, status, location, and date range
    var filteredPersons = _allMissingPersons.where((person) {
      final searchLower = searchQuery.toLowerCase();
      bool matchesSearch = searchQuery.isEmpty ||
          person.name.toLowerCase().contains(searchLower) ||
          person.descriptions.toLowerCase().contains(searchLower) ||
          person.caseId.toLowerCase().contains(searchLower);

      // Status filter
      bool matchesStatus = statusFilter == 'All' ||
          person.status.toLowerCase().contains(statusFilter.toLowerCase());

      // Location filter
      bool matchesLocation = locationFilter.isEmpty ||
          person.address.toLowerCase().contains(locationFilter.toLowerCase()) ||
          person.placeLastSeen.toLowerCase().contains(locationFilter.toLowerCase());

      // Check date range filter
      bool matchesDateRange = true;
      if (startDate != null || endDate != null) {
        DateTime? personDate;
        try {
          personDate = DateTime.parse(person.datetimeReported.toString());
        } catch (e) {
          personDate = null;
        }
        
        if (personDate != null) {
          if (startDate != null && personDate.isBefore(startDate!)) {
            matchesDateRange = false;
          }
          if (endDate != null && personDate.isAfter(endDate!.add(Duration(days: 1)))) {
            matchesDateRange = false;
          }
        }
      }
      
      return matchesSearch && matchesStatus && matchesLocation && matchesDateRange;
    }).toList();

    // Sort persons based on selected sort option
    switch (sortBy) {
      case 'Name (A-Z)':
        filteredPersons.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name (Z-A)':
        filteredPersons.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Status':
        filteredPersons.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'Location':
        filteredPersons.sort((a, b) => a.placeLastSeen.compareTo(b.placeLastSeen));
        break;
      case 'Date Last Seen':
        filteredPersons.sort((a, b) {
          DateTime? dateA = a.lastSeenDateTime;
          DateTime? dateB = b.lastSeenDateTime;
          
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          
          return dateB.compareTo(dateA);
        });
        break;
      case 'Recent':
      default:
        // Use the parsed DateTime fields for more accurate sorting
        filteredPersons.sort((a, b) {
          DateTime? dateA = a.reportedDateTime;
          DateTime? dateB = b.reportedDateTime;
          
          // If parsed DateTime is null, fallback to string parsing
          if (dateA == null) {
            try {
              dateA = DateTime.parse(a.datetimeReported.toString());
            } catch (e) {
              dateA = null;
            }
          }
          
          if (dateB == null) {
            try {
              dateB = DateTime.parse(b.datetimeReported.toString());
            } catch (e) {
              dateB = null;
            }
          }
          
          // Handle null cases - put null dates at the end
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          
          // Sort by most recent first (descending order)
          return dateB.compareTo(dateA);
        });
        break;
    }

    // Show filtered empty state if no results after filtering
    if (filteredPersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredPersons.length,
      itemBuilder: (context, index) {
        return MissingPersonCard(person: filteredPersons[index]);
      },
    );
  }

  bool _hasActiveFilters() {
    return sortBy != 'Recent' || 
           statusFilter != 'All' || 
           locationFilter.isNotEmpty || 
           startDate != null || 
           endDate != null;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (sortBy != 'Recent') count++;
    if (statusFilter != 'All') count++;
    if (locationFilter.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    return count;
  }

  String _getActiveFiltersText() {
    List<String> filters = [];
    if (sortBy != 'Recent') filters.add('Sort: $sortBy');
    if (statusFilter != 'All') filters.add('Status: $statusFilter');
    if (locationFilter.isNotEmpty) filters.add('Location: $locationFilter');
    if (startDate != null || endDate != null) {
      if (startDate != null && endDate != null) {
        filters.add('Date: ${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}');
      } else if (startDate != null) {
        filters.add('From: ${startDate!.day}/${startDate!.month}/${startDate!.year}');
      } else if (endDate != null) {
        filters.add('Until: ${endDate!.day}/${endDate!.month}/${endDate!.year}');
      }
    }
    return filters.join(' • ');
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: 400,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Filter & Sort',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            // Sort Section
                            _buildSectionHeader('Sort By', Icons.sort),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildSortChip('Recent', setState),
                                _buildSortChip('Name (A-Z)', setState),
                                _buildSortChip('Name (Z-A)', setState),
                                _buildSortChip('Status', setState),
                                _buildSortChip('Location', setState),
                                _buildSortChip('Date Last Seen', setState),
                              ],
                            ),
                            
                            SizedBox(height: 24),
                            
                            // Quick Filters Section
                            _buildSectionHeader('Quick Filters', Icons.filter_alt),
                            SizedBox(height: 12),
                            
                            // Status Filter
                            _buildFilterSubheader('Status'),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: statusFilter,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF0D47A1)),
                                  dropdownColor: Colors.white,
                                  items: [
                                    'All',
                                    'Reported',
                                    'Under Review',
                                    'Case Verified',
                                    'In Progress',
                                    'Evidence Submitted',
                                    'Unresolved Case',
                                    'Resolved Case',
                                    'Resolved',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Row(
                                        children: [
                                          _buildStatusIndicator(value),
                                          SizedBox(width: 8),
                                          Text(
                                            value,
                                            style: TextStyle(color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      statusFilter = newValue ?? 'All';
                                    });
                                  },
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Location Filter
                            _buildFilterSubheader('Location'),
                            SizedBox(height: 8),
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  locationFilter = value;
                                });
                              },
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Filter by location...',
                                prefixIcon: Icon(Icons.location_on, color: Color(0xFF0D47A1)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color(0xFF0D47A1), width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            
                            SizedBox(height: 24),
                            
                            // Advanced Filters Section
                            InkWell(
                              onTap: () {
                                setState(() {
                                  showAdvancedFilters = !showAdvancedFilters;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Color(0xFF0D47A1),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Date Range Filter',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    showAdvancedFilters 
                                        ? Icons.keyboard_arrow_up 
                                        : Icons.keyboard_arrow_down,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (showAdvancedFilters) ...[
                              SizedBox(height: 16),
                              
                              // Date Range Presets
                              Text(
                                'Quick Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildDatePresetChip('Last 7 days', setState),
                                  _buildDatePresetChip('Last 30 days', setState),
                                  _buildDatePresetChip('Last 90 days', setState),
                                  _buildDatePresetChip('This Year', setState),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Custom Date Range
                              Text(
                                'Custom Range',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDatePicker(
                                      'Start Date',
                                      startDate,
                                      (date) => setState(() => startDate = date),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDatePicker(
                                      'End Date',
                                      endDate,
                                      (date) => setState(() => endDate = date),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Clear date range button
                              if (startDate != null || endDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Center(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          startDate = null;
                                          endDate = null;
                                        });
                                      },
                                      icon: Icon(Icons.clear, size: 18),
                                      label: Text('Clear Date Range'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Action Buttons
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Reset all filters
                                setState(() {
                                  sortBy = 'Recent';
                                  statusFilter = 'All';
                                  locationFilter = '';
                                  startDate = null;
                                  endDate = null;
                                  showAdvancedFilters = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFF0D47A1)),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(color: Color(0xFF0D47A1)),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                this.setState(() {
                                  // Apply the filters by updating the main widget state
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Apply Filters',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSortChip(String label, StateSetter setState) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: sortBy == label,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            sortBy = label;
          });
        }
      },
      selectedColor: Color(0xFF0D47A1),
      labelStyle: TextStyle(
        color: sortBy == label ? Colors.white : Colors.grey[700],
      ),
      backgroundColor: Colors.grey[100],
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF0D47A1), size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSubheader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    if (status == 'All') {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
      );
    }

    Color color;
    switch (status) {
      case 'Reported':
        color = Colors.grey;
        break;
      case 'Under Review':
        color = Colors.blue;
        break;
      case 'Case Verified':
        color = Colors.purple;
        break;
      case 'In Progress':
        color = Colors.orange;
        break;
      case 'Evidence Submitted':
        color = Colors.teal;
        break;
      case 'Unresolved Case':
        color = Colors.red;
        break;
      case 'Resolved Case':
      case 'Resolved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDatePresetChip(String label, StateSetter setState) {
    return GestureDetector(
      onTap: () {
        setState(() {
          DateTime now = DateTime.now();
          switch (label) {
            case 'Last 7 days':
              startDate = now.subtract(Duration(days: 7));
              endDate = now;
              break;
            case 'Last 30 days':
              startDate = now.subtract(Duration(days: 30));
              endDate = now;
              break;
            case 'Last 90 days':
              startDate = now.subtract(Duration(days: 90));
              endDate = now;
              break;
            case 'This Year':
              startDate = DateTime(now.year, 1, 1);
              endDate = now;
              break;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Color(0xFF0D47A1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Color(0xFF0D47A1),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF0D47A1),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF0D47A1), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate == null
                    ? label
                    : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: TextStyle(
                  color: selectedDate == null ? Colors.grey[600] : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
