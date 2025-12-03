import 'package:flutter/material.dart';
import 'package:gadget/app/authenticate/authenticate.dart';
import 'package:gadget/app/home.dart'; // Using Home Page as default
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/cache.dart';
import 'package:gadget/utils/form.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. REAL AUTH LOGIC
    final UserData? user = Provider.of<UserData?>(context);

    final StartupCache startupCache = StartupCache(
      userData: user,
      reload: true,
    );

    // If no user is logged in, show the Login/Register Screen
    if (user == null) {
      return Authenticate();
    } else {
      // If logged in, Initialize Cache and check permissions
      _initializeCache(startupCache);
      _checkForTargetPermission(user);

      // Go to the Dashboard
      return HomePage();
    }
  }

  void _initializeCache(StartupCache startupCache) async {
    await startupCache.itemMap;
  }

  void _checkForTargetPermission(UserData userData) async {
    bool permitted = await FormUtils.validateTargetEmail(userData);
    if (!permitted) {
      userData.targetEmail = userData.email;
      await CrudHelper().updateUserData(userData);
    }
  }
}
