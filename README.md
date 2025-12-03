# gadget

A Complete Inventory Management Application using 
flutter 
firebase 
dart 
Dependencies Used :
  cupertino_icons: ^1.0.8
  flutter_launcher_icons: ^0.14.4
  cloud_firestore: ^6.0.3
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  flutter_spinkit: ^5.2.2
  provider: ^6.1.5+1
  intl: ^0.20.2
  flutter_typeahead: ^5.2.0
  shared_preferences: ^2.2.0
  image_picker: ^0.8.7+5
  image: ^4.0.17
  image_cropper: ^11.0.0
  mobile_scanner: ^7.1.3
  lottie: ^3.3.2

## Abstract :
This report documents the design, development, and implementation of “Gadget – Inventory Management System,” a real-time mobile application built using Flutter and the Firebase ecosystem. The primary objective of the project was to develop a scalable, efficient, and user-friendly stock management solution that overcomes common limitations found in traditional and small-scale business inventory tools, such as inconsistent unit handling, manual calculation errors, poor UI structure, and lack of real-time synchronization. The system enables users to manage items, purchases, sales, and due payments through a streamlined interface with strong emphasis on accuracy, speed, and intuitive navigation. A modular architecture separates the application into key components including UI screens, stock management logic, Firebase CRUD operations, and authentication layers. Core modules such as the stock conversion engine automate unit-to-base conversion, while the weighted average cost algorithm ensures precise cost price and profit calculations across multiple purchase entries. Firebase Firestore provides real-time updates for items, purchases, sales, and due records, whereas Firebase Storage handles image uploads such as product photos and receipts. Additional features like due tracking, search and filter functionality, and responsive Figma-based layouts enhance usability and operational clarity. Performance optimization played a significant role, with efficient state management (Provider/Riverpod), minimized database reads, and cached network images ensuring smooth performance even on entry-level devices. Iterative testing was conducted to validate stock calculations, unit conversions, UI responsiveness, and data integrity under various usage conditions. Beyond the core system, the project also emphasizes extensibility and future enhancements. Potential extensions include PDF report exports, multi-user access with roles, GST invoice generation, cloud-based analytics dashboards, barcode/QR scanning, and AI-based stock prediction—features that aim to boost reliability, business intelligence, and long-term adoption. Overall, Gadget demonstrates how thoughtful UI design, precise computation logic, and a real-time cloud backend can together deliver a robust, modern inventory management solution tailored for shops, wholesalers, and small businesses.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
