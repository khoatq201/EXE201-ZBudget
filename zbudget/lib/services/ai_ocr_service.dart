import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// AI-powered OCR service using multiple providers
class AIOCRService {
  // API Keys - Add your keys here
  static const String _googleVisionApiKey =
      'AIzaSyAeotuYPrTKZRabwU2p4wgAfYSPSGVVWJg';
  static const String _openaiApiKey = 'sk-your-openai-key-here';
  static const String _azureEndpoint =
      'https://your-resource.cognitiveservices.azure.com';
  static const String _azureApiKey = 'your-azure-key-here';

  /// Extract text using Google Cloud Vision API
  static Future<AIOCRResult> extractWithGoogleVision(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
          'https://vision.googleapis.com/v1/images:annotate?key=${_googleVisionApiKey}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION', 'maxResults': 1},
              ],
              'imageContext': {
                'languageHints': ['vi', 'en'], // Vietnamese and English
              },
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textAnnotations = data['responses'][0]['textAnnotations'] ?? [];

        if (textAnnotations.isNotEmpty) {
          final fullText = textAnnotations[0]['description'] ?? '';
          final confidence = _calculateGoogleVisionConfidence(textAnnotations);

          return AIOCRResult(
            text: fullText,
            confidence: confidence,
            provider: 'Google Vision',
            blocks: _parseGoogleVisionBlocks(textAnnotations),
          );
        }
      }

      throw Exception('Google Vision API failed: ${response.statusCode}');
    } catch (e) {
      throw AIOCRException('Google Vision failed: $e');
    }
  }

  /// Extract text using OpenAI GPT-4 Vision
  static Future<AIOCRResult> extractWithOpenAI(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Analyze this Vietnamese receipt image and extract:
1. Store name
2. Total amount (in VND)
3. Date
4. Items purchased
5. Any other relevant information

Return the information in a structured format. Focus on Vietnamese text and currency (VND).''',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] ?? '';

        return AIOCRResult(
          text: content,
          confidence: 0.9, // GPT-4 Vision is very reliable
          provider: 'OpenAI GPT-4 Vision',
          blocks: [],
        );
      }

      throw Exception('OpenAI API failed: ${response.statusCode}');
    } catch (e) {
      throw AIOCRException('OpenAI failed: $e');
    }
  }

  /// Extract text using Azure Computer Vision
  static Future<AIOCRResult> extractWithAzure(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      final response = await http.post(
        Uri.parse('$_azureEndpoint/vision/v3.2/read/analyze'),
        headers: {
          'Ocp-Apim-Subscription-Key': _azureApiKey,
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 202) {
        // Azure returns a URL to check the result
        final operationLocation = response.headers['Operation-Location'];
        if (operationLocation != null) {
          return await _pollAzureResult(operationLocation);
        }
      }

      throw Exception('Azure API failed: ${response.statusCode}');
    } catch (e) {
      throw AIOCRException('Azure failed: $e');
    }
  }

  /// Smart OCR - Try Google Vision first, then fallback to others
  static Future<AIOCRResult> smartExtract(String imagePath) async {
    // Try Google Vision first (best for Vietnamese)
    try {
      final googleResult = await extractWithGoogleVision(imagePath);
      if (googleResult.text.isNotEmpty && googleResult.confidence > 0.5) {
        return googleResult;
      }
    } catch (e) {
      print('Google Vision failed: $e');
    }

    // Try OpenAI as backup
    try {
      final openaiResult = await extractWithOpenAI(imagePath);
      if (openaiResult.text.isNotEmpty && openaiResult.confidence > 0.5) {
        return openaiResult;
      }
    } catch (e) {
      print('OpenAI failed: $e');
    }

    // Try Azure as last resort
    try {
      final azureResult = await extractWithAzure(imagePath);
      if (azureResult.text.isNotEmpty && azureResult.confidence > 0.5) {
        return azureResult;
      }
    } catch (e) {
      print('Azure failed: $e');
    }

    throw AIOCRException(
      'All AI OCR providers failed. Please check your API keys and internet connection.',
    );
  }

  /// Calculate confidence from Google Vision response
  static double _calculateGoogleVisionConfidence(
    List<dynamic> textAnnotations,
  ) {
    if (textAnnotations.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int count = 0;

    for (final annotation in textAnnotations) {
      if (annotation['score'] != null) {
        totalConfidence += annotation['score'].toDouble();
        count++;
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  /// Parse Google Vision text blocks
  static List<AIOCRBlock> _parseGoogleVisionBlocks(
    List<dynamic> textAnnotations,
  ) {
    final blocks = <AIOCRBlock>[];

    for (int i = 1; i < textAnnotations.length; i++) {
      final annotation = textAnnotations[i];
      final description = annotation['description'] ?? '';
      final boundingPoly = annotation['boundingPoly'];

      if (boundingPoly != null && description.isNotEmpty) {
        blocks.add(
          AIOCRBlock(
            text: description,
            confidence: annotation['score']?.toDouble() ?? 0.0,
            boundingBox: _parseBoundingBox(boundingPoly),
          ),
        );
      }
    }

    return blocks;
  }

  /// Parse bounding box from Google Vision response
  static Map<String, double> _parseBoundingBox(
    Map<String, dynamic> boundingPoly,
  ) {
    final vertices = boundingPoly['vertices'] as List<dynamic>?;
    if (vertices == null || vertices.isEmpty) {
      return {'x': 0, 'y': 0, 'width': 0, 'height': 0};
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final vertex in vertices) {
      final x = (vertex['x'] ?? 0).toDouble();
      final y = (vertex['y'] ?? 0).toDouble();
      minX = minX < x ? minX : x;
      minY = minY < y ? minY : y;
      maxX = maxX > x ? maxX : x;
      maxY = maxY > y ? maxY : y;
    }

    return {'x': minX, 'y': minY, 'width': maxX - minX, 'height': maxY - minY};
  }

  /// Poll Azure result
  static Future<AIOCRResult> _pollAzureResult(String operationLocation) async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(seconds: 2));

      final response = await http.get(
        Uri.parse(operationLocation),
        headers: {'Ocp-Apim-Subscription-Key': _azureApiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'succeeded') {
          final readResults = data['analyzeResult']['readResults'] ?? [];
          final text = readResults
              .map((r) => r['lines']?.map((l) => l['text']).join(' ') ?? '')
              .join('\n');

          return AIOCRResult(
            text: text,
            confidence: 0.8,
            provider: 'Azure Computer Vision',
            blocks: [],
          );
        }
      }
    }

    throw AIOCRException('Azure polling timeout');
  }
}

/// AI OCR Result
class AIOCRResult {
  final String text;
  final double confidence;
  final String provider;
  final List<AIOCRBlock> blocks;

  AIOCRResult({
    required this.text,
    required this.confidence,
    required this.provider,
    required this.blocks,
  });

  bool get isHighConfidence => confidence > 0.8;
  bool get isMediumConfidence => confidence > 0.5;
  bool get isLowConfidence => confidence <= 0.5;
}

/// AI OCR Block
class AIOCRBlock {
  final String text;
  final double confidence;
  final Map<String, double> boundingBox;

  AIOCRBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

/// AI OCR Exception
class AIOCRException implements Exception {
  final String message;
  AIOCRException(this.message);

  @override
  String toString() => 'AIOCRException: $message';
}
