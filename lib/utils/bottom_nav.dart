import 'package:flutter/material.dart';

class BottomNav {
  static BottomAppBar build(
    BuildContext context, {
    required VoidCallback onFab,
  }) {
    // Determine current route to highlight the correct button
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      color: Color(0xFF000000),
      elevation: 0,
      notchMargin: 8.0,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _NavButton(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentRoute == '/' || currentRoute == '/home',
              onTap: () {
                if (currentRoute != '/') {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
            _NavButton(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              isSelected: currentRoute == '/itemList',
              onTap: () {
                if (currentRoute != '/itemList') {
                  Navigator.pushReplacementNamed(context, '/itemList');
                }
              },
            ),
            SizedBox(width: 48), // Space for FAB
            _NavButton(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              isSelected: currentRoute == '/transactionList',
              onTap: () {
                if (currentRoute != '/transactionList') {
                  Navigator.pushReplacementNamed(context, '/transactionList');
                }
              },
            ),
            _NavButton(
              icon: Icons.settings_outlined,
              label: 'Setting',
              isSelected: currentRoute == '/settings',
              onTap: () {
                if (currentRoute != '/settings') {
                  Navigator.pushReplacementNamed(context, '/settings');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Color(0xFFFF3B30);
    final Color inactiveColor = Color(0xFF8E8E93);

    return InkWell(
      onTap: onTap,
      customBorder: CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
