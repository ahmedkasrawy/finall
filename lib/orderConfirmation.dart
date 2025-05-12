import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/pricing_utils.dart';

class OrderConfirmation extends StatefulWidget {
  final Map<String, dynamic> orderDetails;

  const OrderConfirmation({super.key, required this.orderDetails});

  @override
  State<OrderConfirmation> createState() => _OrderConfirmationState();
}

class _OrderConfirmationState extends State<OrderConfirmation> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late double totalPrice = 0.0;
  late double discountedPrice = 0.0;
  late double discountAmount = 0.0;
  late double discountPercentage = 0.0;
  bool isLoading = true;
  bool isCancelling = false;
  late Map<String, dynamic> _orderDetails = {};

  @override
  void initState() {
    super.initState();
    _orderDetails = Map<String, dynamic>.from(widget.orderDetails);
    _calculateTotalPrice();
  }

  /// Calculate total price based on price_per_day and booking duration
  Future<void> _calculateTotalPrice() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Calculate base price based on rental duration
      final pickUp = widget.orderDetails['pickUpDate'] != null ? DateTime.parse(widget.orderDetails['pickUpDate']) : null;
      final dropOff = widget.orderDetails['dropOffDate'] != null ? DateTime.parse(widget.orderDetails['dropOffDate']) : null;
      int days = 1;
      if (pickUp != null && dropOff != null) {
        days = dropOff.difference(pickUp).inDays;
        if (days < 1) days = 1;
      }
      final pricePerDay = (widget.orderDetails['pricePerDay'] is int)
          ? (widget.orderDetails['pricePerDay'] as int).toDouble()
          : (widget.orderDetails['pricePerDay'] ?? 0.0) as double;
      final basePrice = pricePerDay * days;

      // Calculate fees
      final feeBreakdown = PricingUtils.calculateFeeBreakdown(
        basePrice: basePrice,
        hasEscrow: widget.orderDetails['confirmationType'] == 'ESCROW',
        hasBnpl: widget.orderDetails['confirmationType'] == 'BNPL',
        bankFee: 0.02,
      );

      final totalPrice = feeBreakdown['totalPrice'] ?? 0.0;

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
        hasEscrow: widget.orderDetails['confirmationType'] == 'ESCROW',
        hasBnpl: widget.orderDetails['confirmationType'] == 'BNPL',
        duration: widget.orderDetails['confirmationType'] == 'BNPL' ? widget.orderDetails['months'] : null,
      );

      setState(() {
        _orderDetails = {
          ...widget.orderDetails,
          'basePrice': basePrice,
          'totalPrice': totalPrice,
          'finalPrice': finalPrice,
          'feeBreakdown': feeBreakdown,
          'kPointsEarned': kPointsEarned,
          'kPointsUsed': currentKPoints,
          'discountApplied': discount,
        };
        isLoading = false;
      });
    } catch (e) {
      print('Error calculating total price: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to calculate total price: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _calculateDiscount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          discountedPrice = totalPrice;
          discountAmount = 0;
          discountPercentage = 0;
          isLoading = false;
        });
        return;
      }

      // Get user's wallet to check K-Points
      final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
      if (!walletDoc.exists) {
        setState(() {
          discountedPrice = totalPrice;
          discountAmount = 0;
          discountPercentage = 0;
          isLoading = false;
        });
        return;
      }

      final kPoints = walletDoc.data()?['kPoints'] ?? 0;

      // Calculate discount based on K-Points level
      if (kPoints >= 1000) {
        discountPercentage = 0.15; // Platinum: 15% discount
      } else if (kPoints >= 500) {
        discountPercentage = 0.10; // Gold: 10% discount
      } else if (kPoints >= 100) {
        discountPercentage = 0.05; // Silver: 5% discount
      } else {
        discountPercentage = 0.0; // Bronze: No discount
      }

      discountAmount = totalPrice * discountPercentage;
      discountedPrice = totalPrice - discountAmount;

      // Add the discounted price to the order details
      _orderDetails['totalPrice'] = discountedPrice;
      _orderDetails['originalPrice'] = totalPrice;
      _orderDetails['discountAmount'] = discountAmount;
      _orderDetails['discountPercentage'] = discountPercentage;

      // Save the order details to Firestore
      await _saveOrderToFirestore();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error calculating discount: $e');
      setState(() {
        discountedPrice = totalPrice;
        discountAmount = 0;
        discountPercentage = 0;
        isLoading = false;
      });
    }
  }

  Future<void> _saveOrderToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Start a batch write
      final batch = _firestore.batch();

      // Create the main order document
      final orderRef = _firestore.collection('orders').doc();
      batch.set(orderRef, {
        ..._orderDetails,
        'orderId': orderRef.id,
      });

      // Update user's wallet with K-Points
      final walletRef = _firestore.collection('wallets').doc(user.uid);
      batch.set(walletRef, {
        'kPoints': FieldValue.increment(_orderDetails['kPointsEarned'] - _orderDetails['kPointsUsed']),
      }, SetOptions(merge: true));

      // Create specific order type document
      switch (_orderDetails['confirmationType']) {
        case 'ESCROW':
          final escrowRef = _firestore.collection('escrow_orders').doc(orderRef.id);
          batch.set(escrowRef, {
            ..._orderDetails,
            'orderId': orderRef.id,
          });
          break;
        case 'BNPL':
          final bnplRef = _firestore.collection('bnpl_orders').doc(orderRef.id);
          batch.set(bnplRef, {
            ..._orderDetails,
            'orderId': orderRef.id,
          });
          break;
        case 'BOOK_NOW':
          final bookingRef = _firestore.collection('bookings').doc(orderRef.id);
          batch.set(bookingRef, {
            ..._orderDetails,
            'orderId': orderRef.id,
          });
          break;
      }

      // Commit the batch
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Error saving order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save the order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelTransaction() async {
    try {
      setState(() {
        isCancelling = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to cancel the transaction')),
        );
        return;
      }

      // Show confirmation dialog
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Transaction'),
          content: const Text('Are you sure you want to cancel this transaction? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, Keep It'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (shouldCancel != true) {
        setState(() {
          isCancelling = false;
        });
        return;
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Get the order reference
      final orderRef = _firestore.collection('orders').doc(_orderDetails['orderId']);

      // Update order status
      batch.update(orderRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': user.uid,
      });

      // If it's a BNPL transaction, update the BNPL plan
      if (_orderDetails['confirmationType'] == 'BNPL') {
        final bnplRef = _firestore.collection('bnpl_plans').doc(_orderDetails['planId']);
        batch.update(bnplRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': user.uid,
        });
      }

      // If it's an escrow transaction, update the escrow order
      if (_orderDetails['confirmationType'] == 'ESCROW') {
        final escrowRef = _firestore.collection('escrow_orders').doc(_orderDetails['orderId']);
        batch.update(escrowRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': user.uid,
        });
      }

      // Add a transaction record for the cancellation
      final transactionRef = _firestore
          .collection('wallets')
          .doc(user.uid)
          .collection('transactions')
          .doc();

      batch.set(transactionRef, {
        'amount': _orderDetails['totalPrice'],
        'description': 'Refund - Cancelled ${_orderDetails['confirmationType']} Transaction',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'REFUND',
        'orderId': _orderDetails['orderId'],
      });

      // Commit the batch
      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Error cancelling transaction: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeBreakdown = _orderDetails['feeBreakdown'] as Map<String, dynamic>? ?? {};
    final basePrice = _orderDetails['basePrice'] as double? ?? 0.0;
    final totalPrice = _orderDetails['totalPrice'] as double? ?? 0.0;
    final finalPrice = _orderDetails['finalPrice'] as double? ?? totalPrice;
    final discount = _orderDetails['discountApplied'] as double? ?? 0.0;
    final kPointsEarned = _orderDetails['kPointsEarned'] as int? ?? 0;
    final kPointsUsed = _orderDetails['kPointsUsed'] as int? ?? 0;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Base Price', 'EGP ${basePrice.toStringAsFixed(2)}'),
                          if (feeBreakdown.isNotEmpty) ...[
                            _buildDetailRow('Platform Commission', 'EGP ${(feeBreakdown['platformCommission'] ?? 0.0).toStringAsFixed(2)}'),
                            if (_orderDetails['confirmationType'] == 'ESCROW')
                              _buildDetailRow('Escrow Fee', 'EGP ${(feeBreakdown['escrowFee'] ?? 0.0).toStringAsFixed(2)}'),
                            if (_orderDetails['confirmationType'] == 'BNPL')
                              _buildDetailRow('BNPL Fee', 'EGP ${(feeBreakdown['bnplFee'] ?? 0.0).toStringAsFixed(2)}'),
                            _buildDetailRow('Bank Fee', 'EGP ${(feeBreakdown['bankFee'] ?? 0.0).toStringAsFixed(2)}'),
                          ],
                          const Divider(height: 24),
                          _buildDetailRow('Total Price', 'EGP ${totalPrice.toStringAsFixed(2)}'),
                          if (discount > 0)
                            _buildDetailRow('Discount Applied', '${(discount * 100).toStringAsFixed(0)}%'),
                          _buildDetailRow('Final Price', 'EGP ${finalPrice.toStringAsFixed(2)}'),
                          const Divider(height: 24),
                          _buildDetailRow('K-Points Used', '-$kPointsUsed points'),
                          _buildDetailRow('K-Points Earned', '+$kPointsEarned points'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Payment Details Card
                  if (_orderDetails['confirmationType'] == 'BNPL') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Plan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Plan', _orderDetails['planName']),
                            _buildDetailRow('Down Payment', 'EGP ${_orderDetails['downPayment'].toStringAsFixed(2)}'),
                            _buildDetailRow('Monthly Installment', 'EGP ${(_orderDetails['installments'][0]['amount'] as double).toStringAsFixed(2)}'),
                            _buildDetailRow('Duration', '${_orderDetails['months']} months'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_orderDetails['confirmationType'] == 'ESCROW') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Escrow Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Bank', _orderDetails['bank']),
                            _buildDetailRow('Status', 'Pending'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveOrderToFirestore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCancelling)
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
                          'Processing Order...',
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}