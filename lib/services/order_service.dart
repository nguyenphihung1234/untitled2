import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

class OrderService {
  static const String _fileName = 'order.json';
  
  // Read orders from JSON file
  static Future<List<Order>> readOrdersFromFile() async {
    try {
      if (kIsWeb) {
        // For web, we'll use localStorage or just return empty list
        // In a real web app, you'd use localStorage or IndexedDB
        return [];
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_fileName');
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final List<dynamic> jsonList = json.decode(jsonString);
          return jsonList.map((json) => Order.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error reading orders from file: $e');
    }
    return [];
  }

  // Write orders to JSON file
  static Future<void> writeOrdersToFile(List<Order> orders) async {
    try {
      if (kIsWeb) {
        // For web, we'll just print to console
        // In a real web app, you'd use localStorage or IndexedDB
        print('Orders to save: ${json.encode(orders.map((order) => order.toJson()).toList())}');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_fileName');
        final jsonString = json.encode(orders.map((order) => order.toJson()).toList());
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      print('Error writing orders to file: $e');
    }
  }

  // Add new order to the list and save to file
  static Future<void> addOrder(List<Order> orders, Order newOrder) async {
    orders.add(newOrder);
    await writeOrdersToFile(orders);
  }

  // Remove order from the list and save to file
  static Future<void> removeOrder(List<Order> orders, int index) async {
    if (index >= 0 && index < orders.length) {
      orders.removeAt(index);
      await writeOrdersToFile(orders);
    }
  }

  // Search orders by item name
  static List<Order> searchOrdersByName(List<Order> allOrders, String searchTerm) {
    if (searchTerm.isEmpty) return allOrders;
    
    return allOrders.where((order) => 
      order.itemName.toLowerCase().contains(searchTerm.toLowerCase())
    ).toList();
  }

  // Parse orders from JSON string
  static List<Order> parseOrdersFromString(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing orders from string: $e');
      return [];
    }
  }
} 