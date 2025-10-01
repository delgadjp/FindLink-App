import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

class ImageProcessor {
  
  /// Process image to optimize it for Google Vision API human detection
  static Future<Uint8List> processImageForDetection(dynamic imageData) async {
    try {
      Uint8List imageBytes;
      
      // Convert input to Uint8List
      if (kIsWeb) {
        if (imageData is Uint8List) {
          imageBytes = imageData;
        } else if (imageData is String) {
          if (imageData.startsWith('data:image')) {
            // Remove data URL prefix and decode
            final base64String = imageData.split(',')[1];
            imageBytes = Uint8List.fromList(Uri.parse('data:application/octet-stream;base64,$base64String').data!.contentAsBytes());
          } else {
            throw Exception('Unsupported string format for web image');
          }
        } else {
          throw Exception('Unsupported image data type for web');
        }
      } else {
        // Mobile platform
        if (imageData is File) {
          imageBytes = await imageData.readAsBytes();
        } else if (imageData is Uint8List) {
          imageBytes = imageData;
        } else if (imageData is String && imageData.isNotEmpty) {
          final File file = File(imageData);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
          } else {
            throw Exception('File does not exist at path: $imageData');
          }
        } else {
          throw Exception('Unsupported image data type for mobile');
        }
      }
      
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Apply image enhancements for better human detection
      img.Image processedImage = _enhanceImageForHumanDetection(image);
      
      // Encode back to JPEG with high quality
      final Uint8List processedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: 95)
      );
      
      print('Image processed successfully. Original size: ${imageBytes.length} bytes, Processed size: ${processedBytes.length} bytes');
      return processedBytes;
      
    } catch (e) {
      print('Error processing image: $e');
      // If processing fails, return original image data as bytes
      if (imageData is Uint8List) {
        return imageData;
      } else if (imageData is File) {
        return await imageData.readAsBytes();
      } else {
        rethrow;
      }
    }
  }
  
  /// Apply specific enhancements to improve human detection accuracy
  static img.Image _enhanceImageForHumanDetection(img.Image image) {
    img.Image enhanced = img.Image.from(image);
    
    // 1. Optimize resolution for Vision API (recommended: 640-1024px on longest side)
    enhanced = _optimizeResolution(enhanced);
    
    // 2. Enhance contrast and brightness for better face/human detection
    enhanced = _adjustContrastAndBrightness(enhanced);
    
    // 3. Apply subtle sharpening to improve edge detection
    enhanced = _applySharpeningFilter(enhanced);
    
    // 4. Reduce noise while preserving important details
    enhanced = _reduceNoise(enhanced);
    
    return enhanced;
  }
  
  /// Optimize image resolution for best Vision API performance
  static img.Image _optimizeResolution(img.Image image) {
    const int targetMaxDimension = 1024; // Google Vision API sweet spot
    const int targetMinDimension = 640;   // Minimum for good detection
    
    int width = image.width;
    int height = image.height;
    int maxDimension = width > height ? width : height;
    
    // If image is too large, scale it down
    if (maxDimension > targetMaxDimension) {
      double scaleFactor = targetMaxDimension / maxDimension;
      int newWidth = (width * scaleFactor).round();
      int newHeight = (height * scaleFactor).round();
      
      print('Scaling image from ${width}x${height} to ${newWidth}x${newHeight}');
      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic // High-quality scaling
      );
    }
    
    // If image is too small, scale it up slightly for better detection
    else if (maxDimension < targetMinDimension) {
      double scaleFactor = targetMinDimension / maxDimension;
      int newWidth = (width * scaleFactor).round();
      int newHeight = (height * scaleFactor).round();
      
      print('Upscaling image from ${width}x${height} to ${newWidth}x${newHeight}');
      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic
      );
    }
    
    return image; // Already optimal size
  }
  
  /// Enhance contrast and brightness for better human detection
  static img.Image _adjustContrastAndBrightness(img.Image image) {
    // Calculate image statistics to determine optimal adjustments
    int totalBrightness = 0;
    int pixelCount = image.width * image.height;
    
    // Sample brightness across the image
    for (int y = 0; y < image.height; y += 5) {
      for (int x = 0; x < image.width; x += 5) {
        img.Pixel pixel = image.getPixel(x, y);
        int brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        totalBrightness += brightness;
      }
    }
    
    double avgBrightness = totalBrightness / (pixelCount / 25); // Adjusted for sampling
    
    // Determine adjustment values based on image brightness
    double contrastAdjustment = 1.0;
    double brightnessAdjustment = 0.0;
    
    if (avgBrightness < 100) {
      // Dark image - increase brightness and contrast
      brightnessAdjustment = 20.0;
      contrastAdjustment = 1.2;
    } else if (avgBrightness > 180) {
      // Bright image - reduce brightness slightly, increase contrast
      brightnessAdjustment = -10.0;
      contrastAdjustment = 1.1;
    } else {
      // Normal image - slight contrast boost
      contrastAdjustment = 1.1;
    }
    
    print('Applying brightness: ${brightnessAdjustment.toStringAsFixed(1)}, contrast: ${contrastAdjustment.toStringAsFixed(2)}');
    
    // Apply adjustments
    img.Image adjusted = img.adjustColor(
      image,
      brightness: brightnessAdjustment,
      contrast: contrastAdjustment,
    );
    
    return adjusted;
  }
  
  /// Apply subtle sharpening to enhance edge detection
  static img.Image _applySharpeningFilter(img.Image image) {
    // Custom sharpening kernel optimized for human detection
    const List<num> sharpenKernel = [
      -0.1, -0.2, -0.1,
      -0.2,  2.2, -0.2,
      -0.1, -0.2, -0.1
    ];
    
    return img.convolution(image, filter: sharpenKernel, div: 1.0);
  }
  
  /// Reduce noise while preserving important facial features
  static img.Image _reduceNoise(img.Image image) {
    // Apply a very subtle Gaussian blur to reduce noise without losing detail
    // This helps reduce false positives from image artifacts
    return img.gaussianBlur(image, radius: 1);
  }
  
  /// Get optimal camera settings recommendations
  static Map<String, dynamic> getOptimalCameraSettings() {
    return {
      'recommendedResolution': '1024x768 or higher',
      'minLightingConditions': 'Well-lit environment preferred',
      'focusDistance': '1-3 meters from subject',
      'orientation': 'Portrait or landscape both acceptable',
      'backgroundTips': 'Avoid cluttered backgrounds when possible',
      'subjectSize': 'Person should occupy at least 25% of frame',
    };
  }
  
  /// Analyze image quality before processing
  static Map<String, dynamic> analyzeImageQuality(img.Image image) {
    int width = image.width;
    int height = image.height;
    int totalPixels = width * height;
    
    // Calculate brightness distribution
    List<int> brightnessLevels = List.filled(256, 0);
    for (int y = 0; y < height; y += 2) {
      for (int x = 0; x < width; x += 2) {
        img.Pixel pixel = image.getPixel(x, y);
        int brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        brightnessLevels[brightness]++;
      }
    }
    
    // Find brightness statistics
    int darkPixels = brightnessLevels.sublist(0, 50).reduce((a, b) => a + b);
    int brightPixels = brightnessLevels.sublist(200, 256).reduce((a, b) => a + b);
    int sampleSize = (totalPixels / 4).round(); // Due to sampling every 2nd pixel
    
    double darkPercentage = (darkPixels / sampleSize) * 100;
    double brightPercentage = (brightPixels / sampleSize) * 100;
    
    // Determine quality recommendations
    List<String> recommendations = [];
    String qualityRating = 'Good';
    
    if (width < 640 || height < 480) {
      recommendations.add('Image resolution is low. Consider taking a higher resolution photo.');
      qualityRating = 'Fair';
    }
    
    if (darkPercentage > 60) {
      recommendations.add('Image appears dark. Try taking photo in better lighting.');
      qualityRating = 'Poor';
    }
    
    if (brightPercentage > 40) {
      recommendations.add('Image appears overexposed. Avoid direct bright light.');
      qualityRating = darkPercentage > 60 ? 'Poor' : 'Fair';
    }
    
    return {
      'resolution': '${width}x${height}',
      'qualityRating': qualityRating,
      'darkPercentage': darkPercentage.toStringAsFixed(1),
      'brightPercentage': brightPercentage.toStringAsFixed(1),
      'recommendations': recommendations,
      'isOptimalSize': width >= 640 && height >= 480 && width <= 2048 && height <= 2048,
    };
  }
}