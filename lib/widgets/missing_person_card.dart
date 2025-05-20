import '../core/app_export.dart';

class MissingPersonCard extends StatefulWidget {
  final MissingPerson person;

  const MissingPersonCard({required this.person});

  @override
  _MissingPersonCardState createState() => _MissingPersonCardState();
}

class _MissingPersonCardState extends State<MissingPersonCard> {
  static const int _descMaxLength = 100; // Character limit for description
  bool _isExpanded = false;
  Widget _buildStatusLabel() {
    final status = widget.person.status.isNotEmpty ? widget.person.status : 'UNRESOLVED';
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Unresolved Case':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      case 'Pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case 'Resolved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 200,
      width: double.infinity,
      child: widget.person.imageUrl.isNotEmpty
          ? Image.network(
              widget.person.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Container(
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 32, color: Colors.grey[600]),
                      SizedBox(height: 8),
                      Text('Image not available',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              },
            )
          : Container(
              color: Colors.grey[300],
              child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
            ),
    );
  }

  Widget _buildDescription() {
    final String description = widget.person.descriptions;
    final bool isLongText = description.length > _descMaxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLongText && !_isExpanded
              ? '${description.substring(0, _descMaxLength)}...'
              : description,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        if (isLongText)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Read more',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.blue,
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.person.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              trailing: _buildStatusLabel(),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildImage(),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last seen at ${widget.person.placeLastSeen}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 8),
                _buildDescription(),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Missing since: ${widget.person.datetimeLastSeen}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.tips_and_updates),
                        label: Text('Report a Sighting'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubmitTipScreen(person: widget.person),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.visibility),
                        label: Text('View Details'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CaseDetailsScreen(person: widget.person),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
