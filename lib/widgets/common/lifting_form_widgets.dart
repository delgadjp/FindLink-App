import 'package:flutter/material.dart';

/// Utility class for common lifting form UI widgets
/// Consolidates duplicate widgets used across profile and lifting form screens
class LiftingFormWidgets {
  
  /// Builds an image widget for lifting forms with consistent error handling
  static Widget buildFormImage(
    Map<String, dynamic> form, {
    double iconSize = 50,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final imageUrl = form['imageUrl'];
    final bgColor = backgroundColor ?? Color(0xFFfafafa);
    final icColor = iconColor ?? Colors.grey.shade400;

    if (imageUrl != null && imageUrl.toString().trim().isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => 
            _buildPlaceholderImage(iconSize, bgColor, icColor),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: bgColor,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2c2c78)
                ),
              ),
            ),
          );
        },
      );
    } else {
      return _buildPlaceholderImage(iconSize, bgColor, icColor);
    }
  }

  /// Builds a placeholder image when no image is available
  static Widget _buildPlaceholderImage(
    double iconSize, 
    Color backgroundColor, 
    Color iconColor,
  ) {
    return Container(
      color: backgroundColor,
      child: Icon(
        Icons.person,
        size: iconSize,
        color: iconColor,
      ),
    );
  }

  /// Builds an empty state widget for when no lifting forms are available
  static Widget buildEmptyState({
    bool isEnhanced = false,
    String? title,
    String? subtitle,
    String? description,
  }) {
    return Container(
      padding: EdgeInsets.all(isEnhanced ? 40 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isEnhanced ? 32 : 20),
            decoration: BoxDecoration(
              gradient: isEnhanced 
                ? LinearGradient(
                    colors: [Color(0xFFf8fafc), Color(0xFFe3e8ff)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              color: isEnhanced ? null : Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: isEnhanced ? [
                BoxShadow(
                  color: Color(0xFF2c2c78).withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ] : null,
            ),
            child: Icon(
              Icons.flash_off,
              size: isEnhanced ? 80 : 64,
              color: isEnhanced 
                ? Color(0xFF2c2c78).withOpacity(0.6)
                : Colors.grey.shade400,
            ),
          ),
          SizedBox(height: isEnhanced ? 32 : 24),
          Text(
            title ?? 'No Flash Alarm Requests',
            style: TextStyle(
              fontSize: isEnhanced ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: isEnhanced ? Color(0xFF2c2c78) : Colors.grey.shade700,
              letterSpacing: isEnhanced ? 0.5 : 0,
            ),
          ),
          SizedBox(height: 16),
          Text(
            subtitle ?? (isEnhanced 
              ? 'No lifting forms submitted by you.'
              : 'You don\'t have any lifting form notifications at the moment.'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (isEnhanced) SizedBox(height: 12),
          Text(
            description ?? 'New requests will appear here when received.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds a detail card for lifting form information
  static Widget buildDetailCard(
    String label, 
    String value, 
    IconData icon, {
    Color? primaryColor,
  }) {
    final color = primaryColor ?? Color(0xFF2c2c78);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFf8fafc), Color(0xFFe3e8ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe3e8ff), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.only(left: 42),
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: 15,
                color: value.isNotEmpty
                    ? Colors.grey.shade700
                    : Colors.grey.shade500,
                fontStyle:
                    value.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a pagination control widget
  static Widget buildPaginationControls({
    required int currentPage,
    required int totalPages,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
    Color? primaryColor,
  }) {
    final color = primaryColor ?? Color(0xFF2c2c78);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: currentPage > 1 ? onPrevious : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Prev'),
          ),
          SizedBox(width: 20),
          Text(
            'Page $currentPage of $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 20),
          ElevatedButton(
            onPressed: currentPage < totalPages ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Next'),
          ),
        ],
      ),
    );
  }
}