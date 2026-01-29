import 'package:flutter/material.dart';
import 'package:gadget/app/mainview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gadget/services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(MainView());
}