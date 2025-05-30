import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:finall/view/chatbot.dart';

class KPointsLevel {
  final String name;
  final int minPoints;
  final double discount;
  final Color color;

  const KPointsLevel({
    required this.name,
    required this.minPoints,
    required this.discount,
    required this.color,
  });
}

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  double _balance = 0.0;
  int _kPoints = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  final List<KPointsLevel> kPointsLevels = const [
    KPointsLevel(
      name: 'Bronze',
      minPoints: 0,
      discount: 0.0,
      color: Colors.brown,
    ),
    KPointsLevel(
      name: 'Silver',
      minPoints: 100,
      discount: 0.05, // 5% discount
      color: Colors.grey,
    ),
    KPointsLevel(
      name: 'Gold',
      minPoints: 500,
      discount: 0.10, // 10% discount
      color: Colors.amber,
    ),
    KPointsLevel(
      name: 'Platinum',
      minPoints: 1000,
      discount: 0.15, // 15% discount
      color: Colors.purple,
    ),
  ];

  KPointsLevel get currentLevel {
    for (var i = kPointsLevels.length - 1; i >= 0; i--) {
      if (_kPoints >= kPointsLevels[i].minPoints) {
        return kPointsLevels[i];
      }
    }
    return kPointsLevels.first;
  }

  int get pointsToNextLevel {
    for (var level in kPointsLevels) {
      if (_kPoints < level.minPoints) {
        return level.minPoints - _kPoints;
      }
    }
    return 0;
  }

  String cardNumber = '';
  String cardHolder = '';
  String cvv = '';
  String? expiryMonth;
  String? expiryYear;
  bool showBack = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadPaymentDetails();
  }

  Future<void> _loadWalletData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final walletDoc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .get();

      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          if (walletDoc.exists) {
            final data = walletDoc.data() as Map<String, dynamic>;
            _balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
            _kPoints = (data['kPoints'] as num?)?.toInt() ?? 0;
          } else {
            _balance = 0.0;
            _kPoints = 0;
          }
          _transactions = transactionsSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildKPointsCard() {
    final nextLevel = _kPoints < kPointsLevels.last.minPoints
        ? kPointsLevels.firstWhere((level) => _kPoints < level.minPoints)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: currentLevel.color),
                const SizedBox(width: 8),
                Text(
                  'K-Points Level: ${currentLevel.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentLevel.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$_kPoints Points',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentLevel.discount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Current Discount: ${(currentLevel.discount * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (nextLevel != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _kPoints / nextLevel.minPoints,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(nextLevel.color),
              ),
              const SizedBox(height: 8),
              Text(
                '${nextLevel.minPoints - _kPoints} points to ${nextLevel.name} level',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestRefund(Map<String, dynamic> transaction) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final shouldRefund = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Refund'),
          content: const Text('Are you sure you want to request a refund for this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Request Refund'),
            ),
          ],
        ),
      );

      if (shouldRefund != true) return;

      // Create refund request
      await FirebaseFirestore.instance
          .collection('refund_requests')
          .add({
        'userId': user.uid,
        'transactionId': transaction['id'],
        'amount': transaction['amount'],
        'description': transaction['description'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'type': transaction['type'],
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh transactions
      _loadWalletData();
    } catch (e) {
      print('Error requesting refund: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request refund: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isPositive = transaction['amount'] > 0;
    final hasPoints = transaction['kPoints'] != null;
    final canRequestRefund = !isPositive && 
        transaction['type'] != 'REFUND' &&
        transaction['type'] != 'REFUND_REQUEST';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          child: Icon(
            isPositive ? Icons.add : Icons.remove,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction['description'] ?? 'Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction['timestamp']?.toDate().toString().split('.')[0] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            if (hasPoints)
              Text(
                '+${transaction['kPoints']} K-Points',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}EGP ${transaction['amount'].toStringAsFixed(2)}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (canRequestRefund)
              TextButton(
                onPressed: () => _requestRefund(transaction),
                child: Text(
                  'Request Refund',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTips() {
    return ExpansionTile(
      title: const Text('Security Tips'),
      leading: const Icon(Icons.security),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTipItem('Never share your CVV with anyone'),
              _buildTipItem('Always check for the secure lock icon in your browser'),
              _buildTipItem('Use strong passwords and enable 2FA'),
              _buildTipItem('Monitor your transactions regularly'),
              _buildTipItem('Report suspicious activity immediately'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// Load payment details from Firestore
  Future<void> _loadPaymentDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-logged-in',
          message: 'User is not logged in.',
        );
      }

      final doc = await FirebaseFirestore.instance
          .collection('payment_details')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          cardNumber = data?['cardNumber'] ?? '';
          cardHolder = data?['cardHolder'] ?? '';
          cvv = data?['cvv'] ?? '';
          expiryMonth = data?['expiryMonth'] ?? '';
          expiryYear = data?['expiryYear'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading payment details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading payment details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Save payment details to Firestore
  Future<void> _savePaymentDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-logged-in',
          message: 'User is not logged in.',
        );
      }

      await FirebaseFirestore.instance
          .collection('payment_details')
          .doc(user.uid)
          .set({
        'cardNumber': cardNumber,
        'cardHolder': cardHolder,
        'cvv': cvv,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment details saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving payment details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving payment details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatBotScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EGP ${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildKPointsCard(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSecurityTips(),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_transactions.isEmpty)
              const Center(
                child: Text('No transactions yet'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) =>
                    _buildTransactionItem(_transactions[index]),
              ),
            const SizedBox(height: 24),
            // Keep existing card input form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showBack = !showBack;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      transitionBuilder: (widget, animation) => RotationTransition(
                        turns: animation,
                        child: widget,
                      ),
                      child: showBack ? _buildCardBack() : _buildCardFront(),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildInputField(
                    label: 'Card Number',
                    hint: 'Enter card number',
                    maxLength: 16,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.length != 16) {
                        return 'Please enter a valid 16-digit card number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        cardNumber = value;
                      });
                    },
                  ),
                  _buildInputField(
                    label: 'Card Holder',
                    hint: 'Enter card holder name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the card holder name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        cardHolder = value;
                      });
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Expiration MM',
                          hint: 'MM',
                          value: expiryMonth,
                          items: List.generate(12, (index) {
                            final month = (index + 1).toString().padLeft(2, '0');
                            return DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              expiryMonth = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Expiration YY',
                          hint: 'YY',
                          value: expiryYear,
                          items: List.generate(10, (index) {
                            final year =
                            (DateTime.now().year + index).toString();
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              expiryYear = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildInputField(
                          label: 'CVV',
                          hint: 'Enter CVV',
                          maxLength: 3,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.length != 3) {
                              return 'Enter a valid 3-digit CVV';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              cvv = value;
                            });
                          },
                          onFocusChange: (hasFocus) {
                            setState(() {
                              showBack = hasFocus;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _savePaymentDetails(); // Save data to Firestore
                        }
                      },
                      child: Text(
                        'Submit',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      key: ValueKey('front'),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [Colors.blueAccent, Colors.cyan]),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.credit_card, color: Colors.yellow, size: 30),
              Text('VISA', style: TextStyle(color: Colors.white, fontSize: 24)),
            ],
          ),
          SizedBox(height: 20),
          Text(
            cardNumber.isEmpty ? '#### #### #### ####' : cardNumber,
            style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARD HOLDER', style: TextStyle(color: Colors.white)),
                  Text(cardHolder.isEmpty ? 'FULL NAME' : cardHolder.toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRES', style: TextStyle(color: Colors.white)),
                  Text(
                    '${expiryMonth ?? 'MM'}/${expiryYear ?? 'YY'}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      key: ValueKey('back'),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [Colors.blueAccent, Colors.cyan]),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            color: Colors.black,
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CVV',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                cvv.isEmpty ? '***' : cvv,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    int? maxLength,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
    FormFieldValidator<String>? validator,
    ValueChanged<bool>? onFocusChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: onChanged,
          onTap: () => onFocusChange?.call(true),
          onEditingComplete: () => onFocusChange?.call(false),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
