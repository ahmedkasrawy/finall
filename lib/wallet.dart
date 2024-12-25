import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();

  String cardNumber = '';
  String cardHolder = '';
  String cvv = '';
  String? expiryMonth;
  String? expiryYear;
  bool showBack = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails(); // Load saved payment details when the screen initializes
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
        title: Text('Payment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Credit Card Preview
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
            // Payment Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
