import 'package:finall/orderConfirmation.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final String carName =
        '${widget.car['make'] ?? 'Unknown'} ${widget.car['model'] ?? 'Car'}';

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
                'Price per day: \$${widget.car['price_per_day'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              // Embed CarBookingScreen here
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
                onPressed: () {
                  if (_pickUpDate == null || _dropOffDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select pick-up and drop-off dates.'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return OrderConfirmation(
                      orderDetails: {
                        'make': widget.car['make'],
                        'model': widget.car['model'],
                        'pickUpDate': _pickUpDate!.toIso8601String(),
                        'dropOffDate': _dropOffDate!.toIso8601String(),
                        'price_per_day': widget.car['price_per_day'],
                      },
                    );
                  }));
                },
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
