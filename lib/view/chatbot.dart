import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your Kasrawy Group assistant. I can help you with:\n\n'
          '• Understanding digital payments\n'
          '• Explaining escrow and BNPL\n'
          '• Security tips\n'
          '• Building K-Points\n'
          '• Payment methods\n'
          '• Booking rewards\n\n'
          'What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    // Simulate AI response (in a real app, this would call an AI service)
    await Future.delayed(const Duration(seconds: 1));

    String response = _generateResponse(userMessage);

    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('escrow')) {
      return 'Escrow is a secure payment method where your money is held by a trusted third party until you confirm the car pickup. '
          'This protects both you and the car provider. Here\'s how it works:\n\n'
          '1. You make the payment which is held securely\n'
          '2. The car provider confirms the car is ready\n'
          '3. You inspect and accept the car\n'
          '4. The payment is released to the provider\n\n'
          'Benefits:\n'
          '• 100% secure payment\n'
          '• Protection against fraud\n'
          '• 50 K-Points bonus\n'
          '• Dispute resolution support\n\n'
          'Would you like to know more about any specific aspect of escrow?';
    } else if (lowerMessage.contains('bnpl') || lowerMessage.contains('installment')) {
      return 'Buy Now, Pay Later (BNPL) lets you split your payment into manageable installments. Here are our plans:\n\n'
          '1. Smart Plan (3 months)\n'
          '   • 30% down payment\n'
          '   • 3 equal monthly installments\n'
          '   • 15 K-Points bonus\n'
          '   • Perfect for short-term rentals\n\n'
          '2. Flexi Installment (6 months)\n'
          '   • 20% down payment\n'
          '   • 6 equal monthly installments\n'
          '   • 30 K-Points bonus\n'
          '   • Best for long-term rentals\n\n'
          '3. Saver Plan (2 months)\n'
          '   • 50% down payment\n'
          '   • 2 equal monthly installments\n'
          '   • 10 K-Points bonus\n'
          '   • Lowest interest rate\n\n'
          'All plans include:\n'
          '• No hidden fees\n'
          '• Flexible payment dates\n'
          '• Early payment option\n'
          '• 24/7 payment support';
    } else if (lowerMessage.contains('trust') || lowerMessage.contains('points') || lowerMessage.contains('k-points')) {
      return 'K-Points are our loyalty rewards that unlock amazing benefits! Here\'s how to earn them:\n\n'
          'Earning K-Points:\n'
          '• 50 points for using escrow\n'
          '• 10 points per month for BNPL\n'
          '• 25 points for completing your profile\n'
          '• 100 points for referring friends\n'
          '• 10 points per 100 EGP spent\n'
          '• 20 points for booking 7+ days in advance\n'
          '• 30 points for booking luxury vehicles\n'
          '• 40 points for booking during peak seasons\n'
          '• 25 points for repeat bookings within 30 days\n\n'
          'Tiers and Benefits:\n'
          'Bronze (0-99 points)\n'
          '• Basic account features\n'
          '• Standard support\n\n'
          'Silver (100-499 points)\n'
          '• 5% discount on rentals\n'
          '• Priority support\n'
          '• Early access to deals\n\n'
          'Gold (500-999 points)\n'
          '• 10% discount on rentals\n'
          '• VIP support\n'
          '• Free upgrades\n'
          '• Exclusive offers\n\n'
          'Platinum (1000+ points)\n'
          '• 15% discount on rentals\n'
          '• 24/7 concierge service\n'
          '• Free insurance upgrades\n'
          '• Premium vehicle access';
    } else if (lowerMessage.contains('booking') || lowerMessage.contains('book')) {
      return 'Our booking system offers great rewards and flexibility:\n\n'
          'Booking Rewards:\n'
          '• 20 K-Points for booking 7+ days in advance\n'
          '• 30 K-Points for luxury vehicle bookings\n'
          '• 40 K-Points for peak season bookings\n'
          '• 25 K-Points for repeat bookings within 30 days\n\n'
          'Booking Features:\n'
          '• Instant confirmation\n'
          '• Flexible cancellation\n'
          '• Price match guarantee\n'
          '• 24/7 booking support\n\n'
          'Special Offers:\n'
          '• Early bird discounts\n'
          '• Last-minute deals\n'
          '• Weekend specials\n'
          '• Long-term rental packages\n\n'
          'Would you like to know more about:\n'
          '• Specific booking requirements\n'
          '• Cancellation policies\n'
          '• Special offers\n'
          '• Booking process';
    } else if (lowerMessage.contains('secure') || lowerMessage.contains('safe')) {
      return 'Your security is our top priority! Here\'s how we protect you:\n\n'
          'Payment Security:\n'
          '• End-to-end encryption\n'
          '• Secure payment processing\n'
          '• 24/7 fraud monitoring\n'
          '• Dispute resolution support\n'
          '• Regular security audits\n\n'
          'Vehicle Security:\n'
          '• Verified car providers\n'
          '• Vehicle inspection reports\n'
          '• Insurance coverage\n'
          '• 24/7 roadside assistance\n'
          '• Emergency support\n\n'
          'Data Protection:\n'
          '• GDPR compliance\n'
          '• Secure data storage\n'
          '• Privacy controls\n'
          '• Regular security updates';
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('pay')) {
      return 'We offer multiple secure payment options to suit your needs:\n\n'
          '1. Escrow (Most Secure)\n'
          '   • Payment held until car pickup\n'
          '   • 50 K-Points bonus\n'
          '   • Full protection\n\n'
          '2. BNPL (Flexible Installments)\n'
          '   • Multiple payment plans\n'
          '   • Monthly installments\n'
          '   • Points per month\n\n'
          '3. Direct Bank Transfer\n'
          '   • Instant payment\n'
          '   • Bank-level security\n'
          '   • No extra fees\n\n'
          '4. Digital Wallet\n'
          '   • Quick payments\n'
          '   • Save payment methods\n'
          '   • Transaction history\n\n'
          'All payments are processed through secure banking partners with:\n'
          '• 256-bit encryption\n'
          '• PCI DSS compliance\n'
          '• Fraud protection\n'
          '• 24/7 monitoring';
    } else if (lowerMessage.contains('car') || lowerMessage.contains('vehicle')) {
      return 'Our car rental service offers a wide range of vehicles:\n\n'
          'Vehicle Categories:\n'
          '• Economy (Budget-friendly)\n'
          '• Compact (City driving)\n'
          '• SUV (Family trips)\n'
          '• Luxury (Special occasions)\n'
          '• Electric (Eco-friendly)\n\n'
          'Features:\n'
          '• Verified condition\n'
          '• Regular maintenance\n'
          '• Insurance included\n'
          '• 24/7 support\n'
          '• Flexible rental periods\n\n'
          'Would you like to know more about:\n'
          '• Specific vehicle types\n'
          '• Rental requirements\n'
          '• Insurance options\n'
          '• Pickup/dropoff process';
    } else if (lowerMessage.contains('insurance') || lowerMessage.contains('cover')) {
      return 'All our rentals include comprehensive insurance coverage:\n\n'
          'Standard Coverage:\n'
          '• Collision damage waiver\n'
          '• Theft protection\n'
          '• Third-party liability\n'
          '• Roadside assistance\n\n'
          'Premium Options:\n'
          '• Zero deductible\n'
          '• Personal accident cover\n'
          '• Extended coverage\n'
          '• International travel\n\n'
          'Insurance Benefits:\n'
          '• 24/7 claims support\n'
          '• Quick processing\n'
          '• Transparent terms\n'
          '• No hidden fees';
    } else if (lowerMessage.contains('help') || lowerMessage.contains('support')) {
      return 'I\'m here to help! Here are the main topics I can assist with:\n\n'
          '1. Payment & Security\n'
          '   • Escrow payments\n'
          '   • BNPL plans\n'
          '   • Payment methods\n'
          '   • Security features\n\n'
          '2. K-Points & Rewards\n'
          '   • Earning points\n'
          '   • Tier benefits\n'
          '   • Special offers\n'
          '   • Referral program\n\n'
          '3. Vehicle Information\n'
          '   • Car categories\n'
          '   • Rental process\n'
          '   • Insurance options\n'
          '   • Support services\n\n'
          'What would you like to know more about?';
    } else {
      return 'I\'m your Kasrawy Group assistant, here to help you with:\n\n'
          '• Understanding digital payments\n'
          '• Explaining escrow and BNPL\n'
          '• Security and trust features\n'
          '• K-Points and rewards\n'
          '• Vehicle information\n'
          '• Insurance coverage\n'
          '• Support services\n'
          '• Booking rewards\n\n'
          'You can ask me about any of these topics or type "help" for more options.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasrawy Group Assistant'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about digital payments...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const ChatBubble({
    required this.message,
    required this.isUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
} 