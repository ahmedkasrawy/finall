import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../orderConfirmation.dart';
import '../utils/pricing_utils.dart';

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

  Future<void> _submitEscrowOrder() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank to proceed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Calculate fees and total price
      final feeBreakdown = PricingUtils.calculateFeeBreakdown(
        basePrice: widget.car['price'],
        hasEscrow: true,
        bankFee: 0.02, // Using minimum bank fee
      );

      final totalPrice = feeBreakdown['totalPrice']!;

      // Get user's current K-Points
      final walletDoc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .get();

      final currentKPoints = walletDoc.exists ? (walletDoc.data()?['kPoints'] ?? 0) : 0;

      // Calculate discount from K-Points
      final discount = PricingUtils.calculateDiscount(currentKPoints);
      final finalPrice = PricingUtils.calculateFinalPrice(
        totalPrice: totalPrice,
        kPoints: currentKPoints,
      );

      // Calculate K-Points earned
      final kPointsEarned = PricingUtils.calculateKPoints(
        totalPrice: totalPrice,
        hasEscrow: true,
        hasBnpl: false,
      );

      // Create order details
      final orderDetails = {
        'userId': user.uid,
        'carId': widget.car['id']?.toString() ?? 'unknown_id',
        'carName': ((widget.car['name'] ?? '${widget.car['make'] ?? ''} ${widget.car['model'] ?? ''}').toString().trim().isEmpty
            ? 'Unknown Car'
            : (widget.car['name'] ?? '${widget.car['make'] ?? ''} ${widget.car['model'] ?? ''}')),
        'pricePerDay': widget.car['price'],
        'basePrice': widget.car['price'],
        'totalPrice': totalPrice,
        'finalPrice': finalPrice,
        'feeBreakdown': feeBreakdown,
        'kPointsEarned': kPointsEarned,
        'kPointsUsed': currentKPoints,
        'discountApplied': discount,
        'confirmationType': 'ESCROW',
        'bank': _selectedBank,
        'pickUpDate': widget.pickUpDate.toIso8601String(),
        'dropOffDate': widget.dropOffDate.toIso8601String(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Navigate to order confirmation
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmation(
            orderDetails: orderDetails,
          ),
        ),
      );
    } catch (e) {
      print('Error submitting escrow order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit escrow order: $e'),
          backgroundColor: Colors.red,
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
    final feeBreakdown = PricingUtils.calculateFeeBreakdown(
      basePrice: widget.car['price'],
      hasEscrow: true,
      bankFee: 0.02,
    );

    final totalPrice = feeBreakdown['totalPrice']!;

    // Calculate K-Points earned
    final kPointsEarned = PricingUtils.calculateKPoints(
      totalPrice: totalPrice,
      hasEscrow: true,
      hasBnpl: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow Service'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.car['name'] ?? '${widget.car['make'] ?? ''} ${widget.car['model'] ?? ''}').toString().trim().isEmpty
                              ? 'Unknown Car'
                              : (widget.car['name'] ?? '${widget.car['make'] ?? ''} ${widget.car['model'] ?? ''}'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Base Price', 'EGP ${widget.car['price'].toStringAsFixed(2)}'),
                        _buildDetailRow('Platform Commission', 'EGP ${feeBreakdown['platformCommission']!.toStringAsFixed(2)}'),
                        _buildDetailRow('Escrow Fee', 'EGP ${feeBreakdown['escrowFee']!.toStringAsFixed(2)}'),
                        _buildDetailRow('Bank Fee', 'EGP ${feeBreakdown['bankFee']!.toStringAsFixed(2)}'),
                        const Divider(height: 24),
                        _buildDetailRow('Total Price', 'EGP ${totalPrice.toStringAsFixed(2)}'),
                        _buildDetailRow('K-Points Earned', '+$kPointsEarned points'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Bank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._banks.map((bank) => _buildBankCard(bank)).toList(),
                const SizedBox(height: 24),
                const Text(
                  'How Escrow Works',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEscrowStep(
                  '1. Payment',
                  'You pay the full amount which is held securely in escrow.',
                  Icons.payment,
                ),
                _buildEscrowStep(
                  '2. Verification',
                  'We verify the car and ensure all documents are in order.',
                  Icons.verified_user,
                ),
                _buildEscrowStep(
                  '3. Delivery',
                  'Once verified, the car is delivered to you.',
                  Icons.local_shipping,
                ),
                _buildEscrowStep(
                  '4. Release',
                  'Payment is released to the seller only after you confirm receipt.',
                  Icons.check_circle,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitEscrowOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Proceed with Escrow'),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  margin: EdgeInsets.all(32),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing Escrow Order...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
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
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowStep(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
