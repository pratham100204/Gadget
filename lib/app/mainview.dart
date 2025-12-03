import 'package:flutter/material.dart';
import 'package:gadget/app/forms/salesEntryForm.dart';
import 'package:gadget/app/home.dart';
import 'package:gadget/app/itemlist.dart';
import 'package:gadget/app/settings.dart';
import 'package:gadget/app/transactions/transactionList.dart';
import 'package:gadget/app/wrapper.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/auth.dart';
import 'package:gadget/utils/theme.dart';
import 'package:provider/provider.dart';

class MainView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserData?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bookkeeping app',
        theme: AppTheme.dark(),

        // CORRECTION:
        // 1. We defined "/" as Wrapper() (this acts as the 'home').
        // 2. We removed the 'home: Wrapper()' property at the bottom to fix the error.
        routes: <String, WidgetBuilder>{
          "/":
              (BuildContext context) =>
                  Wrapper(), // The entry point checking Auth
          "/home": (BuildContext context) => HomePage(),
          "/mainForm":
              (BuildContext context) => SalesEntryForm(title: "Sales Entry"),
          "/itemList": (BuildContext context) => ItemList(),
          "/transactionList": (BuildContext context) => TransactionList(),
          "/settings": (BuildContext context) => Setting(),
        },
        // home: Wrapper(), // REMOVED to fix the assertion error
      ),
    );
  }
}
