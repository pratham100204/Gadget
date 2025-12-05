import 'package:flutter/material.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/loading.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatelessWidget {
  // Theme Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData?>(context);

    if (userData == null) return Loading();

    final crudHelper = CrudHelper(userData: userData);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        title: Text(
          "Notifications",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: _textColor),
        elevation: 0,
      ),
      body: StreamBuilder<List<ItemTransaction>>(
        stream: crudHelper.getTransactionStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: _subTextColor),
                  SizedBox(height: 10),
                  Text(
                    "No recent activities",
                    style: TextStyle(color: _subTextColor),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (ctx, index) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              final trans = transactions[index];

              // Determine Icon and Color based on transaction logic
              // Assuming positive quantity = added, negative = sold/removed
              bool isNegative = (trans.items ?? 0) < 0;
              IconData icon = isNegative ? Icons.outbox : Icons.add_box;
              Color iconColor = isNegative ? _accentColor : Colors.green;
              String title = isNegative ? "Stock Out" : "Stock In";

              return Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  title: Text(
                    // --- FIX IS HERE ---
                    // We use the description. If null, use itemId. If both null, "Unknown".
                    trans.description ?? trans.itemId ?? "Unknown Item",
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "$title • ${trans.date ?? ''}",
                    style: TextStyle(color: _subTextColor, fontSize: 12),
                  ),
                  trailing: Text(
                    "${(trans.items ?? 0).abs()} qty",
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
