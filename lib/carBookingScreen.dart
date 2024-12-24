import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarBookingScreen extends StatefulWidget {
  final Function(DateTime pickUpDate, DateTime dropOffDate)? onDatesConfirmed;

  CarBookingScreen({this.onDatesConfirmed});

  @override
  _CarBookingScreenState createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  DateTime _pickUpDate = DateTime.now();
  DateTime _dropOffDate = DateTime.now().add(Duration(days: 1));

  Future<void> _selectDate(BuildContext context, bool isPickUp) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isPickUp ? _pickUpDate : _dropOffDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isPickUp) {
          _pickUpDate = pickedDate;

          // Ensure drop-off date is after pick-up date
          if (_dropOffDate.isBefore(_pickUpDate)) {
            _dropOffDate = _pickUpDate.add(Duration(days: 1));
          }
        } else {
          _dropOffDate = pickedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Your Dates",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildDateTile(
          context,
          label: "Pick-up Date",
          date: _pickUpDate,
          icon: Icons.calendar_today,
          onTap: () => _selectDate(context, true),
        ),
        Divider(),
        _buildDateTile(
          context,
          label: "Drop-off Date",
          date: _dropOffDate,
          icon: Icons.calendar_today_outlined,
          onTap: () => _selectDate(context, false),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _confirmBooking();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            "Confirm Date",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Date'),
        content: Text(
          'Pick-up: ${DateFormat('dd/MM/yyyy').format(_pickUpDate)}\n'
              'Drop-off: ${DateFormat('dd/MM/yyyy').format(_dropOffDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              if (widget.onDatesConfirmed != null) {
                widget.onDatesConfirmed!(_pickUpDate, _dropOffDate); // Notify parent
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Date confirmed!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
