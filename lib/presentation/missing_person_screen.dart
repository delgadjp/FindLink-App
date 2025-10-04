import '/core/app_export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

enum ViewMode { card, list, grid }

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
  int _currentPage = 0;
  static const int _itemsPerPage = 8;
  ViewMode _viewMode = ViewMode.card;
  bool _isSearchExpanded = false;
  
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
            _currentPage = 0;
          });
        },
        onError: (error) {
          debugPrint('Error listening to missing persons stream: $error');
          setState(() {
            _isLoading = false;
            _errorMessage = error.toString();
          });
        },
      );
    } catch (e) {
  debugPrint('Error setting up missing persons stream: $e');
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
              // Top bar with view toggles and search
              Container(
                padding: EdgeInsets.all(16),
                color: Color(0xFF0D47A1),
                child: Row(
                  children: [
                    // Search toggle button
                    IconButton(
                      icon: Icon(
                        _isSearchExpanded ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = !_isSearchExpanded;
                          if (!_isSearchExpanded) {
                            searchQuery = '';
                            _currentPage = 0;
                          }
                        });
                      },
                      tooltip: 'Search',
                    ),
                    // Expandable search bar
                    if (_isSearchExpanded) ...[
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 40,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _currentPage = 0;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.white70, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          searchQuery = '';
                                          _currentPage = 0;
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white24,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            autofocus: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ] else
                      Spacer(),
                    // View mode toggle buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.view_agenda),
                            color: _viewMode == ViewMode.card ? Colors.white : Colors.white54,
                            onPressed: () {
                              setState(() {
                                _viewMode = ViewMode.card;
                              });
                            },
                            tooltip: 'Card View',
                          ),
                          IconButton(
                            icon: Icon(Icons.list),
                            color: _viewMode == ViewMode.list ? Colors.white : Colors.white54,
                            onPressed: () {
                              setState(() {
                                _viewMode = ViewMode.list;
                              });
                            },
                            tooltip: 'List View',
                          ),
                          IconButton(
                            icon: Icon(Icons.grid_view),
                            color: _viewMode == ViewMode.grid ? Colors.white : Colors.white54,
                            onPressed: () {
                              setState(() {
                                _viewMode = ViewMode.grid;
                              });
                            },
                            tooltip: 'Grid View',
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            _currentPage = 0;
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
  debugPrint('Error displaying missing persons: $_errorMessage');
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

    final totalItems = filteredPersons.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    int targetPage = _currentPage;
    if (totalPages == 0) {
      targetPage = 0;
    } else if (_currentPage > totalPages - 1) {
      targetPage = totalPages - 1;
    }

    if (targetPage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentPage = targetPage;
        });
      });
    }

    final startIndex = targetPage * _itemsPerPage;
    final displayedPersons = filteredPersons
        .skip(startIndex)
        .take(_itemsPerPage)
        .toList();

    final showPagination = totalPages > 1;
    Widget contentView;

    switch (_viewMode) {
      case ViewMode.list:
        contentView = _buildListView(displayedPersons, showPagination);
        break;
      case ViewMode.grid:
        contentView = _buildGridView(displayedPersons, showPagination);
        break;
      case ViewMode.card:
        contentView = _buildCardView(displayedPersons, showPagination);
        break;
    }

    if (!showPagination) {
      return contentView;
    }

    return Stack(
      children: [
        contentView,
        _buildPaginationControls(
          totalPages: totalPages,
          totalItems: totalItems,
        ),
      ],
    );
  }

  // Build card view (current implementation)
  Widget _buildCardView(List<MissingPerson> displayedPersons, bool showPagination) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, showPagination ? 120 : 16),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: displayedPersons.length,
      itemBuilder: (context, index) {
        return MissingPersonCard(person: displayedPersons[index]);
      },
    );
  }

  // Build list view (compact version)
  Widget _buildListView(List<MissingPerson> displayedPersons, bool showPagination) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, showPagination ? 120 : 16),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: displayedPersons.length,
      itemBuilder: (context, index) {
        return _buildListItem(displayedPersons[index]);
      },
    );
  }

  // Build grid view
  Widget _buildGridView(List<MissingPerson> displayedPersons, bool showPagination) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    
    // Adaptive grid based on screen width
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, showPagination ? 120 : 16),
      physics: AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayedPersons.length,
      itemBuilder: (context, index) {
        return _buildGridItem(displayedPersons[index]);
      },
    );
  }

  // Build compact list item
  Widget _buildListItem(MissingPerson person) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF0D47A1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: person.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      person.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person, color: Color(0xFF0D47A1), size: 32),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: Color(0xFF0D47A1), size: 32),
                  ),
          ),
          title: Text(
            person.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0D47A1),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      person.placeLastSeen,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    'Case ID: ${person.caseId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              _buildStatusChip(person.status),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CaseDetailsScreen(person: person),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build grid item
  Widget _buildGridItem(MissingPerson person) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CaseDetailsScreen(person: person),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF0D47A1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    _buildStatusChip(person.status),
                  ],
                ),
              ),
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF0D47A1).withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: person.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            person.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Icon(Icons.person, size: 40, color: Color(0xFF0D47A1)),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Icon(Icons.person, size: 40, color: Color(0xFF0D47A1)),
                          ),
                        ),
                ),
              ),
              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              person.placeLastSeen,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              person.datetimeLastSeen,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF0D47A1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility, size: 14, color: Color(0xFF0D47A1)),
                            SizedBox(width: 4),
                            Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build status chip
  Widget _buildStatusChip(String status) {
    final statusText = status.isNotEmpty ? status : 'UNRESOLVED';
    Color bgColor;
    Color textColor;
    IconData statusIcon;

    switch (statusText) {
      case 'Unresolved Case':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        statusIcon = Icons.warning_rounded;
        break;
      case 'Pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        statusIcon = Icons.pending_rounded;
        break;
      case 'Resolved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        statusIcon = Icons.help_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: textColor,
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
                                    this.setState(() {
                                      _currentPage = 0;
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
                                this.setState(() {
                                  _currentPage = 0;
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
                                      (date) {
                                        setState(() => startDate = date);
                                        this.setState(() {
                                          _currentPage = 0;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDatePicker(
                                      'End Date',
                                      endDate,
                                      (date) {
                                        setState(() => endDate = date);
                                        this.setState(() {
                                          _currentPage = 0;
                                        });
                                      },
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
                                        this.setState(() {
                                          _currentPage = 0;
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
                                this.setState(() {
                                  _currentPage = 0;
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
                                  _currentPage = 0;
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
          this.setState(() {
            _currentPage = 0;
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
        this.setState(() {
          _currentPage = 0;
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
  
  Widget _buildPaginationControls({required int totalPages, required int totalItems}) {
    const Color primaryColor = Color(0xFF0D47A1);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Material(
          color: primaryColor,
          elevation: 6,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaginationArrowButton(
                  icon: Icons.chevron_left,
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Page ${_currentPage + 1} of $totalPages',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '$totalItems case${totalItems == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                _buildPaginationArrowButton(
                  icon: Icons.chevron_right,
                  onPressed: (_currentPage + 1) < totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationArrowButton({required IconData icon, required VoidCallback? onPressed}) {
    final bool enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(enabled ? 0.22 : 0.1),
        disabledBackgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white54,
        padding: EdgeInsets.all(8),
        minimumSize: Size(40, 40),
        shape: CircleBorder(),
      ),
    );
  }
}
