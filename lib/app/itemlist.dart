import 'package:flutter/material.dart';
import 'package:gadget/app/forms/itemEntryForm.dart';
import 'package:gadget/app/forms/salesEntryForm.dart';
import 'package:gadget/app/forms/stockEntryForm.dart';
import 'package:gadget/app/wrapper.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/bottom_nav.dart';
import 'package:gadget/utils/form.dart';
import 'package:gadget/utils/loading.dart';
import 'package:gadget/utils/window.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ItemList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ItemListState();
  }
}

class ItemListState extends State<ItemList> {
  static CrudHelper? crudHelper;
  Stream<List<Item>>? items;
  static List<Item> _itemsList = [];
  List<Item> itemsList = [];
  static UserData? userData;

  // Search controller
  TextEditingController _searchController = TextEditingController();

  // Design Palette (Matches Home Page)
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _subTextColor = Colors.grey;
  final Color _textColor = Colors.white;

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

    return Scaffold(
      backgroundColor: _backgroundColor,
      // --- AppBar with Profile and Add Button ---
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[800],
              child: Text(
                userData!.email != null
                    ? userData!.email![0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          "Inventory",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Add Item Button (Top Right)
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () => navigateToDetail(Item(''), 'Create Item'),
            ),
          ),
        ],
      ),

      // --- Main Body ---
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildSearchBar(),
            SizedBox(height: 20),

            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "All Items",
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${itemsList.length} items",
                  style: TextStyle(color: _subTextColor, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 10),

            // The List
            Expanded(
              child:
                  _searchController.text.isNotEmpty
                      ? _buildFilteredListView()
                      : _buildStreamListView(),
            ),
          ],
        ),
      ),

      // --- Scanner FAB (Matches Home) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        elevation: 4,
        onPressed: _openScanner, // Opens the camera scanner
        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),

      // --- Shared Bottom Navigation ---
      bottomNavigationBar: BottomNav.build(context, onFab: _openScanner),
    );
  }

  // --- Widgets ---

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: _textColor),
              onChanged: (value) {
                setState(() {
                  _modifyItemList(value);
                });
              },
              decoration: InputDecoration(
                hintText: "Search inventory...",
                hintStyle: TextStyle(color: _subTextColor),
                prefixIcon: Icon(Icons.search, color: _subTextColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamListView() {
    return StreamBuilder<List<Item>>(
      stream: this.items,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Update local list for search reference
          if (_searchController.text.isEmpty) {
            // We don't want to overwrite if user is actively searching
            _itemsList = snapshot.data!;
            itemsList = _itemsList;
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              Item item = snapshot.data![index];
              return _buildItemCard(item);
            },
          );
        } else {
          return Loading();
        }
      },
    );
  }

  Widget _buildFilteredListView() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: this.itemsList.length,
      itemBuilder: (BuildContext context, int index) {
        Item item = this.itemsList[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(Item item) {
    String markedPrice = item.markedPrice ?? '0';
    String stockCount =
        item.totalStock != null
            ? "${item.totalStock.toInt()} in Stock"
            : "0 in Stock";

    return GestureDetector(
      key: Key(item.name ?? ''),
      onTap: () => this._showItemInfoDialog(item),
      onLongPress: () => navigateToDetail(item, 'Edit Item'),
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < 0.0) {
          this._initiateTransaction("Stock Entry", item);
        } else if (details.primaryVelocity! > 0.0) {
          this._initiateTransaction("Sales Entry", item);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Icon(Icons.inventory_2, color: Colors.grey, size: 24),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? 'Unknown',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    stockCount,
                    style: TextStyle(color: _subTextColor, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.nickName ?? '',
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "\$$markedPrice",
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Methods ---

  // Copy of Scanner Logic from Home Page
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
      final Item scannedItem = _itemsList.firstWhere(
        (item) => (item.nickName == code || item.name == code),
        orElse: () => Item(''),
      );

      if (scannedItem.name != null && scannedItem.name!.isNotEmpty) {
        _showItemInfoDialog(scannedItem);
      } else {
        WindowUtils.showAlertDialog(
          context,
          "Not Found",
          "Item not found in inventory.",
        );
      }
    } catch (e) {
      WindowUtils.showAlertDialog(context, "Error", "Could not process code.");
    }
  }

  void _showItemInfoDialog(Item item) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  item.name ?? '',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  item.nickName ?? '',
                  style: TextStyle(color: _subTextColor),
                ),
                Divider(color: _subTextColor, height: 30),
                _buildDialogRow("Price", "\$${item.markedPrice ?? '0'}"),
                _buildDialogRow("Stock", "${item.totalStock.toInt()}"),
                _buildDialogRow(
                  "Cost",
                  "${item.costPrice?.toStringAsFixed(2) ?? '0'}",
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                        ),
                        child: Text(
                          "Edit",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          navigateToDetail(item, 'Edit Item');
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _subTextColor),
                        ),
                        child: Text(
                          "Close",
                          style: TextStyle(color: _textColor),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _subTextColor)),
          Text(
            value,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void navigateToDetail(Item item, String name) async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ItemEntryForm(title: name, item: item, forEdit: true);
        },
      ),
    );

    if (result == true) {
      this._updateListView();
    }
  }

  void _initiateTransaction(String formName, Item item) async {
    String itemName = item.name ?? '';
    Map<String, Widget> formMap = {
      'Sales Entry': SalesEntryForm(swipeData: item, title: "Sell $itemName"),
      'Stock Entry': StockEntryForm(swipeData: item, title: "Buy $itemName"),
    };

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => formMap[formName]!),
    );
  }

  void _updateListView() async {
    _itemsList = await crudHelper!.getItems();
    if (mounted) {
      setState(() {
        this.items = crudHelper!.getItemStream();
        this.itemsList = _itemsList;
      });
    }
  }

  void _modifyItemList(String val) {
    if (val.isEmpty) {
      setState(() {
        itemsList = _itemsList;
      });
      return;
    }
    List<Map<String, dynamic>> itemsMapList =
        _itemsList.map((Item item) => item.toMap()).toList();
    List<Map<String, dynamic>> _suggestions =
        FormUtils.genFuzzySuggestionsForItem(val, itemsMapList);
    setState(() {
      this.itemsList =
          _suggestions.map((Map<String, dynamic> itemMap) {
            return Item.fromMapObject(itemMap);
          }).toList();
    });
  }
}
