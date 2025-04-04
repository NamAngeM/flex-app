import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/app_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Pour Android, utiliser GoogleSignIn avec les scopes nécessaires
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool _devMode = AppConfig().isDevMode(); // Utiliser AppConfig pour la cohérence

  // Constructeur pour configurer l'authentification persistante
  AuthService() {
    _auth.setPersistence(Persistence.LOCAL);
  }

  // Stream pour l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Vérifier si l'email est vérifié
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }
  
  // Renvoyer un email de vérification
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
  
  // Recharger l'utilisateur pour vérifier l'état de vérification de l'email
  Future<bool> reloadUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser;
      return user!.emailVerified;
    }
    return false;
  }

  // Inscription avec email/mot de passe
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      print('Tentative d\'inscription avec email: $email');
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Utilisateur créé avec succès: ${result.user?.uid}');
      
      if (result.user != null) {
        // Envoyer un email de vérification
        try {
          await result.user!.sendEmailVerification();
          print('Email de vérification envoyé');
        } catch (e) {
          print('Erreur lors de l\'envoi de l\'email de vérification: $e');
          // Continuer malgré l'erreur d'envoi d'email
        }
        
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          role: role,
        );

        print('Tentative d\'enregistrement des données utilisateur dans Firestore');
        try {
          await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .set(newUser.toMap());
          print('Données utilisateur enregistrées avec succès');
        } catch (e) {
          print('Erreur lors de l\'enregistrement des données utilisateur: $e');
          // Si l'enregistrement dans Firestore échoue, supprimer l'utilisateur Auth
          try {
            await result.user!.delete();
            print('Utilisateur supprimé après échec Firestore');
          } catch (deleteError) {
            print('Erreur lors de la suppression de l\'utilisateur: $deleteError');
          }
          throw Exception('Erreur lors de l\'enregistrement des données: $e');
        }

        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException lors de l\'inscription: ${e.code}');
      print('Message d\'erreur: ${e.message}');
      
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Cette adresse email est déjà utilisée par un autre compte.';
          break;
        case 'invalid-email':
          message = 'L\'adresse email n\'est pas valide.';
          break;
        case 'operation-not-allowed':
          message = 'L\'authentification par email/mot de passe n\'est pas activée.';
          break;
        case 'weak-password':
          message = 'Le mot de passe est trop faible.';
          break;
        default:
          message = 'Une erreur s\'est produite: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      print('Exception générale lors de l\'inscription: $e');
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion avec email/mot de passe
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      print('Tentative de connexion avec email: $email');
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Connexion réussie pour l\'utilisateur: ${result.user?.uid}');
      
      if (result.user != null) {
        print('Récupération des données utilisateur depuis Firestore');
        try {
          final doc = await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .get();
              
          if (doc.exists) {
            print('Document utilisateur trouvé dans Firestore');
            return UserModel.fromFirestore(doc);
          } else {
            print('Aucun document utilisateur trouvé dans Firestore');
            
            // En mode production, on pourrait créer un document utilisateur basique
            if (!_devMode) {
              print('Création d\'un document utilisateur basique en production');
              UserModel newUser = UserModel(
                uid: result.user!.uid,
                email: result.user!.email ?? email,
                fullName: result.user!.displayName ?? 'Utilisateur',
                phoneNumber: result.user!.phoneNumber ?? '',
                role: UserRole.client,
              );
              
              await _firestore
                  .collection('users')
                  .doc(result.user!.uid)
                  .set(newUser.toMap());
                  
              print('Document utilisateur créé avec succès');
              return newUser;
            }
          }
        } catch (e) {
          print('Erreur lors de la récupération des données utilisateur: $e');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException lors de la connexion: ${e.code}');
      print('Message d\'erreur: ${e.message}');
      
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cette adresse email.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'L\'adresse email n\'est pas valide.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé.';
          break;
        default:
          message = 'Une erreur s\'est produite: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Connexion avec Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Vérifier si l'utilisateur existe déjà
        final userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Créer un nouveau profil si l'utilisateur n'existe pas
          UserModel newUser = UserModel(
            uid: result.user!.uid,
            email: result.user!.email!,
            fullName: result.user!.displayName ?? '',
            photoUrl: result.user!.photoURL,
            role: UserRole.client,
            phoneNumber: result.user!.phoneNumber ?? '',
          );

          await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .set(newUser.toMap());

          return newUser;
        } else {
          return UserModel.fromFirestore(userDoc);
        }
      }
      return null;
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Obtenir l'utilisateur courant
  Future<UserModel?> getCurrentUser() async {
    print('Récupération de l\'utilisateur courant');
    
    // En mode développement, retourner un utilisateur de test
    if (_devMode) {
      print('Mode développement activé, retour d\'un utilisateur de test');
      
      // Vérifier d'abord si un utilisateur de test existe déjà dans Firestore
      try {
        final testUserDoc = await _firestore.collection('users').doc('test-user-id').get();
        if (testUserDoc.exists) {
          print('Utilisateur de test trouvé dans Firestore');
          return UserModel.fromFirestore(testUserDoc);
        }
      } catch (e) {
        print('Erreur lors de la recherche de l\'utilisateur de test: $e');
      }
      
      // Créer un utilisateur de test s'il n'existe pas
      UserModel testUser = UserModel(
        uid: 'test-user-id',
        email: 'test@example.com',
        fullName: 'Utilisateur Test',
        phoneNumber: '+33123456789',
        role: UserRole.client,
      );
      
      return testUser;
    }
    
    // En production, récupérer l'utilisateur réel
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
      } catch (e) {
        print('Erreur lors de la récupération des données utilisateur: $e');
      }
    }
    
    return null;
  }
  
  // Obtenir l'ID de l'utilisateur courant
  Future<String?> getCurrentUserId() async {
    User? user = _auth.currentUser;
    return user?.uid;
  }
}