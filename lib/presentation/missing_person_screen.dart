import '../core/app_export.dart';
import '../core/network/missing_person_service.dart';

class MissingPersonScreen extends StatefulWidget {
  @override
  _MissingPersonScreenState createState() => _MissingPersonScreenState();
}

class _MissingPersonScreenState extends State<MissingPersonScreen> {
  final MissingPersonService _missingPersonService = MissingPersonService();
  String searchQuery = '';
  String sortBy = 'Recent';
  DateTime? startDate;
  DateTime? endDate;

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
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
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
            setState(() {});
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
                    hintText: 'Search missing persons...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
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
              Expanded(
                child: StreamBuilder<List<MissingPerson>>(
                  stream: _missingPersonService.getMissingPersons(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('StreamBuilder error: ${snapshot.error}');
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }                    if (snapshot.hasData) {
                      final persons = snapshot.data!;
                      for (var person in persons) {
                        person.debugPrint();
                      }
                      
                      // Filter persons based on search query and date range
                      var filteredPersons = persons.where((person) {
                        final searchLower = searchQuery.toLowerCase();
                        bool matchesSearch = searchQuery.isEmpty ||
                            person.name.toLowerCase().contains(searchLower) ||
                            person.descriptions.toLowerCase().contains(searchLower);                        // Check date range filter
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
                        
                        return matchesSearch && matchesDateRange;
                      }).toList();                      // Sort persons based on selected sort option
                      // Default sorting is 'Recent' based on date reported (most recent first)
                      switch (sortBy) {
                        case 'Name (A-Z)':
                          filteredPersons.sort((a, b) => a.name.compareTo(b.name));
                          break;
                        case 'Age':
                          filteredPersons.sort((a, b) {
                            // Since age property doesn't exist, sort by name as fallback
                            return a.name.compareTo(b.name);
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

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPersons.length,
                        itemBuilder: (context, index) {
                          return MissingPersonCard(person: filteredPersons[index]);
                        },
                      );
                    }

                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        },
        icon: Icon(Icons.arrow_back),
        label: Text("Back"),
        backgroundColor: Color(0xFF0D47A1), // Match app bar color
        foregroundColor: Colors.white, // Make text and icon white
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Position on left side
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort options
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,                      children: [
                        _buildSortChip('Recent', setState),
                        _buildSortChip('Name (A-Z)', setState),
                        _buildSortChip('Age', setState),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Date range selection
                    Text(
                      'Missing Since',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                startDate == null
                                    ? 'Start Date'
                                    : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  endDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                endDate == null
                                    ? 'End Date'
                                    : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Clear date range button
                    if (startDate != null || endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              startDate = null;
                              endDate = null;
                            });
                          },
                          icon: Icon(Icons.clear, size: 16),
                          label: Text('Clear Date Range'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                  ],
                ),
              ),              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      // Apply the filters
                      // Note: The actual filter implementation would need to be
                      // added to the StreamBuilder in the main widget
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String label, StateSetter setState) {
    return ChoiceChip(
      label: Text(label),
      selected: sortBy == label,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            sortBy = label;
          });
        }
      },
    );
  }
}
