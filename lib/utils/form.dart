import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart'; // Required for CrudHelper
import 'package:intl/intl.dart';

class FormUtils {
  static String fmtToIntIfPossible(double? value) {
    if (value == null) {
      return '';
    }

    String intString = '${value.ceil()}';
    if (double.parse(intString) == value) {
      return intString;
    } else {
      return '$value';
    }
  }

  static double getShortDouble(double value, {int round = 2}) {
    return double.parse(value.toStringAsFixed(round));
  }

  static bool isDatabaseOwner(UserData userData) {
    return userData.targetEmail == userData.email;
  }

  static bool isTransactionOwner(
    UserData userData,
    ItemTransaction transaction,
  ) {
    return transaction.signature == userData.email;
  }

  // --- THIS IS THE MISSING METHOD ---
  static Future<bool> validateTargetEmail(UserData userData) async {
    print("Checking permission for target email: ${userData.targetEmail}");

    // If target is self, permission is granted
    if (userData.email == userData.targetEmail) return true;

    // Fetch the target user's data to check roles
    UserData? targetUserData = await CrudHelper().getUserData(
      'email',
      userData.targetEmail ?? '',
    );

    // If target user has no roles or doesn't exist, deny
    if (targetUserData?.roles?.isEmpty ?? true) {
      return false;
    } else {
      // Check if the current user's email is in the target's roles list
      if (targetUserData!.roles!.containsKey(userData.email)) {
        return true;
      } else {
        return false;
      }
    }
  }
  // ----------------------------------

  static Future<String> saveTransactionAndUpdateItem(
    ItemTransaction transaction,
    Item item, {
    UserData? userData,
  }) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    String message = '';

    String? targetEmail = userData!.targetEmail;
    WriteBatch batch = db.batch();

    try {
      if (transaction.id == null) {
        // Insert operation
        transaction.createdAt = DateTime.now().millisecondsSinceEpoch;
        transaction.date = DateFormat.yMMMd().add_jms().format(DateTime.now());
        if (transaction.type == 1) item.lastStockEntry = transaction.date;
        transaction.signature = userData.email;
        batch.set(
          db.collection('$targetEmail-transactions').doc(),
          transaction.toMap(),
        );
      } else {
        // Update operation
        if (!isDatabaseOwner(userData) &&
            !isTransactionOwner(userData, transaction)) {
          return "Permission Denied: You don't have editing access";
        } else {
          transaction.signature = userData.email;
          batch.update(
            db.collection('$targetEmail-transactions').doc(transaction.id),
            transaction.toMap(),
          );
        }
      }

      item.used += 1;

      if (isDatabaseOwner(userData)) {
        print("db owner so updating item $item");
        batch.update(
          db.collection('$targetEmail-items').doc(item.id),
          item.toMap(),
        );
      }

      await batch.commit();
    } catch (e) {
      message = 'Error updating transaction info! Try again.';
    }
    return message;
  }

  static void deleteTransactionAndUpdateItem(
    Function callback,
    ItemTransaction transaction,
    Item item,
    UserData userData,
  ) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    String message = '';
    String? targetEmail = userData.targetEmail;
    WriteBatch batch = db.batch();

    if (!isDatabaseOwner(userData) &&
        !isTransactionOwner(userData, transaction)) {
      callback("Permission Denied: You don't have deleting access");
      return;
    }

    if (item.id == null || !isDatabaseOwner(userData)) {
      batch.delete(
        db.collection('$targetEmail-transactions').doc(transaction.id),
      );
      await batch.commit();
      callback(message);
      return;
    }

    item.used += 1;

    if (transaction.type == 0) {
      item.increaseStock(transaction.items!);
    } else {
      item.decreaseStock(transaction.items!);
    }
    try {
      batch.delete(
        db.collection('$targetEmail-transactions').doc(transaction.id),
      );
      batch.update(
        db.collection('$targetEmail-items').doc(item.id),
        item.toMap(),
      );

      await batch.commit();
    } catch (e) {
      message = "Error deleting transaction info! Try again.";
    }

    callback(message);
  }

  static List<Map<String, dynamic>> genFuzzySuggestionsForItem(
    String sampleString,
    List<Map<String, dynamic>> sourceList,
  ) {
    if (sourceList.isEmpty) {
      return sourceList;
    }
    List<Map<String, dynamic>> result =
        sourceList.where((map) {
          String itemName = map['name'].toLowerCase();
          String itemNickName = map['nickName']?.toLowerCase() ?? '';

          // FIX: Added RegExp.escape to prevent crashes when searching special characters like (, ), *, +
          List<String> strsWithWildCards =
              "$sampleString"
                  .split("")
                  .map((letter) => ".*${RegExp.escape(letter)}")
                  .toList();
          strsWithWildCards.add('.*');
          String regexPattern = strsWithWildCards.join('');

          try {
            RegExp regExp = new RegExp(
              "$regexPattern",
              caseSensitive: false,
              multiLine: false,
            );
            return regExp.hasMatch("$itemName") ||
                regExp.hasMatch("$itemNickName");
          } catch (e) {
            // Fallback to simple contains if regex fails essentially
            return itemName.contains(sampleString) ||
                itemNickName.contains(sampleString);
          }
        }).toList();

    return result;
  }
}
