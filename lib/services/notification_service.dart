import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
    print('✅ Notification Service Initialized');
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidImplementation?.requestNotificationsPermission();
    print('📱 Notification Permission: ${granted ?? false}');
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // You can add navigation logic here if needed
  }

  // Show notification for stock entry
  static Future<void> showStockNotification({
    required int itemCount,
    required String itemName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications for stock and sales transactions',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF3B30),
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '📦 Stock Added',
      'Added $itemCount x $itemName to inventory',
      details,
      payload: 'stock',
    );
    
    print('📦 Stock notification sent: $itemCount x $itemName');
  }

  // Show notification for sale
  static Future<void> showSaleNotification({
    required int itemCount,
    required String itemName,
    required double amount,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications for stock and sales transactions',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF3B30),
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '💰 Sale Made',
      'Sold $itemCount x $itemName for ₹$amount',
      details,
      payload: 'sale',
    );
    
    print('💰 Sale notification sent: $itemCount x $itemName');
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
