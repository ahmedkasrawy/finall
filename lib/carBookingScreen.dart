import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarBookingScreen extends StatefulWidget {
  @override
  _CarBookingScreenState createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  DateTime _pickUpDate = DateTime.now();
  DateTime _dropOffDate = DateTime.now().add(Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ensures it takes only as much space as needed
        children: [
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _pickUpDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  _pickUpDate = pickedDate;
                });
              }
            },
            child: Text(
              "Pick-up Date: ${DateFormat('dd/MM/yyyy').format(_pickUpDate)}",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _dropOffDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  _dropOffDate = pickedDate;
                });
              }
            },
            child: Text(
              "Drop-off Date: ${DateFormat('dd/MM/yyyy').format(_dropOffDate)}",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
