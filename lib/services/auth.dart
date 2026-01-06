import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AuthService {
  auth.FirebaseAuth get _firebaseAuth => auth.FirebaseAuth.instance;

  Future<UserData?> _userDataFromUser(auth.User? user) async {
    if (user == null) {
      return null;
    }
    
    UserData? userData = await CrudHelper().getUserDataByUid(user.uid);
    
    if (userData == null) {
      // New user - create with full data
      userData = UserData(
        uid: user.uid,
        email: user.email,
        verified: user.emailVerified,
        targetEmail: user.email,
        roles: {'staff': true}, // Default role
      );
      
      // Save to Firestore
      await CrudHelper().updateUserData(userData);
      return userData;
    }
    
    // Existing user - check if email fields are missing and fix them
    bool needsUpdate = false;
    
    if (userData.email == null || userData.email!.isEmpty) {
      userData.email = user.email;
      needsUpdate = true;
    }
    
    if (userData.targetEmail == null || userData.targetEmail!.isEmpty) {
      userData.targetEmail = user.email;
      needsUpdate = true;
    }
    
    // If email was missing, update Firestore
    if (needsUpdate) {
      print('Fixing user data - updating email fields for ${user.uid}');
      await CrudHelper().updateUserData(userData);
    }
    
    print('Stream current target email ${userData.targetEmail}');
    return userData;
  }

  // auth change user stream
  Stream<UserData?> get user {
    return _firebaseAuth.authStateChanges().asyncMap(_userDataFromUser);
  }

  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      auth.User? user = result.user;
      return user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  // register with email and password
  Future register(String email, String password, String role) async {
    try {
      auth.UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      auth.User? user = result.user;

      // Check for duplicate (though Firebase auth handles this mostly)
      UserData? duplicate = await CrudHelper().getUserData(
        'email',
        user!.email!,
      );
      if (duplicate != null) {
        print("duplicate email");
        return null;
      }

      // Create role map based on selection
      Map<String, bool> rolesMap = {};
      if (role == 'SuperAdmin')
        rolesMap = {'superadmin': true};
      else if (role == 'Manager')
        rolesMap = {'manager': true};
      else
        rolesMap = {'staff': true}; // Default to staff

      UserData userData = UserData(
        uid: user.uid,
        targetEmail: user.email,
        email: user.email,
        verified: user.emailVerified,
        roles: rolesMap,
      );

      await CrudHelper().updateUserData(userData);
      return user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  // sign out
  Future signOut() async {
    try {
      return await _firebaseAuth.signOut();
    } catch (error) {
      print(error.toString());
      return null;
    }
  }
}
