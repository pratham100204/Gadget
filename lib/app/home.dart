import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gadget/app/forms/salesEntryForm.dart';
import 'package:gadget/app/notifications.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/transaction.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/bottom_nav.dart';
import 'package:gadget/utils/window.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

// [NEW] Helper class to hold detailed graph data
class DayStats {
  final double heightPct;
  final int added;
  final int sold;
  DayStats(this.heightPct, this.added, this.sold);
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static CrudHelper? crudHelper;
  UserData? userData;

  // --- DATA STATE ---
  bool isStockLoading = false;
  List<Item> allItems = [];

  // [MODIFIED] Changed from Map<String, double> to Map<String, DayStats>
  Map<String, DayStats> weeklyGraphData = {};

  // [NEW] Track viewed notifications locally to handle the red dot
  int _lastViewedTransactionCount = 0;
  bool _isFirstLoad = true;

  // Dynamic Stats
  double totalStockValue = 0.0;
  int totalStockCount = 0;
  int outOfStockCount = 0;
  int lowStockCount = 0;

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newUser = Provider.of<UserData?>(context);

    if (newUser != null) {
      bool isNewUser = userData == null || userData!.uid != newUser.uid;
      userData = newUser;
      crudHelper = CrudHelper(userData: userData);

      if (isNewUser) {
        _loadStockData();
      }
    }
  }

  void _loadStockData() async {
    if (!mounted) return;

    if (allItems.isEmpty) {
      setState(() => isStockLoading = true);
    }

    try {
      List<Item> items = await crudHelper!.getItems();
      List<ItemTransaction> transactions = [];

      try {
        if (userData?.targetEmail != null) {
          QuerySnapshot snapshot =
              await FirebaseFirestore.instance
                  .collection('${userData!.targetEmail}-transactions')
                  .get();

          transactions =
              snapshot.docs
                  .map(
                    (doc) => ItemTransaction.fromMapObject(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList();
        }
      } catch (e) {
        debugPrint("Transactions fetch failed: $e");
      }

      // Calculations
      double valueSum = 0;
      int stockSum = 0;
      int outSum = 0;
      int lowSum = 0;

      for (var item in items) {
        double price = double.tryParse(item.markedPrice ?? '0') ?? 0.0;
        if (price == 0) price = item.costPrice ?? 0.0;

        valueSum += (price * item.totalStock);
        stockSum += item.totalStock.toInt();

        if (item.totalStock <= 0)
          outSum++;
        else if (item.totalStock < 10)
          lowSum++;
      }

      // [MODIFIED] Graph Logic to include Added/Sold details
      Map<String, DayStats> graphMap = {};
      DateTime now = DateTime.now();

      for (int i = 4; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String dayName = DateFormat('E').format(date);
        String dateStr = DateFormat('MMM d').format(date);

        double dailyTotalChange = 0;
        int dailyAdded = 0;
        int dailySold = 0;

        for (var t in transactions) {
          if (t.date != null && t.date!.contains(dateStr)) {
            // Fix: Explicitly cast num to int using .toInt()
            int quantity = (t.items ?? 0).toInt();
            dailyTotalChange += quantity.abs(); // For height calculation

            if (quantity > 0) {
              dailyAdded += quantity;
            } else {
              dailySold += quantity.abs();
            }
          }
        }

        // Calculate height percentage (clamp between 0.1 and 1.0)
        double heightPct =
            dailyTotalChange > 0
                ? (dailyTotalChange / 50).clamp(
                  0.1,
                  1.0,
                ) // Adjusted divisor for scale
                : 0.1;

        graphMap[dayName] = DayStats(heightPct, dailyAdded, dailySold);
      }

      // Fallback data if empty
      if (graphMap.isEmpty) {
        graphMap = {
          "Mon": DayStats(0.3, 5, 2),
          "Tue": DayStats(0.5, 8, 4),
          "Wed": DayStats(0.2, 2, 1),
          "Thu": DayStats(0.8, 12, 6),
          "Fri": DayStats(0.6, 7, 3),
        };
      }

      if (mounted) {
        setState(() {
          allItems = items;
          totalStockValue = valueSum;
          totalStockCount = stockSum;
          outOfStockCount = outSum;
          lowStockCount = lowSum;
          weeklyGraphData = graphMap;
          isStockLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => isStockLoading = false);
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'GOOD MORNING';
    if (hour >= 12 && hour < 17) return 'GOOD AFTERNOON';
    if (hour >= 17 && hour < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null)
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 4),

                      // Real-time Name Listener
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(userData!.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          String displayName = "USER";
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data!.exists) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            if (data['name'] != null &&
                                data['name'].toString().isNotEmpty) {
                              displayName = data['name'];
                            }
                          } else if (userData!.name != null &&
                              userData!.name!.isNotEmpty) {
                            displayName = userData!.name!;
                          } else {
                            displayName =
                                userData!.email?.split('@')[0] ?? "USER";
                          }
                          return Text(
                            displayName.toUpperCase(),
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  _notificationButton(context),
                ],
              ),

              SizedBox(height: 20),

              // --- DASHBOARD CONTENT ---
              isStockLoading
                  ? Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    ),
                  )
                  : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 170,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.monetization_on,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "\$${NumberFormat.compact().format(totalStockValue)}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Total Stock Value",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.arrow_outward,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _statCardSmall(
                                  "Total Stock",
                                  "$totalStockCount",
                                  Icons.inventory_2,
                                  Colors.white,
                                ),
                                SizedBox(height: 12),
                                _statCardSmall(
                                  "Low Stock",
                                  "$lowStockCount",
                                  Icons.warning_amber,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 35),
                      _statCardHorizontal(
                        "Out of Stock",
                        "$outOfStockCount",
                        Icons.remove_shopping_cart,
                        Colors.redAccent,
                      ),
                      SizedBox(height: 50),

                      // [MODIFIED] Graph Section
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Stock Flow",
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _subTextColor),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Last 5 days (Tap bar for details)",
                                    style: TextStyle(
                                      color: _subTextColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Inventory Movement",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              height: 150,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children:
                                    weeklyGraphData.entries.map((entry) {
                                      return _graphBar(
                                        entry.key,
                                        entry.value,
                                        _accentColor,
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        elevation: 4,
        onPressed: _openScanner,
        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomNav.build(context, onFab: _openScanner),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _notificationButton(BuildContext context) {
    if (userData == null || crudHelper == null) {
      return Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: _cardColor, shape: BoxShape.circle),
        child: Icon(Icons.notifications_none, color: _subTextColor, size: 20),
      );
    }

    return StreamBuilder<List<ItemTransaction>>(
      stream: crudHelper!.getTransactionStream(),
      builder: (context, snapshot) {
        bool hasNewAlerts = false;
        int currentCount = 0;

        if (snapshot.hasData) {
          currentCount = snapshot.data!.length;

          // Initialize sync on first load so the dot doesn't show immediately if not needed
          // Or remove this block if you WANT the dot to show on fresh app start
          if (_isFirstLoad) {
            _lastViewedTransactionCount = currentCount;
            _isFirstLoad = false;
          }

          // Logic: If database has more items than we last viewed, show dot
          if (currentCount > _lastViewedTransactionCount) {
            hasNewAlerts = true;
          }
        }

        return GestureDetector(
          onTap: () {
            // [UPDATED] On Tap, sync the count so the dot disappears
            setState(() {
              _lastViewedTransactionCount = currentCount;
            });

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          },
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasNewAlerts
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: hasNewAlerts ? Colors.white : _subTextColor,
                  size: 20,
                ),
              ),
              if (hasNewAlerts)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _backgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // [MODIFIED] Graph Bar with Tooltip
  Widget _graphBar(String day, DayStats stats, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          triggerMode: TooltipTriggerMode.tap, // Shows on tap for mobile
          showDuration: Duration(seconds: 3),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _subTextColor.withOpacity(0.5)),
          ),
          textStyle: TextStyle(color: Colors.white),
          richMessage: TextSpan(
            children: [
              TextSpan(
                text: "$day Stats\n",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextSpan(text: "Added: ", style: TextStyle(color: Colors.grey)),
              TextSpan(
                text: "+${stats.added}\n",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: "Sold: ", style: TextStyle(color: Colors.grey)),
              TextSpan(
                text: "-${stats.sold}",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          child: Container(
            width: 30,
            height: 100 * stats.heightPct,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.8), width: 1),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(day, style: TextStyle(color: _subTextColor, fontSize: 10)),
      ],
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text("Scan Barcode"),
                backgroundColor: _backgroundColor,
              ),
              body: MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.noDuplicates,
                  returnImage: false,
                ),
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context);
                      _handleScannedCode(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
      ),
    );
  }

  void _handleScannedCode(String code) {
    try {
      final Item scannedItem = allItems.firstWhere(
        (item) => (item.nickName == code || item.name == code),
        orElse: () => Item(''),
      );
      if (scannedItem.name != null && scannedItem.name!.isNotEmpty) {
        _showProductDetailsPopup(scannedItem);
      } else {
        WindowUtils.showAlertDialog(
          context,
          "Not Found",
          "Item with code $code not found.",
        );
      }
    } catch (e) {
      WindowUtils.showAlertDialog(context, "Error", "Scanning failed.");
    }
  }

  void _showProductDetailsPopup(Item item) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    item.name ?? "Unknown",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.nickName ?? "No ID",
                    style: TextStyle(color: _subTextColor),
                  ),
                  Divider(color: _subTextColor),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _popupDetail("Price", "\$${item.markedPrice ?? '0'}"),
                      _popupDetail("Stock", "${item.totalStock.toInt()}"),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _subTextColor),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            "Close",
                            style: TextStyle(color: _textColor),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => SalesEntryForm(
                                      title: "Sell ${item.name}",
                                      swipeData: item,
                                    ),
                              ),
                            );
                          },
                          child: Text(
                            "Sell Now",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _popupDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: _subTextColor, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: _textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statCardSmall(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      height: 90,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: TextStyle(color: _subTextColor, fontSize: 10)),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.arrow_outward, color: _subTextColor, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _statCardHorizontal(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: TextStyle(color: _subTextColor, fontSize: 12)),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_outward, color: _subTextColor, size: 16),
        ],
      ),
    );
  }
}
