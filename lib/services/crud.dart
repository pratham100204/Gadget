import 'dart:async';
import 'package:gadget/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gadget/models/item.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/services/auth.dart';

class CrudHelper {
  AuthService auth = AuthService();
  final UserData? userData;
  CrudHelper({this.userData});

  // Item
  Future<int> addItem(Item item) async {
    String? targetEmail = this.userData!.targetEmail;
    if (targetEmail == this.userData!.email) {
      await FirebaseFirestore.instance
          .collection('$targetEmail-items')
          .add(item.toMap())
          .catchError((e) {
        print(e);
        return 0;
      });
      return 1;
    } else {
      return 0;
    }
  }

  Future<int> updateItem(Item newItem) async {
    String? targetEmail = this.userData!.targetEmail;
    if (targetEmail == this.userData!.email) {
      await FirebaseFirestore.instance
          .collection('$targetEmail-items')
          .doc(newItem.id)
          .update(newItem.toMap())
          .catchError((e) {
        print(e);
        return 0;
      });
      return 1;
    } else {
      return 0;
    }
  }

  Future<int> deleteItem(String? itemId) async {
    String? targetEmail = this.userData!.targetEmail;
    if (targetEmail == this.userData!.email) {
      await FirebaseFirestore.instance
          .collection('$targetEmail-items')
          .doc(itemId)
          .delete()
          .catchError((e) {
        print(e);
        return 0;
      });
      return 1;
    } else {
      return 0;
    }
  }

  Stream<List<Item>> getItemStream() {
    String? email = this.userData!.targetEmail;
    print("Stream current target email $email");
    return FirebaseFirestore.instance
        .collection('$email-items')
        .orderBy('used', descending: true)
        .snapshots()
        .map(Item.fromQuerySnapshot);
  }

  Future<Item?> getItem(String field, String value) async {
    String? email = this.userData!.targetEmail;
    QuerySnapshot itemSnapshots = await FirebaseFirestore.instance
        .collection('$email-items')
        .where(field, isEqualTo: value)
        .get()
        .catchError((e) {
      return null;
    });

    if (itemSnapshots.docs.isEmpty) {
      return null;
    }
    DocumentSnapshot itemSnapshot = itemSnapshots.docs.first;

    if ((itemSnapshot.data() as Map<String, dynamic>).isNotEmpty) {
      Item item = Item.fromMapObject(itemSnapshot.data() as Map<String, dynamic>);
      item.id = itemSnapshot.id;
      return item;
    } else {
      return null;
    }
  }

  Future<Item?> getItemById(String id) async {
    String? email = this.userData!.targetEmail;
    DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
        .doc('$email-items/$id')
        .get().catchError((e) {
      print(e);
      return null;
    });

    if (itemSnapshot.data() == null) {
      return null;
    }
    Item item = Item.fromMapObject(itemSnapshot.data() as Map<String, dynamic>);
    item.id = itemSnapshot.id;
    return item;
  }

  Future<List<Item>> getItems() async {
    String? email = this.userData!.targetEmail;
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-items')
        .get();
    return Item.fromQuerySnapshot(snapshots);
  }

  // Transactions
  Future<int> addTransaction(ItemTransaction transaction) async {
    String? targetEmail = this.userData!.targetEmail;
    await FirebaseFirestore.instance
        .collection('$targetEmail-transactions')
        .add(transaction.toMap())
        .catchError((e) {
      print(e);
      return 0;
    });
    return 1;
  }

  Future<int> updateTransaction(ItemTransaction newTransaction) async {
    String? targetEmail = this.userData!.targetEmail;
    await FirebaseFirestore.instance
        .collection('$targetEmail-transactions')
        .doc(newTransaction.id)
        .update(newTransaction.toMap())
        .catchError((e) {
      print(e);
      return 0;
    });
    return 1;
  }

  Future<int> deleteTransaction(String transactionId) async {
    String? targetEmail = this.userData!.targetEmail;
    await FirebaseFirestore.instance
        .collection('$targetEmail-transactions')
        .doc(transactionId)
        .delete()
        .catchError((e) {
      print(e);
      return 0;
    });
    return 1;
  }

  Future<ItemTransaction?> getTransactionById(String id) async {
    String? email = this.userData!.targetEmail;
    DocumentSnapshot transactionSnapshot = await FirebaseFirestore.instance
        .doc('$email-transactions/$id')
        .get().catchError((e) {
      print(e);
      return null;
    });

    if (transactionSnapshot.data() == null) {
      return null;
    }
    ItemTransaction transaction = ItemTransaction.fromMapObject(transactionSnapshot.data() as Map<String, dynamic>);
    transaction.id = transactionSnapshot.id;
    return transaction;
  }

  Stream<List<ItemTransaction>> getTransactionStream() {
    String? email = this.userData!.targetEmail;
    return FirebaseFirestore.instance
        .collection('$email-transactions')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(ItemTransaction.fromQuerySnapshot);
  }

  Future<List<ItemTransaction>> getItemTransactions() async {
    String? email = this.userData!.targetEmail;
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('signature', isEqualTo: email)
        .get();
    return ItemTransaction.fromQuerySnapshot(snapshots);
  }

  Future<List<ItemTransaction>> getPendingTransactions() async {
    String? email = this.userData!.targetEmail;
    UserData? user = await this.getUserData('email', email!);
    List<String>? roles = user!.roles?.keys.toList() ?? [];
    print("roles $roles");
    if (roles.isEmpty) return [];
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('signature', whereIn: roles)
        .get();
    return ItemTransaction.fromQuerySnapshot(snapshots);
  }

  Future<List<ItemTransaction>> getDueTransactions() async {
    String? email = this.userData!.targetEmail;
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('due_amount', isGreaterThan: 0.0)
        .get();
    return ItemTransaction.fromQuerySnapshot(snapshots);
  }

  Future<void> deleteAllTransactions() async {
    String? targetEmail = this.userData!.targetEmail;
    
    // Check if user has permission (must be own email)
    if (targetEmail != this.userData!.email) {
      throw Exception('Permission denied: Cannot delete transactions for other users');
    }
    
    // Get all transactions
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$targetEmail-transactions')
        .get();
    
    if (snapshots.docs.isEmpty) {
      return; // Nothing to delete
    }
    
    // Delete each transaction in batches (Firestore batch limit is 500)
    const int batchSize = 500;
    List<DocumentSnapshot> docs = snapshots.docs;
    
    for (int i = 0; i < docs.length; i += batchSize) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      
      for (int j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      
      await batch.commit();
    }
  }

  // Users
  Future<UserData?> getUserData(String field, String value) async {
    QuerySnapshot userDataSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .where(field, isEqualTo: value)
        .get()
        .catchError((e) {
      return null;
    });
    if (userDataSnapshots.docs.isEmpty) {
      return null;
    }
    DocumentSnapshot userDataSnapshot = userDataSnapshots.docs.first;
    if ((userDataSnapshot.data() as Map<String, dynamic>).isNotEmpty) {
      UserData userData = UserData.fromMapObject(userDataSnapshot.data() as Map<String, dynamic>);
      userData.uid = userDataSnapshot.id;
      return userData;
    } else {
      return null;
    }
  }

  Future<UserData?> getUserDataByUid(String uid) async {
    DocumentSnapshot _userData =
    await FirebaseFirestore.instance.doc('users/$uid').get().catchError((e) {
      print("error getting userdata $e");
      return null;
    });

    if (_userData.data() == null) {
      print("error getting userdata is $uid");
      return null;
    }

    UserData userData = UserData.fromMapObject(_userData.data() as Map<String, dynamic>);
    print("here we go $userData & roles ${userData.roles}");
    return userData;
  }

  Future<int> updateUserData(UserData userData) async {
    print("got userData and roles ${userData.toMap()}");
    
    // Ensure we're using the correct UID
    if (userData.uid == null || userData.uid!.isEmpty) {
      print("ERROR: Cannot update user data - UID is null or empty");
      return 0;
    }
    
    print("Updating Firestore document: users/${userData.uid}");
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userData.uid)
        .set(userData.toMap() as Map<String, dynamic>, SetOptions(merge: true))
        .catchError((e) {
      print("ERROR updating user data: $e");
      return 0;
    });
    return 1;
  }
}