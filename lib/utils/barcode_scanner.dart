import 'package:flutter/material.dart';
import 'package:gadget/app/forms/itemEntryForm.dart';
import 'package:gadget/models/item.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Common barcode scanner utility that can be used throughout the app
/// 
/// This provides consistent scanner behavior:
/// - If item exists: shows product details dialog
/// - If item doesn't exist: opens ItemEntryForm with barcode pre-filled
class BarcodeScanner {
  /// Opens the barcode scanner screen
  /// 
  /// [context] - BuildContext for navigation
  /// [allItems] - List of all items to search through
  /// [onItemFound] - Callback when an existing item is found
  /// [onLoadData] - Optional callback to reload data after adding new item
  static void openScanner({
    required BuildContext context,
    required List<Item> allItems,
    required Function(Item) onItemFound,
    Function()? onLoadData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ScannerScreen(
          allItems: allItems,
          onItemFound: onItemFound,
          onLoadData: onLoadData,
        ),
      ),
    );
  }
}

/// Internal scanner screen widget
class _ScannerScreen extends StatefulWidget {
  final List<Item> allItems;
  final Function(Item) onItemFound;
  final Function()? onLoadData;

  const _ScannerScreen({
    required this.allItems,
    required this.onItemFound,
    this.onLoadData,
  });

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final Color _backgroundColor = const Color(0xFF000000);

  void _handleScannedCode(String code) {
    try {
      // Try to find item by nickName (barcode) or name
      final Item scannedItem = widget.allItems.firstWhere(
        (item) => (item.nickName == code || item.name == code),
        orElse: () => Item(''),
      );

      // Close scanner
      Navigator.pop(context);

      if (scannedItem.name != null && scannedItem.name!.isNotEmpty) {
        // Product found in inventory - call the callback
        widget.onItemFound(scannedItem);
      } else {
        // Product not found - open add form with barcode pre-filled
        _openAddProductForm(code);
      }
    } catch (e) {
      Navigator.pop(context);
      _showError('Scanning failed.');
    }
  }

  void _openAddProductForm(String barcode) {
    // Create a new item with the scanned barcode pre-filled
    Item newItem = Item('');
    newItem.nickName = barcode;

    // Navigate to ItemEntryForm with the barcode pre-filled
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemEntryForm(
          item: newItem,
          title: "Add New Product",
        ),
      ),
    ).then((_) {
      // Reload data when returning from the form
      if (widget.onLoadData != null) {
        widget.onLoadData!();
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Scan Barcode",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
              _handleScannedCode(barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }
}
