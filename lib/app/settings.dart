import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/auth.dart';
import 'package:gadget/services/crud.dart';
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

  final TextEditingController _nameController = TextEditingController();

  // [ADDED] Variable to store name locally for instant updates
  String? _tempName;

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
  final Color _inputColor = const Color(0xFF2C2C2E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this.userData = Provider.of<UserData?>(context);

    if (this.userData != null) {
      crudHelper = CrudHelper(userData: this.userData);
      this.checkStock = this.userData!.checkStock ?? true;

      // Only fill controller if empty to avoid overwriting user typing
      if (_nameController.text.isEmpty) {
        _nameController.text =
            userData?.name ?? userData?.email?.split('@')[0] ?? '';
      }
    }
  }

  // --- THE UPDATED POPUP DIALOG ---
  Future<void> _showEditProfileDialog() async {
    // Reset controller to current saved value when opening
    _nameController.text =
        _tempName ?? userData?.name ?? userData?.email?.split('@')[0] ?? '';

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
                  autofocus: true, // Keyboard pops up automatically
                  style: TextStyle(color: _textColor),
                  cursorColor: _accentColor,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _inputColor,
                    hintText: "Enter your name",
                    hintStyle: TextStyle(color: Colors.grey),
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
                // --- INSTANT UPDATE LOGIC ---

                final newName = _nameController.text.trim();
                if (newName.isEmpty) return;

                // 1. Close Dialog IMMEDIATELY (Don't wait for server)
                Navigator.of(context).pop();

                // 2. Update Local Screen IMMEDIATELY
                setState(() {
                  _tempName = newName;
                });

                // 3. Send to Database in BACKGROUND
                if (userData?.uid != null) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userData!.uid)
                      .update({'name': newName})
                      .then((_) {
                        // Success - Optional: Show small confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Saved"),
                            backgroundColor: Colors.green,
                            duration: Duration(
                              milliseconds: 500,
                            ), // Short duration
                          ),
                        );
                      })
                      .catchError((error) {
                        // Revert if error
                        setState(() {
                          _tempName = null;
                        });
                        print("Update failed: $error");
                      });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (this.userData == null) return Loading();

    // LOGIC: Use local _tempName first (for speed), then database Name, then Email fallback
    String displayName =
        _tempName ?? userData?.name ?? userData?.email?.split('@')[0] ?? 'User';
    String displayEmail = userData?.email ?? '';

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
            // --- User Profile Header ---
            Container(
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
                          style: TextStyle(color: _subTextColor, fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          displayName, // Uses the instant variable
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          displayEmail,
                          style: TextStyle(color: _subTextColor, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Preferences
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
                onChanged: (val) => setState(() => this.checkStock = val),
              ),
            ),

            SizedBox(height: 30),

            // Edit Profile Button
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
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text(
                  "Edit Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _showEditProfileDialog,
              ),
            ),

            SizedBox(height: 15),

            // Logout Button
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
                label: Text(
                  "Log Out",
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await _auth.signOut();
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
      bottomNavigationBar: BottomNav.build(context, onFab: () {}),
    );
  }
}
