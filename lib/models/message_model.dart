// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  document,
}

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool read;
  final String? fileName; // Pour les documents
  
  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.read,
    this.fileName,
  });
  
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    MessageType messageType;
    switch (data['type']) {
      case 'image':
        messageType = MessageType.image;
        break;
      case 'document':
        messageType = MessageType.document;
        break;
      default:
        messageType = MessageType.text;
    }
    
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: messageType,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      fileName: data['fileName'],
    );
  }
  
  Map<String, dynamic> toMap() {
    String typeString;
    switch (type) {
      case MessageType.image:
        typeString = 'image';
        break;
      case MessageType.document:
        typeString = 'document';
        break;
      default:
        typeString = 'text';
    }
    
    return {
      'senderId': senderId,
      'content': content,
      'type': typeString,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      if (fileName != null) 'fileName': fileName,
    };
  }
}