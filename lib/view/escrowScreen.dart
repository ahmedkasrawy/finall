import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../orderConfirmation.dart';

class EscrowScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickUpDate;
  final DateTime dropOffDate;

  const EscrowScreen({
    required this.car,
    required this.pickUpDate,
    required this.dropOffDate,
    Key? key,
  }) : super(key: key);

  @override
  State<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends State<EscrowScreen> {
  String? _selectedBank;
  final List<String> _banks = ['QNB', 'Al Ahly', 'Bank Misr'];
  bool _isLoading = false;

  Widget _buildTrustInfo() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'How Escrow Works',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStepItem(1, 'Payment is held securely in escrow'),
            _buildStepItem(2, 'Funds are released only after car pickup'),
            _buildStepItem(3, 'Full refund if car is not as described'),
            _buildStepItem(4, '24/7 dispute resolution support'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBankCard(String bank) {
    final isSelected = _selectedBank == bank;
    return GestureDetector(
      onTap: () => setState(() => _selectedBank = bank),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Secure Escrow Partner',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEscrowOrder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login and select a bank.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final double pricePerDay = widget.car['price'] ?? 0.0;
    final int days = widget.dropOffDate.difference(widget.pickUpDate).inDays;
    final double total = pricePerDay * (days > 0 ? days : 1);

    // Calculate K-Points (10 points per 100 EGP + 50 bonus for using escrow)
    final int basePoints = (total / 100).floor() * 10;
    final int escrowBonus = 50;
    final int totalPoints = basePoints + escrowBonus;

    final order = {
      'userId': user.uid,
      'carId': widget.car['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'carName': '${widget.car['make']} ${widget.car['model']}',
      'pickUpDate': widget.pickUpDate.toIso8601String(),
      'dropOffDate': widget.dropOffDate.toIso8601String(),
      'pricePerDay': pricePerDay,
      'total': total,
      'bank': _selectedBank,
      'status': 'escrow_pending',
      'createdAt': DateTime.now().toIso8601String(),
      'kPointsEarned': totalPoints,
    };

    try {
      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Add escrow order
      final orderRef = FirebaseFirestore.instance.collection('escrow_orders').doc();
      batch.set(orderRef, order);

      // Update user's K-Points
      final walletRef = FirebaseFirestore.instance.collection('wallets').doc(user.uid);
      batch.set(walletRef, {
        'kPoints': FieldValue.increment(totalPoints),
      }, SetOptions(merge: true));

      // Add transaction record
      final transactionRef = walletRef.collection('transactions').doc();
      batch.set(transactionRef, {
        'amount': -total,
        'description': 'Escrow Payment - ${widget.car['make']} ${widget.car['model']}',
        'timestamp': FieldValue.serverTimestamp(),
        'kPoints': totalPoints,
        'type': 'ESCROW_PAYMENT',
      });

      // Commit the batch
      await batch.commit();

      if (!mounted) return;

      // Show success message with points earned
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order placed! You earned $totalPoints K-Points!',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmation(orderDetails: {
            ...order,
            'confirmationType': 'ESCROW',
          }),
        ),
      );
    } catch (e) {
      print('🔥 Escrow order save error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to place escrow order.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (widget.car['price'] ?? 0.0) *
        (widget.dropOffDate.difference(widget.pickUpDate).inDays > 0
            ? widget.dropOffDate.difference(widget.pickUpDate).inDays
            : 1);
    
    // Calculate potential K-Points
    final basePoints = (totalPrice / 100).floor() * 10;
    final escrowBonus = 50;
    final totalPoints = basePoints + escrowBonus;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Secure Payment (Escrow)'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrustInfo(),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_car,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Rental Details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.car['make']} ${widget.car['model']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'calendar_today',
                            'From',
                            widget.pickUpDate.toLocal().toString().split(' ')[0],
                          ),
                          _buildDetailRow(
                            'event',
                            'To',
                            widget.dropOffDate.toLocal().toString().split(' ')[0],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'payments',
                            'Total',
                            'EGP ${totalPrice.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earn $totalPoints K-Points',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Including $escrowBonus bonus points for using escrow!',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Bank',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._banks.map((bank) => _buildBankCard(bank)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedBank == null ? null : () => _submitEscrowOrder(context),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Place Escrow Order'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String icon, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            IconData(
              icon.codeUnitAt(0),
              fontFamily: 'MaterialIcons',
            ),
            size: 20,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
