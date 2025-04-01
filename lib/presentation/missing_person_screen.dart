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
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
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
                    }

                    if (snapshot.hasData) {
                      final persons = snapshot.data!;
                      for (var person in persons) {
                        person.debugPrint();
                      }
                      final filteredPersons = persons.where((person) {
                        final searchLower = searchQuery.toLowerCase();
                        return searchQuery.isEmpty ||
                            person.name.toLowerCase().contains(searchLower) ||
                            person.descriptions.toLowerCase().contains(searchLower);
                      }).toList();

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
          Navigator.of(context).pop(); // Go back to home screen
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
                      spacing: 8,
                      children: [
                        _buildSortChip('Recent', setState),
                        _buildSortChip('Name (A-Z)', setState),
                        _buildSortChip('Age', setState),
                        _buildSortChip('Location', setState),
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
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
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
