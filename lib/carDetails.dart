import 'package:finall/orderConfirmation.dart';
import 'package:finall/view/bnpl.dart';
import 'package:finall/view/escrowScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carBookingScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

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
      'make': widget.car['make'],
      'model': widget.car['model'],
      'price': widget.car['price'],
      'pickUpDate': _pickUpDate!.toIso8601String(),
      'dropOffDate': _dropOffDate!.toIso8601String(),
      'totalPrice': totalPrice,
      'userID': user.uid,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.car['image'] != null && widget.car['image'].toString().startsWith('http'))
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
                  )
                else
                  Center(
                    child: Image.asset(
                      'assets/kisooo.png',
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  carName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make: ${widget.car['make'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Model: ${widget.car['model'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Year: ${widget.car['year'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${price.toStringAsFixed(2)} EGP/day',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CarBookingScreen(
                    onDatesConfirmed: _updateBookingDates,
                    initialPickUpDate: _pickUpDate,
                    initialDropOffDate: _dropOffDate,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_pickUpDate == null || _dropOffDate == null)
                      ? null
                      : () {
                          final int days = _dropOffDate!.difference(_pickUpDate!).inDays;
                          final double pricePerDay = widget.car['price'] ?? 0.0;
                          final double totalPrice = pricePerDay * (days > 0 ? days : 1);

                          final orderDetails = {
                            'carId': widget.car['id']?.toString() ?? 'unknown_id',
                            'carName': (widget.car['name'] ?? '${widget.car['make'] ?? ''} ${widget.car['model'] ?? ''}').toString().trim().isEmpty
                                ? 'Unknown Car'
                                : (widget.car['name'] ?? '${widget.car['make'] ?? ''} ${widget.car['model'] ?? ''}'),
                            'pricePerDay': pricePerDay,
                            'pickUpDate': _pickUpDate!.toIso8601String(),
                            'dropOffDate': _dropOffDate!.toIso8601String(),
                            'confirmationType': 'BOOK_NOW',
                            'totalPrice': totalPrice,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderConfirmation(
                                orderDetails: orderDetails,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_pickUpDate == null || _dropOffDate == null)
                      ? null
                      : () {
                          final int days = _dropOffDate!.difference(_pickUpDate!).inDays;
                          final double totalPrice = (widget.car['price'] ?? 0.0) * (days > 0 ? days : 1);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BnplPlanSelectionScreen(
                                car: widget.car,
                                pickUpDate: _pickUpDate!,
                                dropOffDate: _dropOffDate!,
                                totalPrice: totalPrice,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.orangeAccent,
                  ),
                  child: const Text(
                    'Buy Now, Pay Later!',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_pickUpDate == null || _dropOffDate == null)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EscrowScreen(
                                car: widget.car,
                                pickUpDate: _pickUpDate!,
                                dropOffDate: _dropOffDate!,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'Secure with Escrow',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                // Add Discount Info Card
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('wallets')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final kPoints = snapshot.data?.get('kPoints') ?? 0;
                    double discountPercentage = 0.0;
                    String levelName = 'Bronze';

                    if (kPoints >= 1000) {
                      discountPercentage = 0.15;
                      levelName = 'Platinum';
                    } else if (kPoints >= 500) {
                      discountPercentage = 0.10;
                      levelName = 'Gold';
                    } else if (kPoints >= 100) {
                      discountPercentage = 0.05;
                      levelName = 'Silver';
                    }

                    final pricePerDay = widget.car['price'] ?? 0.0;
                    final discountAmount = pricePerDay * discountPercentage;
                    final discountedPrice = pricePerDay - discountAmount;

                    return Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Discount',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Level: $levelName',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'K-Points: $kPoints',
                              style: TextStyle(fontSize: 16),
                            ),
                            if (discountPercentage > 0) ...[
                              SizedBox(height: 8),
                              Text(
                                'Discount: ${(discountPercentage * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Discounted Price: ${discountedPrice.toStringAsFixed(2)} EGP/day',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${(widget.car['price'] ?? 0.0 * (_dropOffDate!.difference(_pickUpDate!).inDays > 0 ? _dropOffDate!.difference(_pickUpDate!).inDays : 1)).toStringAsFixed(0)} EGP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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