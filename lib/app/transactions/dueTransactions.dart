import 'package:flutter/material.dart';
// Import the forms to navigate to
import 'package:gadget/app/forms/salesEntryForm.dart';
import 'package:gadget/app/forms/stockEntryForm.dart';
import 'package:gadget/app/wrapper.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/cache.dart';
import 'package:gadget/utils/form.dart';
import 'package:gadget/utils/loading.dart';
import 'package:gadget/utils/scaffold.dart';
import 'package:gadget/utils/window.dart';
import 'package:provider/provider.dart';

class DueTransaction extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DueTransactionState();
  }
}

class DueTransactionState extends State<DueTransaction> {
  static CrudHelper? crudHelper;
  Map itemMapCache = Map();
  late List<ItemTransaction> payableTransactions;
  late List<ItemTransaction> receivableTransactions;
  bool loading = true;
  static UserData? userData;

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  @override
  void initState() {
    this.payableTransactions = [];
    this.receivableTransactions = [];
    _initializeItemMapCache();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userData = Provider.of<UserData?>(context);
    if (userData != null) {
      crudHelper = CrudHelper(userData: userData);
      _updateListView();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Wrapper();
    }
    List<Tab> viewTabs = <Tab>[Tab(text: "To Receive"), Tab(text: "To Pay")];

    return DefaultTabController(
      length: viewTabs.length,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          title: Text(
            "Due Transactions",
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: _textColor),
          bottom: TabBar(
            tabs: viewTabs,
            indicatorColor: _accentColor,
            labelColor: _accentColor,
            unselectedLabelColor: _subTextColor,
          ),
        ),
        drawer: CustomScaffold.setDrawer(context),
        body: TabBarView(
          children: <Widget>[
            getDueTransactionView(type: 'receivable'),
            getDueTransactionView(type: 'payable'),
          ],
        ),
        bottomNavigationBar: buildBottomAppBar(context),
      ),
    );
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      color: _backgroundColor, // Updated to match theme
      child: Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.list_alt, color: _subTextColor),
              onPressed:
                  () => WindowUtils.navigateToPage(
                    context,
                    target: 'Transactions',
                    caller: 'Due Transactions',
                  ),
            ),
            IconButton(
              icon: Icon(
                Icons.access_alarm,
                color: _accentColor,
              ), // Highlighted current page
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.history, color: _subTextColor),
              onPressed:
                  () => WindowUtils.navigateToPage(
                    context,
                    target: 'Month History',
                    caller: 'Due Transactions',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getDueTransactionView({type}) {
    Map transactionMap = {
      'payable': this.payableTransactions,
      'receivable': this.receivableTransactions,
    };
    List<ItemTransaction> transactions = transactionMap[type];
    if (this.loading) {
      return Loading();
    }

    if (transactions.isEmpty) {
      final emptyText =
          type == 'receivable' ? 'No dues to receive' : 'No dues to pay';
      return Center(
        child: Text(emptyText, style: TextStyle(color: _subTextColor)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (BuildContext context, int index) {
        ItemTransaction transaction = transactions[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Amount",
                  style: TextStyle(color: _subTextColor, fontSize: 10),
                ),
                SizedBox(height: 4),
                Text(
                  "₹${FormUtils.fmtToIntIfPossible(transaction.dueAmount ?? 0)}", // Display Due Amount, not total
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            title: _getDescription(context, transaction), // Local helper method
            trailing: Icon(Icons.chevron_right, color: _subTextColor),
            onTap: () {
              _navigateToDetail(context, transaction); // Local helper method
            },
          ),
        );
      },
    );
  }

  // --- Logic Helpers (Moved from TransactionListState) ---

  Widget _getDescription(BuildContext context, ItemTransaction transaction) {
    String itemName = 'Unknown Item';
    String nickName = '';

    // Resolve item name from cache
    if (this.itemMapCache.containsKey(transaction.itemId)) {
      var data = this.itemMapCache[transaction.itemId];
      if (data is List && data.isNotEmpty) {
        itemName = data[0];
        if (data.length > 1) nickName = data[1];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          itemName,
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Text(
              transaction.date ?? '',
              style: TextStyle(color: _subTextColor, fontSize: 12),
            ),
            if (nickName.isNotEmpty) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  nickName,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _navigateToDetail(
    BuildContext context,
    ItemTransaction transaction,
  ) async {
    Widget targetPage;
    String title;

    // Type 0 = Sales, Type 1 = Stock
    if (transaction.type == 0) {
      title = "Edit Sale";
      targetPage = SalesEntryForm(
        title: title,
        transaction: transaction,
        forEdit: true,
      );
    } else {
      title = "Edit Stock";
      targetPage = StockEntryForm(
        title: title,
        transaction: transaction,
        forEdit: true,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
    _updateListView(); // Refresh list on return
  }

  void _updateListView() async {
    List<ItemTransaction> dueTransactions =
        await crudHelper!.getDueTransactions();
    if (!mounted) return;

    setState(() {
      // Filter receivables (Sales with due amount)
      this.receivableTransactions =
          dueTransactions.where((t) => t.type == 0).toList();

      // Filter payables (Stock/Purchases with due amount)
      this.payableTransactions =
          dueTransactions.where((t) => t.type == 1).toList();
    });
  }

  void _initializeItemMapCache() async {
    this.itemMapCache = await StartupCache().itemMap;
    if (mounted) {
      setState(() {
        this.loading = false;
      });
    }
  }
}
