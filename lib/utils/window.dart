import 'package:flutter/material.dart';
import 'package:gadget/utils/form.dart';
import 'package:gadget/app/forms/itemEntryForm.dart';
import 'package:gadget/app/forms/salesEntryForm.dart';
import 'package:gadget/app/forms/stockEntryForm.dart';
import 'package:gadget/app/transactions/monthHistory.dart';
import 'package:gadget/app/transactions/transactionList.dart';
import 'package:gadget/app/transactions/dueTransactions.dart';

class WindowUtils {
  static Widget getCard(String label, {Color color = Colors.white}) {
    return Expanded(
      child: Card(
        color: color,
        elevation: 5.0,
        child: Center(
          heightFactor: 2,
          child: Text(label),
        ),
      ),
    );
  }

  static void navigateToPage(
      BuildContext context, {
        String? caller,
        String? target,
      }) async {
    final Map<String, Widget> _stringToForm = {
      'Item Entry': ItemEntryForm(title: target),
      'Sales Entry': SalesEntryForm(title: target),
      'Stock Entry': StockEntryForm(title: target),
      'Month History': MonthlyHistory(),
      'Transactions': TransactionList(),
      'Due Transactions': DueTransaction(),
    };

    if (caller == target || target == null || !_stringToForm.containsKey(target)) {
      return;
    }

    final getForm = _stringToForm[target];
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return getForm!;
    }));
  }

  static void moveToLastScreen(BuildContext context, {bool modified = false}) {
    debugPrint("I am called. Going back screen");
    Navigator.pop(context, modified);
  }

  static void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showAlertDialog(
      BuildContext context,
      String title,
      String message, {
        void Function(BuildContext)? onPressed,
      }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                moveToLastScreen(context);
                if (onPressed != null) {
                  onPressed(context);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget genButton(
      BuildContext context,
      String name,
      void Function()? onPressed,
      ) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
        child: Text(name, textScaler: TextScaler.linear(1.5)),
        onPressed: onPressed,
      ),
    );
  }

  static String? _formValidator(String? value, String? labelText) {
    if (value == null || value.isEmpty) {
      return 'Please enter $labelText';
    }
    return null;
  }

  static Widget genTextField({
    String? labelText,
    String? hintText,
    TextStyle? textStyle,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    void Function(String)? onChanged,
    String? Function(String?, String?)? validator = _formValidator,
    bool enabled = true,
  }) {
    const double _minimumPadding = 5.0;

    return Padding(
      padding: const EdgeInsets.only(top: _minimumPadding, bottom: _minimumPadding),
      child: TextFormField(
        enabled: enabled,
        keyboardType: keyboardType,
        style: textStyle,
        maxLines: maxLines,
        controller: controller,
        obscureText: obscureText,
        validator: (String? value) {
          return validator != null ? validator(value, labelText) : null;
        },
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: textStyle,
          hintText: hintText,
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 15.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  static Widget genAutocompleteTextField({
    String? labelText,
    String? hintText,
    TextStyle? textStyle,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<Map<String, String>>? suggestions,
    bool? enabled,
    String? Function(String?, String?)? validator = _formValidator,
    void Function()? onChanged,
    List<Map<String, String>> Function()? getSuggestions,
  }) {
    const double _minimumPadding = 5.0;

    return Padding(
      padding: const EdgeInsets.only(top: _minimumPadding, bottom: _minimumPadding),
      child: TextFormField(
        controller: controller,
        enabled: enabled ?? true,
        autofocus: true,
        keyboardType: keyboardType,
        style: textStyle,
        validator: (String? value) {
          return validator != null ? validator(value, labelText) : null;
        },
        onChanged: (String value) {
          if (onChanged != null) {
            onChanged();
          }
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: textStyle,
          hintText: hintText,
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 15.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }
}