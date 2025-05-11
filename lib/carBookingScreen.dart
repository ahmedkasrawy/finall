import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CarBookingScreen extends StatefulWidget {
  final Function(DateTime, DateTime)? onDatesConfirmed;
  final DateTime? initialPickUpDate;
  final DateTime? initialDropOffDate;

  const CarBookingScreen({
    Key? key,
    this.onDatesConfirmed,
    this.initialPickUpDate,
    this.initialDropOffDate,
  }) : super(key: key);

  @override
  State<CarBookingScreen> createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  DateTime? _pickUpDate;
  DateTime? _dropOffDate;

  @override
  void initState() {
    super.initState();
    _pickUpDate = widget.initialPickUpDate;
    _dropOffDate = widget.initialDropOffDate;
  }

  Future<void> _selectDate(BuildContext context, bool isPickUp) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickUp ? _pickUpDate ?? DateTime.now() : _dropOffDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isPickUp) {
          _pickUpDate = picked;
          if (_dropOffDate != null && _dropOffDate!.isBefore(_pickUpDate!)) {
            _dropOffDate = _pickUpDate;
          }
        } else {
          _dropOffDate = picked;
        }
      });
    }
  }

  Widget _buildDateTile(BuildContext context,
      {required String label,
        required DateTime date,
        required IconData icon,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        label,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        DateFormat('dd/MM/yyyy').format(date),
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _confirmBooking() {
    if (_pickUpDate == null || _dropOffDate == null) {
      Fluttertoast.showToast(
        msg: "Please select both pick-up and drop-off dates.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (widget.onDatesConfirmed != null) {
      widget.onDatesConfirmed!(_pickUpDate!, _dropOffDate!);
      Fluttertoast.showToast(
        msg: "Date confirmed!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            children: [
              _buildDateTile(
                context,
                label: 'Pick-up Date',
                date: _pickUpDate ?? DateTime.now(),
                icon: Icons.calendar_today,
                onTap: () => _selectDate(context, true),
              ),
              _buildDateTile(
                context,
                label: 'Drop-off Date',
                date: _dropOffDate ?? DateTime.now(),
                icon: Icons.calendar_today,
                onTap: () => _selectDate(context, false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _confirmBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Confirm Dates',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
