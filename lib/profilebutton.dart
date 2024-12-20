import 'package:flutter/material.dart';


class ProfileButton extends StatelessWidget {
  final String title;
  final Icon icon;
  final VoidCallback onTap;

  ProfileButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        elevation: 4, // Adds shadow for a lifted effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: this.icon,
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.0,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}