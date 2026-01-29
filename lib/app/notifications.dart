import 'package:flutter/material.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/loading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, color: _accentColor),
            tooltip: 'Clear All',
            onPressed: () => _showClearConfirmation(context, crudHelper),
          ),
        ],
      ),
      body: FutureBuilder<int>(
        future: _getLastViewedCount(),
        builder: (context, countSnapshot) {
          if (countSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }

          final lastViewedCount = countSnapshot.data ?? 0;

          return StreamBuilder<List<ItemTransaction>>(
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

              final allTransactions = snapshot.data!;
              
              // Filter to show only unread notifications
              // Unread = transactions beyond the last viewed count
              final unreadTransactions = allTransactions.length > lastViewedCount
                  ? allTransactions.sublist(0, allTransactions.length - lastViewedCount)
                  : <ItemTransaction>[];

              if (unreadTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 60, color: _subTextColor),
                      SizedBox(height: 10),
                      Text(
                        "No unread notifications",
                        style: TextStyle(color: _subTextColor),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: unreadTransactions.length,
                separatorBuilder: (ctx, index) => SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final trans = unreadTransactions[index];

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
          );
        },
      ),
    );
  }

  Future<int> _getLastViewedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_viewed_transaction_count') ?? 0;
  }

  void _showClearConfirmation(BuildContext context, CrudHelper crudHelper) async {
    // Get current transaction count
    final transactions = await crudHelper.getItemTransactions();
    final currentCount = transactions.length;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            'Clear Notification Badge?',
            style: TextStyle(color: _textColor),
          ),
          content: Text(
            'This will mark all notifications as read. The transactions will remain in your history.',
            style: TextStyle(color: _subTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: _subTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  // Save current count to SharedPreferences to mark as "viewed"
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('last_viewed_transaction_count', currentCount);
                  
                  // Trigger rebuild to hide notifications
                  if (mounted) {
                    setState(() {});
                  }
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notifications marked as read'),
                      backgroundColor: Colors.green,
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                } catch (e) {
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear notifications: ${e.toString()}'),
                      backgroundColor: _accentColor,
                    ),
                  );
                }
              },
              child: Text('Mark as Read', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
