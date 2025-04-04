// lib/services/chat_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Créer une nouvelle conversation
  Future<String> createConversation(String otherUserId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');
    
    // Vérifier si une conversation existe déjà
    QuerySnapshot existingConvs = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .get();
    
    for (var doc in existingConvs.docs) {
      List<dynamic> participants = (doc.data() as Map<String, dynamic>)['participants'];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }
    
    // Créer une nouvelle conversation
    DocumentReference convRef = await _firestore.collection('conversations').add({
      'participants': [currentUser.uid, otherUserId],
      'lastMessage': null,
      'lastMessageTime': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return convRef.id;
  }
  
  // Envoyer un message texte
  Future<void> sendMessage(String conversationId, String content) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');
    
    // Récupérer les participants de la conversation
    DocumentSnapshot convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    List<dynamic> participants = (convDoc.data() as Map<String, dynamic>)['participants'];
    
    // Identifier le destinataire
    String recipientId = participants.firstWhere((id) => id != currentUser.uid);
    
    // Ajouter le message
    await _firestore.collection('conversations').doc(conversationId).collection('messages').add({
      'senderId': currentUser.uid,
      'content': content,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    
    // Mettre à jour les informations de la conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    // Envoyer une notification au destinataire
    await _notificationService.sendNotificationToUser(
      recipientId,
      'Nouveau message',
      content,
      data: {'type': 'chat', 'conversationId': conversationId},
    );
  }
  
  // Envoyer une image
  Future<void> sendImage(String conversationId, File imageFile) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');
    
    // Récupérer les participants de la conversation
    DocumentSnapshot convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    List<dynamic> participants = (convDoc.data() as Map<String, dynamic>)['participants'];
    
    // Identifier le destinataire
    String recipientId = participants.firstWhere((id) => id != currentUser.uid);
    
    // Uploader l'image
    String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = _storage.ref().child('chat_images/$conversationId/$fileName');
    
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    String imageUrl = await snapshot.ref.getDownloadURL();
    
    // Ajouter le message avec l'image
    await _firestore.collection('conversations').doc(conversationId).collection('messages').add({
      'senderId': currentUser.uid,
      'content': imageUrl,
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    
    // Mettre à jour les informations de la conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': '🖼️ Image',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    // Envoyer une notification au destinataire
    await _notificationService.sendNotificationToUser(
      recipientId,
      'Nouveau message',
      '🖼️ A partagé une image',
      data: {'type': 'chat', 'conversationId': conversationId},
    );
  }
  
  // Envoyer un document
  Future<void> sendDocument(String conversationId, File documentFile, String fileName) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');
    
    // Récupérer les participants de la conversation
    DocumentSnapshot convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    List<dynamic> participants = (convDoc.data() as Map<String, dynamic>)['participants'];
    
    // Identifier le destinataire
    String recipientId = participants.firstWhere((id) => id != currentUser.uid);
    
    // Uploader le document
    Reference storageRef = _storage.ref().child('chat_documents/$conversationId/$fileName');
    
    UploadTask uploadTask = storageRef.putFile(documentFile);
    TaskSnapshot snapshot = await uploadTask;
    String documentUrl = await snapshot.ref.getDownloadURL();
    
    // Ajouter le message avec le document
    await _firestore.collection('conversations').doc(conversationId).collection('messages').add({
      'senderId': currentUser.uid,
      'content': documentUrl,
      'fileName': fileName,
      'type': 'document',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    
    // Mettre à jour les informations de la conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': '📄 Document: $fileName',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    // Envoyer une notification au destinataire
    await _notificationService.sendNotificationToUser(
      recipientId,
      'Nouveau message',
      '📄 A partagé un document',
      data: {'type': 'chat', 'conversationId': conversationId},
    );
  }
  
  // Récupérer les conversations d'un utilisateur
  Stream<QuerySnapshot> getUserConversations() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');
    
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
  
  // Récupérer les messages d'une conversation
  Stream<QuerySnapshot> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');
    
    QuerySnapshot unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUser.uid)
        .get();
    
    WriteBatch batch = _firestore.batch();
    
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }
  
  // Compter les messages non lus
  Future<int> getUnreadMessageCount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return 0;
    
    int totalUnread = 0;
    
    QuerySnapshot conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .get();
    
    for (var convDoc in conversations.docs) {
      QuerySnapshot unreadMessages = await _firestore
          .collection('conversations')
          .doc(convDoc.id)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUser.uid)
          .get();
      
      totalUnread += unreadMessages.size;
    }
    
    return totalUnread;
  }
}