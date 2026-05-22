import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class SharedWidgetData {
  const SharedWidgetData({
    required this.text,
    required this.encodedImage,
    required this.timestamp,
    required this.senderId,
    required this.recipientId,
  });

  factory SharedWidgetData.fromMap(Map<String, dynamic> data) {
    return SharedWidgetData(
      text: _stringFrom(data['text'])?.trim(),
      encodedImage: _stringFrom(data['image'])?.trim(),
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : null,
      senderId: _stringFrom(data['senderId']),
      recipientId: _stringFrom(data['recipientId']),
    );
  }

  final String? text;
  final String? encodedImage;
  final Timestamp? timestamp;
  final String? senderId;
  final String? recipientId;

  bool get hasText => text != null && text!.isNotEmpty;

  bool get hasImage => encodedImage != null && encodedImage!.isNotEmpty;

  bool get hasContent => hasText || hasImage;

  String get contentType {
    if (hasText && hasImage) return 'mixed';
    if (hasText) return 'text';
    if (hasImage) return 'image';
    return 'empty';
  }

  DecodedWidgetImage decodeImage() {
    final String? image = encodedImage;
    if (image == null || image.isEmpty) {
      return const DecodedWidgetImage();
    }

    try {
      return DecodedWidgetImage(bytes: base64Decode(image));
    } catch (_) {
      return const DecodedWidgetImage(hasDecodeError: true);
    }
  }

  static String? _stringFrom(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}

class DecodedWidgetImage {
  const DecodedWidgetImage({this.bytes, this.hasDecodeError = false});

  final Uint8List? bytes;
  final bool hasDecodeError;
}
