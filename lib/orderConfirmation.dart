import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderConfirmation extends StatefulWidget {
  final Map<String, dynamic> orderDetails;

  const OrderConfirmation({super.key, required this.orderDetails});

  @override
  State<OrderConfirmation> createState() => _OrderConfirmationState();
}

class _OrderConfirmationState extends State<OrderConfirmation> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late double totalPrice;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
    _saveOrderToFirestore();
  }

  /// Calculate total price based on price_per_day and booking duration
  void _calculateTotalPrice() {
    final pricePerDay = widget.orderDetails['price_per_day'] ?? 0.0;

    final pickUpDate = DateTime.parse(widget.orderDetails['pickUpDate']);
    final dropOffDate = DateTime.parse(widget.orderDetails['dropOffDate']);

    final days = dropOffDate.difference(pickUpDate).inDays;
    totalPrice = pricePerDay * (days > 0 ? days : 1); // Ensure at least 1 day
  }

  Future<void> _saveOrderToFirestore() async {
    try {
      // Add the totalPrice to the order details
      widget.orderDetails['totalPrice'] = totalPrice;

      // Save the order details to Firestore
      await _firestore.collection('orders').add(widget.orderDetails);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order saved successfully!')),
      );
    } catch (e) {
      // Handle errors
      print('Error saving order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save the order.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderDetails = widget.orderDetails;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Payment Confirmed',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(width: 8.0),
                ImageIcon(
                  AssetImage('assets/check.png'),
                  size: 24.0,
                  color: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              "Thank you for choosing\nKasrawy Group!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 32.0),
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Car: ${orderDetails['make']} ${orderDetails['model']}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  Text(
                    'Pick-Up Date: ${DateFormat.yMMMd().format(DateTime.parse(orderDetails['pickUpDate']))}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  Text(
                    'Drop-Off Date: ${DateFormat.yMMMd().format(DateTime.parse(orderDetails['dropOffDate']))}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  Text(
                    'Price per Day: \$${orderDetails['price_per_day']}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8.0),
                  Divider(color: Colors.grey),
                  SizedBox(height: 8.0),
                  Text(
                    'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go Back to Home',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
