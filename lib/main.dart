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
      const jsonString = '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1},{"Item": "A1002","ItemName": "MacBook Pro","Price": 2500,"Currency": "USD","Quantity":1},{"Item": "A1003","ItemName": "iPad Pro","Price": 800,"Currency": "USD","Quantity":2},{"Item": "A1004","ItemName": "AirPods Pro","Price": 250,"Currency": "USD","Quantity":1},{"Item": "A1005","ItemName": "Apple Watch","Price": 400,"Currency": "USD","Quantity":1},{"Item": "A1006","ItemName": "iMac","Price": 1800,"Currency": "USD","Quantity":1},{"Item": "A1007","ItemName": "Mac Mini","Price": 700,"Currency": "USD","Quantity":1},{"Item": "A1008","ItemName": "HomePod","Price": 300,"Currency": "USD","Quantity":2}]';
      final parsedOrders = OrderService.parseOrdersFromString(jsonString);
      
      if (parsedOrders.isNotEmpty) {
        setState(() {
          _orders.clear();
          _orders.addAll(existingOrders);
          _orders.addAll(parsedOrders);
          _filteredOrders.clear();
          _filteredOrders.addAll(_orders);
        });
      } else {
        // If parsing failed, add some default orders
        setState(() {
          _orders.clear();
          _orders.addAll(existingOrders);
          _orders.addAll([
            Order(item: 'A1000', itemName: 'Iphone 15', price: 1200, currency: 'USD', quantity: 1),
            Order(item: 'A1001', itemName: 'Iphone 16', price: 1500, currency: 'USD', quantity: 1),
          ]);
          _filteredOrders.clear();
          _filteredOrders.addAll(_orders);
        });
      }
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
      // Check for duplicate item ID
      if (_orders.any((order) => order.item == _itemController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item ID already exists! Please use a different ID.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
        const SnackBar(
          content: Text('Order added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeOrder(int index) async {
    final orderToRemove = _filteredOrders[index];
    
    // Show confirmation dialog
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${orderToRemove.itemName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      final originalIndex = _orders.indexOf(orderToRemove);
      
      await OrderService.removeOrder(_orders, originalIndex);
      
      setState(() {
        _filteredOrders.clear();
        _filteredOrders.addAll(_orders);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${orderToRemove.itemName} removed from orders'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
            child: SingleChildScrollView(
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
                          Column(
                            children: [
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
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
                                  const Expanded(child: SizedBox()),
                                ],
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
                    child: Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _filteredOrders.clear();
                              _filteredOrders.addAll(_orders);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Orders Table Section
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Orders',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Total: \$${_filteredOrders.fold(0.0, (sum, order) => sum + (order.price * order.quantity)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 400,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 800) {
                                      // Mobile layout - use ListView
                                      if (_filteredOrders.isEmpty) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                              SizedBox(height: 16),
                                              Text(
                                                'No orders found',
                                                style: TextStyle(fontSize: 18, color: Colors.grey),
                                              ),
                                              Text(
                                                'Try adjusting your search or add new orders',
                                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return ListView.builder(
                                        itemCount: _filteredOrders.length,
                                        itemBuilder: (context, index) {
                                          final order = _filteredOrders[index];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            child: ListTile(
                                              title: Text(order.itemName),
                                              subtitle: Text('ID: ${order.item} | Qty: ${order.quantity} | Price: ${order.price} ${order.currency}'),
                                              trailing: IconButton(
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
                                          );
                                        },
                                      );
                                    } else {
                                      // Desktop layout - use DataTable
                                      if (_filteredOrders.isEmpty) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                              SizedBox(height: 16),
                                              Text(
                                                'No orders found',
                                                style: TextStyle(fontSize: 18, color: Colors.grey),
                                              ),
                                              Text(
                                                'Try adjusting your search or add new orders',
                                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return SingleChildScrollView(
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
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
