import 'package:flutter/material.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/utils/bottom_nav.dart';
import 'package:provider/provider.dart';

class TransactionList extends StatelessWidget {
  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;
  final Color _greenColor = const Color(0xFF34C759);
  final Color _blueColor = const Color(0xFF0A84FF);

  @override
  Widget build(BuildContext context) {
    UserData? userData = Provider.of<UserData?>(context);

    // Mock Data for the chart
    final double stockLevel = 0.8; // 80%
    final double itemsSold = 0.5; // 50%
    final double transactions = 0.65; // 65%

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Reports & Analysis",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inventory Overview",
              style: TextStyle(color: _subTextColor, fontSize: 16),
            ),
            SizedBox(height: 20),

            // --- Custom Bar Chart ---
            Container(
              height: 250,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar("Stock", stockLevel, _blueColor),
                  _buildBar("Sold", itemsSold, _accentColor),
                  _buildBar("Traffic", transactions, _greenColor),
                ],
              ),
            ),

            SizedBox(height: 30),

            // --- Analysis Description ---
            Text(
              "Analysis",
              style: TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border(left: BorderSide(color: _accentColor, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Performance Summary",
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Your inventory performance is stable. The 'Stock' levels are currently higher than 'Sold' items, indicating a surplus. Transaction traffic is moderate.",
                    style: TextStyle(color: _subTextColor, height: 1.5),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Recommendation: Consider running a promotion to increase sales and balance the stock levels.",
                    style: TextStyle(
                      color: _greenColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        elevation: 4,
        onPressed: () {},
        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomNav.build(context, onFab: () {}),
    );
  }

  Widget _buildBar(String label, double percentage, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // The Bar
        Container(
          width: 40,
          height: 150 * percentage, // Scaling height
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: _subTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
