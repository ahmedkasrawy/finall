import 'package:finall/profilescreen.dart';
import 'package:finall/search.dart';
import 'package:flutter/material.dart';

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
        title: const Text('My Transactions'),
        backgroundColor: Colors.cyan.shade700,
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
                  ? Center(child: Text('No transactions found'))
                  : ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return ListTile(
                    title: Text(transaction['name']),
                    subtitle: Text(
                      '${transaction['date'].toString().split(' ')[0]}',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to the home screen
              },
              icon: Image.asset(
                'assets/home.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                onTap: () {
                  // Navigate to the SearchScreen when the TextField is tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                } ;
                },
              icon: Image.asset(
                'assets/magnifying-glass.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      toggleTheme: () {},
                      isDarkMode: true,
                    ),
                  ),
                );
              },
              icon: Image.asset(
                'assets/user.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}