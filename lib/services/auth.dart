import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  Future<UserData?> _userDataFromUser(auth.User? user) async {
    if (user == null) {
      return null;
    }
    UserData? userData = await CrudHelper().getUserDataByUid(user.uid);
    if (userData == null) {
      // The userdatabyid method will return null when its data is null.
      // This is only case when user is just registered and doesnot happen othertimes
      // Since now user is not null (only userData supposedly is) we should allow it to happen
      return UserData(
          uid: user.uid,
          email: user.email,
          verified: user.emailVerified,
          targetEmail: user.email);
    }
    return userData;
  }

  // auth change user stream
  Stream<UserData?> get user {
    return _firebaseAuth.authStateChanges().asyncMap(_userDataFromUser);
  }

  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      auth.User? user = result.user;
      return user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  // register with email and password
  Future register(String email, String password) async {
    try {
      auth.UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      auth.User? user = result.user;
      // create a new document for the user with the uid
      UserData? duplicate =
      await CrudHelper().getUserData('email', user!.email!);
      if (duplicate != null) {
        print("duplicate email");
        return null;
      }

      UserData userData = UserData(
          uid: user.uid,
          targetEmail: user.email,
          email: user.email,
          verified: user.emailVerified,
          roles: {});

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