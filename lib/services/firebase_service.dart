import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Функция для отправки виджета
  Future<void> sendWidget({
    required String senderId,
    required String recipientId,
    String? text,
    Uint8List? imageBytes, // Сюда прилетит рисунок или фото
  }) async {
    String? base64Image;

    // Если есть картинка, превращаем её в текст (Base64)
    if (imageBytes != null) {
      base64Image = base64Encode(imageBytes);
    }

    await _db.collection('widgets').add({
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'image': base64Image, // Сохраняем как строку!
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Стрим для получения последнего виджета (для главного экрана)
  Stream<QuerySnapshot> getLatestWidget(String myId) {
    return _db
        .collection('widgets')
        .where('recipientId', isEqualTo: myId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }
}