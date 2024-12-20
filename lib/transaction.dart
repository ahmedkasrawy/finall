import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionWidget extends StatelessWidget {
  final String name;
  final DateTime date;
  final double amount;
  final VoidCallback onTap;

  TransactionWidget({
    required this.name,
    required this.date,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color amountColor = amount < 0 ? Colors.red : Colors.green;

    // Format the date
    String formattedDate = DateFormat('EEEE, MMM d, yyyy').format(date);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        elevation: 4, // Adds shadow for a lifted effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16.0,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}