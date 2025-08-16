import 'package:flutter/material.dart';
import 'models/order.dart';
import 'services/order_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Order',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const OrderPage(),
    );
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final List<Order> _orders = [];
  final List<Order> _filteredOrders = [];
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load existing orders from file
      final existingOrders = await OrderService.readOrdersFromFile();
      
      // Parse the provided JSON string and add to orders
      const jsonString = '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]';
      final parsedOrders = OrderService.parseOrdersFromString(jsonString);
      
      setState(() {
        _orders.clear();
        _orders.addAll(existingOrders);
        _orders.addAll(parsedOrders);
        _filteredOrders.clear();
        _filteredOrders.addAll(_orders);
      });
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final searchTerm = _searchController.text;
    setState(() {
      _filteredOrders.clear();
      _filteredOrders.addAll(
        OrderService.searchOrdersByName(_orders, searchTerm)
      );
    });
  }

  Future<void> _addOrder() async {
    if (_formKey.currentState!.validate()) {
      final newOrder = Order(
        item: _itemController.text,
        itemName: _itemNameController.text,
        price: double.parse(_priceController.text),
        currency: _currencyController.text,
        quantity: int.parse(_quantityController.text),
      );

      await OrderService.addOrder(_orders, newOrder);
      
      setState(() {
        _filteredOrders.clear();
        _filteredOrders.addAll(_orders);
      });

      // Clear form
      _formKey.currentState!.reset();
      _itemController.clear();
      _itemNameController.clear();
      _priceController.clear();
      _quantityController.clear();
      _currencyController.text = 'USD';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order added successfully!')),
      );
    }
  }

  Future<void> _removeOrder(int index) async {
    final orderToRemove = _filteredOrders[index];
    final originalIndex = _orders.indexOf(orderToRemove);
    
    await OrderService.removeOrder(_orders, originalIndex);
    
    setState(() {
      _filteredOrders.clear();
      _filteredOrders.addAll(_orders);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${orderToRemove.itemName} removed from orders')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header with Question and Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Question:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const Text(
                      'Duration: 90 minutes | Marks: 10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Main Title
                const Text(
                  'My Order',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Input Form Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Item',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _itemController,
                                decoration: const InputDecoration(
                                  labelText: 'Item',
                                  hintText: 'Item',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter item';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _itemNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Item Name',
                                  hintText: 'Item Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter item name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  hintText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  hintText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter quantity';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid quantity';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _currencyController,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter currency';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _addOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add Item to Cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Search Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Item Name',
                      hintText: 'Enter item name to search...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Orders Table Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Orders',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Id')),
                                      DataColumn(label: Text('Item')),
                                      DataColumn(label: Text('Item Name')),
                                      DataColumn(label: Text('Quantity')),
                                      DataColumn(label: Text('Price')),
                                      DataColumn(label: Text('Currency')),
                                      DataColumn(label: Text('Action')),
                                    ],
                                    rows: _filteredOrders.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final order = entry.value;
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(order.item)),
                                          DataCell(Text(order.item)),
                                          DataCell(Text(order.itemName)),
                                          DataCell(Text(order.quantity.toString())),
                                          DataCell(Text(order.price.toString())),
                                          DataCell(Text(order.currency)),
                                          DataCell(
                                            IconButton(
                                              icon: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlue,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                              onPressed: () => _removeOrder(index),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Số 8, Tôn Thất Thuyết, Cầu giấy, Hà Nội',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
