import 'package:flutter/material.dart';
import 'ProfileScreeen.dart';
import 'search.dart';
import 'view/homescreen.dart';

class MyTransactions extends StatefulWidget {
  @override
  _MyTransactionsState createState() => _MyTransactionsState();
}

class _MyTransactionsState extends State<MyTransactions> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _transactions = [
    {'name': 'Ahmed Amr', 'date': DateTime.now(), 'amount': -50.75},
    {'name': 'Omar Weeka', 'date': DateTime.now().subtract(Duration(days: 1)), 'amount': 1200.00},
    {'name': 'Arthur Morgan', 'date': DateTime.now().subtract(Duration(days: 5)), 'amount': -75.30},
  ];

  List<Map<String, dynamic>> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _filteredTransactions = _transactions;
  }

  void _filterTransactions(String query) {
    setState(() {
      _filteredTransactions = _transactions
          .where((transaction) =>
          transaction['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'My Transactions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Transactions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterTransactions,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? Center(
                child: Text(
                  'No transactions found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        transaction['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${transaction['date'].toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Text(
                        transaction['amount'] > 0
                            ? '+\$${transaction['amount'].toStringAsFixed(2)}'
                            : '-\$${transaction['amount'].abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: transaction['amount'] > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        print('Transaction tapped: ${transaction['name']}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Active index for Transactions
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
            // Already on Transactions screen
              break;
            case 2:
            // Navigate to Favorites
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
