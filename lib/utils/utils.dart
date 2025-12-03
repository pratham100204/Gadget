import 'dart:async';
import 'package:gadget/models/user.dart';
import 'package:provider/provider.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/date.dart';

class AppUtils {
  static Future<Map> getTransactionsForToday(context) async {
    UserData? userData = Provider.of<UserData?>(context);
    if (userData == null) return {};
    CrudHelper crudHelper = CrudHelper(userData: userData);

    Map itemTransactionMap = Map();
    List<ItemTransaction> transactions = await crudHelper.getItemTransactions();
    if (transactions.isEmpty) {
      return itemTransactionMap;
    }
    transactions.forEach((transaction) {
      Map transactionMap = transaction.toMap();
      String date = transactionMap['date'];
      if (DateUtils.isNotOfToday(date)) {
        return;
      }
      itemTransactionMap[transactionMap['id']] = {
        'type': transactionMap['type'],
        'itemId': transactionMap['item_id'],
        'amount': transactionMap['amount'] / transactionMap['items'],
        'costPrice': transactionMap['cost_price'],
        'dueAmount': transactionMap['due_amount'],
        'items': transactionMap['items'],
        'date': date,
        'description': transactionMap['description']
      };
    });
    return itemTransactionMap;
  }
}
