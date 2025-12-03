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
  TextEditingController targetEmailController = TextEditingController();

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1C1C1E);
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
    }
  }

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
                      userData!.email != null
                          ? userData!.email![0].toUpperCase()
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
                          userData!.email ?? 'Unknown User',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // --- App Settings ---
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

            // --- Logout Button ---
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
}
