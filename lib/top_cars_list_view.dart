import 'package:flutter/material.dart';

class TopCarsListView extends StatefulWidget {
  final List<Map<String, dynamic>> topCars;
  final void Function(Map<String, dynamic> car) onCarTap;

  TopCarsListView({required this.topCars, required this.onCarTap});

  @override
  _TopCarsListViewState createState() => _TopCarsListViewState();
}

class _TopCarsListViewState extends State<TopCarsListView> {
  final Map<int, bool> _favorites = {}; // To track favorite state for each car

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.topCars.length,
      itemBuilder: (context, index) {
        final car = widget.topCars[index];
        final isFavorite = _favorites[index] ?? false;

        return GestureDetector(
          onTap: () => widget.onCarTap(car),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: car['image'] != null && car['image'].isNotEmpty
                        ? Image.network(
                      car['image'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                        : Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Car Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          car['name'] ?? '${car['make']} ${car['model']}' ?? 'Unknown Car',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make: ${car['make'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Model: ${car['model'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Year: ${car['year'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite Icon
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _favorites[index] = !isFavorite; // Toggle favorite state
                      });
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
