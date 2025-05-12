import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../orderConfirmation.dart';

class BnplPlanSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickUpDate;
  final DateTime dropOffDate;
  final double totalPrice;

  const BnplPlanSelectionScreen({
    required this.car,
    required this.pickUpDate,
    required this.dropOffDate,
    required this.totalPrice,
    Key? key,
  }) : super(key: key);

  @override
  State<BnplPlanSelectionScreen> createState() => _BnplPlanSelectionScreenState();
}

class _BnplPlanSelectionScreenState extends State<BnplPlanSelectionScreen> {
  final List<Map<String, dynamic>> plans = [
    {
      'name': 'Smart Plan',
      'down': 0.30,
      'months': 3,
      'description': 'Perfect for short-term rentals with manageable payments',
      'benefits': ['Lower interest rate', 'Flexible payment schedule', 'Early payment bonus'],
    },
    {
      'name': 'Flexi Installment',
      'down': 0.20,
      'months': 6,
      'description': 'Spread your payments over a longer period',
      'benefits': ['Smaller monthly payments', 'Extended rental period', 'Payment flexibility'],
    },
    {
      'name': 'Saver Plan',
      'down': 0.50,
      'months': 2,
      'description': 'Pay more upfront, save on interest',
      'benefits': ['Lowest interest rate', 'Quick completion', 'Trust points bonus'],
    },
  ];

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
                Icon(Icons.verified_user, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Trust & Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrustItem('Secure Payment Processing'),
            _buildTrustItem('Transparent Payment Schedule'),
            _buildTrustItem('No Hidden Fees'),
            _buildTrustItem('24/7 Customer Support'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _confirmPlan(BuildContext context, Map<String, dynamic> plan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
        return;
      }

      // Show loading indicator
      setState(() => _isLoading = true);

      final double downPayment = widget.totalPrice * plan['down'];
      final double remaining = widget.totalPrice - downPayment;
      final double installmentAmount = double.parse((remaining / plan['months']).toStringAsFixed(2));

      // Calculate K-Points earned
      final int basePoints = (widget.totalPrice / 100).floor() * 10; // 10 points per 100 EGP
      final int durationBonus = plan['months'] * 5; // 5 bonus points per month
      final int totalPoints = basePoints + durationBonus;

      final List<Map<String, dynamic>> installments = [];
      final now = DateTime.now();

      for (int i = 1; i <= plan['months']; i++) {
        final dueDate = DateTime(now.year, now.month + i, now.day);
        installments.add({
          'amount': installmentAmount,
          'dueDate': dueDate.toIso8601String().split('T')[0],
          'paid': false,
        });
      }

      // First, check if wallet exists and create if it doesn't
      final walletRef = FirebaseFirestore.instance.collection('wallets').doc(user.uid);
      final walletDoc = await walletRef.get();

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      if (!walletDoc.exists) {
        // Create new wallet if it doesn't exist
        batch.set(walletRef, {
          'kPoints': totalPoints,
          'balance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing wallet
        batch.update(walletRef, {
          'kPoints': FieldValue.increment(totalPoints),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create BNPL document
      final bnplDoc = {
        'userId': user.uid,
        'carId': widget.car['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'carName': '${widget.car['make']} ${widget.car['model']}',
        'pickUpDate': widget.pickUpDate.toIso8601String(),
        'dropOffDate': widget.dropOffDate.toIso8601String(),
        'totalAmount': widget.totalPrice,
        'downPayment': downPayment,
        'installments': installments,
        'status': 'active',
        'planName': plan['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'kPointsEarned': totalPoints,
      };

      // Add BNPL plan
      final planRef = FirebaseFirestore.instance.collection('bnpl_plans').doc();
      batch.set(planRef, bnplDoc);

      // Add transaction record
      final transactionRef = walletRef.collection('transactions').doc();
      batch.set(transactionRef, {
        'amount': -downPayment,
        'description': 'BNPL Down Payment - ${widget.car['make']} ${widget.car['model']}',
        'timestamp': FieldValue.serverTimestamp(),
        'kPoints': totalPoints,
        'type': 'BNPL_DOWN_PAYMENT',
        'planId': planRef.id,
      });

      // Commit all changes
      await batch.commit();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Plan confirmed! You earned $totalPoints K-Points!',
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

      // Verify points were added
      final updatedWallet = await walletRef.get();
      print('Updated K-Points: ${updatedWallet.data()?['kPoints']}');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmation(orderDetails: {
            ...bnplDoc,
            'confirmationType': 'BNPL',
          }),
        ),
      );
    } catch (e) {
      print('Error confirming BNPL plan: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: ${e.toString()}',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add loading state
  bool _isLoading = false;

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan) {
    final dp = widget.totalPrice * plan['down'];
    final monthly = (widget.totalPrice - dp) / plan['months'];
    final basePoints = (widget.totalPrice / 100).floor() * 10;
    final durationBonus = plan['months'] * 5;
    final totalPoints = basePoints + durationBonus;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${plan['months']} months',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                plan['description'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPriceRow('Down Payment', 'EGP ${dp.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _buildPriceRow('Monthly', 'EGP ${monthly.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Earn $totalPoints K-Points',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmPlan(context, plan),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Text('Select Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Choose BNPL Plan'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Installment Plans',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTrustInfo(),
                ...plans.map((plan) => _buildPlanCard(context, plan)).toList(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}