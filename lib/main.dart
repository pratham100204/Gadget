import 'package:flutter/material.dart';
import 'package:gadget/app/mainview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gadget/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(MainView());
}