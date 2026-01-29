import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gadget/app/forms/salesEntryForm.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/auth.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/barcode_scanner.dart';
import 'package:gadget/utils/bottom_nav.dart';
import 'package:gadget/utils/loading.dart';
import 'package:provider/provider.dart';

class Setting extends StatefulWidget {
  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Setting> {
  static CrudHelper? crudHelper;
  UserData? userData;
  static AuthService _auth = AuthService();
  bool checkStock = true;
  bool _isLoggingOut = false; // Loading state for logout

  final TextEditingController _nameController = TextEditingController();

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _inputColor = const Color(0xFF2C2C2E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  List<Item> allItems = []; // For scanning

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this.userData = Provider.of<UserData?>(context);

    if (this.userData != null) {
      crudHelper = CrudHelper(userData: this.userData);
      this.checkStock = this.userData!.checkStock ?? true;

      _loadItems(); // load items to support scanning
    }
  }

  // Load items (same as HomePage requirement)
  Future<void> _loadItems() async {
    if (crudHelper != null) {
      allItems = await crudHelper!.getItems();
      if (mounted) {
        setState(() {});
      }
    }
  }

  // --------------------------- EDIT PROFILE POPUP ----------------------------
  Future<void> _showEditProfileDialog(String currentName) async {
    _nameController.text = currentName;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  "Display Name",
                  style: TextStyle(color: _subTextColor, fontSize: 12),
                ),
                SizedBox(height: 5),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(color: _textColor),
                  cursorColor: _accentColor,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _inputColor,
                    hintText: "Enter your name",
                    hintStyle: TextStyle(color: Colors.grey),
                    errorText: _nameController.text.trim().isEmpty ? "Name is required" : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: _subTextColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Name cannot be empty"),
                      backgroundColor: Colors.red,
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userData!.uid)
                    .set(
                      {'name': newName},
                      SetOptions(merge: true),
                    ) // Use set with merge to create if missing
                    .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Profile Updated"),
                          backgroundColor: Colors.green,
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    })
                    .catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
              },
            ),
          ],
        );
      },
    );
  }

  // ----------------------------- SCANNER LOGIC -----------------------------------

  void _openScanner() {
    BarcodeScanner.openScanner(
      context: context,
      allItems: allItems,
      onItemFound: (item) {
        _showProductDetailsPopup(item);
      },
      onLoadData: _loadItems,
    );
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

  // ------------------------------ UI BUILD ------------------------------

  @override
  Widget build(BuildContext context) {
    if (this.userData == null) return Loading();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          "Settings",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- USER PROFILE HEADER ----------------
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userData!.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                String displayName = "User";
                String displayEmail = userData?.email ?? '';

                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;

                  if (data['name'] != null &&
                      data['name'].toString().isNotEmpty) {
                    displayName = data['name'];
                  }
                }

                return Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[900]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _accentColor,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Logged in as",
                              style: TextStyle(
                                color: _subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              displayName,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              displayEmail,
                              style: TextStyle(
                                color: _subTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: Icon(Icons.edit, color: _subTextColor),
                        onPressed: () => _showEditProfileDialog(displayName),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 30),

            // ---------------- PREFERENCES ----------------
            Text(
              'Preferences',
              style: TextStyle(
                color: _accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SwitchListTile(
                activeColor: _accentColor,
                title: Text(
                  "Enforce Stock Checking",
                  style: TextStyle(color: _textColor),
                ),
                value: this.checkStock,
                onChanged: (val) async {
                  setState(() => this.checkStock = val);
                  // Save to Firestore immediately
                  if (userData != null) {
                    userData!.checkStock = val;
                    await CrudHelper().updateUserData(userData!);
                  }
                },
              ),
            ),

            SizedBox(height: 30),

            // ---------------- LOGOUT BUTTON ----------------
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2C2C2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: Icon(Icons.logout, color: _accentColor),
                label: _isLoggingOut
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                        ),
                      )
                    : Text(
                        "Log Out",
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                onPressed: _isLoggingOut
                    ? null
                    : () async {
                        setState(() => _isLoggingOut = true);
                        await _auth.signOut();
                        // No need to reset state as widget will be disposed
                      },
              ),
            ),

            SizedBox(height: 20),
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),

      // ------------------------- SCANNER FAB -------------------------
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
}
