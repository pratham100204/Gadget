import 'package:flutter/material.dart';
import 'package:gadget/services/auth.dart';
import 'package:gadget/utils/loading.dart';

class Register extends StatefulWidget {
  final Function? toggleView;
  Register({this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  bool loading = false;
  bool _obscurePassword = true; // Password visibility toggle

  TextEditingController userEmailController = TextEditingController();
  TextEditingController userPasswordController = TextEditingController();
  String selectedRole = 'Staff'; // Default role
  final List<String> roles = ['SuperAdmin', 'Manager', 'Staff'];

  // Design Colors
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _inputColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFFFF3B30);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey;

  // Email validation regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show the spinner
    if (loading) return Loading();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0.0,
        // Moved the title to the body for a modern look, kept action button
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(Icons.login, color: _accentColor),
            label: Text('Sign In', style: TextStyle(color: _textColor)),
            onPressed: () => widget.toggleView!(),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. Header Section
                Icon(Icons.app_registration, size: 80, color: _accentColor),
                SizedBox(height: 20),
                Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Sign up to start managing your inventory",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subTextColor, fontSize: 14),
                ),
                SizedBox(height: 40.0),

                // 2. Email Input (Custom styled to match dark theme)
                _buildDarkTextField(
                  controller: userEmailController,
                  icon: Icons.email_outlined,
                  hintText: "Email",
                  obscureText: false,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!_isValidEmail(val)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() => this.userEmailController.text = val);
                  },
                ),
                SizedBox(height: 20.0),

                // 3. Password Input
                _buildDarkTextField(
                  controller: userPasswordController,
                  icon: Icons.lock_outline,
                  hintText: "Password",
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: _subTextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator:
                      (val) =>
                          val!.length < 6
                              ? 'Enter a password 6+ chars long'
                              : null,
                  onChanged: (val) {
                    setState(() => this.userPasswordController.text = val);
                  },
                ),
                SizedBox(height: 20.0),

                // 3.5 Role Selection Dropdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _inputColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      dropdownColor: _inputColor,
                      icon: Icon(Icons.arrow_drop_down, color: _subTextColor),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      isExpanded: true,
                      items:
                          roles.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 40.0),

                // 4. Register Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          loading = true;
                          error = '';
                        });
                        String email = this.userEmailController.text.trim();
                        String password = this.userPasswordController.text;

                        dynamic result = await _auth.register(
                          email,
                          password,
                          selectedRole,
                        );

                        if (result == null) {
                          setState(() {
                            loading = false;
                            error = 'Registration failed. Email may already be in use.';
                          });
                        }
                      }
                    },
                  ),
                ),

                // 5. Error Text
                SizedBox(height: 20.0),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to create the Dark Mode Text Fields
  Widget _buildDarkTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required bool obscureText,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _subTextColor),
          prefixIcon: Icon(icon, color: _subTextColor),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          errorStyle: TextStyle(
            height: 0,
            color: Colors.transparent,
          ), // Hide default error text layout to keep it clean
        ),
      ),
    );
  }
}
