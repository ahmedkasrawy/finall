import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderConfirmation extends StatefulWidget {
  final Map<String, dynamic> orderDetails;

  const OrderConfirmation({super.key, required this.orderDetails});

  @override
  State<OrderConfirmation> createState() => _OrderConfirmationState();
}

class _OrderConfirmationState extends State<OrderConfirmation> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _saveOrderToFirestore();
  }

  Future<void> _saveOrderToFirestore() async {
    try {
      // Save the order details to the Firestore database
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
      backgroundColor: Colors.grey[200], // Sets the background color of the screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centers items vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Aligns items horizontally
          children: [
            Row(
              mainAxisSize: MainAxisSize.min, // Ensures the row doesn't take extra space
              children: [
                Text(
                  'Payment Confirmed',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    decoration: TextDecoration.none, // Removes the line under the text
                  ),
                ),
                SizedBox(width: 8.0), // Adds spacing between text and the icon
                ImageIcon(
                  AssetImage('assets/check.png'), // Path to the image asset
                  size: 24.0,
                  color: Colors.green, // Set the color of the icon
                ),
              ],
            ),
            SizedBox(height: 16.0), // Adds spacing between the two text elements
            Text(
              "Thank you for choosing\nKasrawy Group!",
              textAlign: TextAlign.center, // Ensures the text is centered
              style: TextStyle(
                fontSize: 30,
                color: Colors.black,
                decoration: TextDecoration.none, // Removes the line under the text
              ),
            ),
            SizedBox(height: 32.0), // Adds spacing
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
                    'Pick-Up Date: ${orderDetails['pickUpDate']}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  Text(
                    'Drop-Off Date: ${orderDetails['dropOffDate']}',
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
                    'Total Price: \$${orderDetails['totalPrice']}',
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
