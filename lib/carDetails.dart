import 'package:finall/orderConfirmation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carBookingScreen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  CarDetailsScreen({required this.car});

  @override
  _CarDetailsScreenState createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  DateTime? _pickUpDate;
  DateTime? _dropOffDate;

  // Callback to update booking dates from CarBookingScreen
  void _updateBookingDates(DateTime pickUp, DateTime dropOff) {
    setState(() {
      _pickUpDate = pickUp;
      _dropOffDate = dropOff;
    });
  }

  // Save booking to Firebase and navigate to OrderConfirmation screen
  Future<void> _saveBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    if (_pickUpDate == null || _dropOffDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select pick-up and drop-off dates.')),
      );
      return;
    }

    // Calculate the total price based on booking duration
    final double pricePerDay = widget.car['price'] ?? 0.0;
    final int days = _dropOffDate!.difference(_pickUpDate!).inDays;
    final double totalPrice = pricePerDay * (days > 0 ? days : 1); // Ensure at least 1 day

    final bookingDetails = {
      'carName': '${widget.car['make']} ${widget.car['model']}',
      'pickUpDate': _pickUpDate!.toIso8601String(),
      'dropOffDate': _dropOffDate!.toIso8601String(),
      'price': pricePerDay, // Save price per day
      'totalPrice': totalPrice, // Save total price
      'userID': user.uid,
      'make': widget.car['make'],
      'model': widget.car['model'],
    };

    try {
      // Save booking to Firestore
      await FirebaseFirestore.instance.collection('bookings').add(bookingDetails);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking saved successfully!')),
      );

      // Navigate to the order confirmation screen with the booking details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmation(orderDetails: bookingDetails),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String carName =
        '${widget.car['make'] ?? 'Unknown'} ${widget.car['model'] ?? 'Car'}';
    final double price = widget.car['price'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text(carName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.car['image'] != null)
                Center(
                  child: Image.network(
                    widget.car['image'],
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/kisooo.png',
                        height: 200,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
              Text(
                carName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Make: ${widget.car['make'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Model: ${widget.car['model'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Year: ${widget.car['year'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Price: \$${price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CarBookingScreen(
                  onDatesConfirmed: _updateBookingDates, // Pass callback
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveBooking,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(
                  'Book Now',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}