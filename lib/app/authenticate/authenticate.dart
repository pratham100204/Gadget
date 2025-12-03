import 'package:flutter/material.dart';
import 'package:gadget/app/authenticate/register.dart';
import 'package:gadget/app/authenticate/sign_in.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;

  // Toggle between SignIn and Register views
  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    // The visual design is handled inside SignIn and Register widgets.
    // This wrapper simply controls the navigation logic.
    if (showSignIn) {
      return SignIn(toggleView: toggleView);
    } else {
      return Register(toggleView: toggleView);
    }
  }
}
