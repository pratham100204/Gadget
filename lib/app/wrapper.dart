import 'package:flutter/material.dart';
import 'package:gadget/app/authenticate/authenticate.dart';
import 'package:gadget/app/home.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';
import 'package:gadget/utils/cache.dart';
import 'package:gadget/utils/form.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:gadget/app/custom_splash.dart';

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _showSplash = true;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    // Remove native splash immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      
      // Show custom splash for minimum 1 second
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _minTimeElapsed = true;
            _updateSplashState();
          });
        }
      });
    });
  }

  void _updateSplashState() {
    // Only hide splash if minimum time has elapsed
    if (_minTimeElapsed) {
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserData? user = Provider.of<UserData?>(context);

    // Show custom splash for minimum duration
    if (_showSplash) {
      return CustomSplashScreen();
    }

    // If no user is logged in, show the Login/Register Screen
    if (user == null) {
      return Authenticate();
    }

    final StartupCache startupCache = StartupCache(
      userData: user,
      reload: true,
    );

    // If logged in, Initialize Cache and check permissions
    _initializeCache(startupCache);
    _checkForTargetPermission(user);

    // Go to the Dashboard
    return HomePage();
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
