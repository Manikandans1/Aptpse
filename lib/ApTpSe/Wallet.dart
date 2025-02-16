import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends StatefulWidget {
  final int earnedPoints;
  const WalletScreen({Key? key, required this.earnedPoints}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}



class _WalletScreenState extends State<WalletScreen> {
  TextEditingController _upiController = TextEditingController();
  TextEditingController _withdrawController = TextEditingController();
  late BannerAd _topBannerAd;
  bool _isTopBannerLoaded = false;
  int earnedPoints = 0; // Stores total points
  final int minWithdrawPoints = 1000; // Minimum ₹10 (1000 points)
  final double transactionFeePercent = 0.02; // 2% fee
  List<Map<String, dynamic>> withdrawalHistory = [];

  @override
  void initState() {
    super.initState();
    _loadBannerAds();
    _loadSavedPoints();
    _loadWithdrawalHistory();
  }

  Future<void> _loadSavedPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      earnedPoints = prefs.getInt('earnedPoints') ?? 0;
    });
  }

  Future<void> _withdrawPoints(int amount) async {
    if (amount > earnedPoints) {
      _showMessage("Not enough points to withdraw!");
      return;
    }

    setState(() {
      earnedPoints -= amount;
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('earnedPoints', earnedPoints);

    _showMessage("$amount points withdrawn!");
  }

  Future<void> _loadWithdrawalHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? historyData = prefs.getString("withdrawal_history");
    if (historyData != null) {
      setState(() {
        withdrawalHistory = List<Map<String, dynamic>>.from(jsonDecode(historyData));
      });
    }
  }

  Future<void> _saveWithdrawalHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("withdrawal_history", jsonEncode(withdrawalHistory));
  }

  void _loadBannerAds() {
    _topBannerAd = BannerAd(
      // adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      adUnitId: 'ca-app-pub-7067890046040375/8161414282',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isTopBannerLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _emailSupport() async {
    final Uri emailUri = Uri(
      scheme: "mailto",
      path: "manimp377@gmail.com",
      queryParameters: {
        "subject": "Support Request",
        "body": "Hello Support Team, I need help with..."
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication); // 👈 Force external app (Gmail)
    } else {
      debugPrint("Could not launch email app.");
    }
  }

  Future<void> _requestWithdrawal() async {
    String upiId = _upiController.text.trim();
    int withdrawPoints = int.tryParse(_withdrawController.text) ?? 0;

    if (upiId.isEmpty) {
      _showMessage("Please enter a valid UPI ID");
      return;
    }

    if (withdrawPoints < minWithdrawPoints || withdrawPoints > earnedPoints) {
      _showMessage("Enter a valid withdrawal amount (Min ₹10 or 1000 points)");
      return;
    }

    double transactionFee = (withdrawPoints / 100) * transactionFeePercent;
    double finalAmount = (withdrawPoints / 100) - transactionFee;

    bool confirmed = await _showConfirmationDialog(finalAmount, transactionFee);
    if (!confirmed) return;

    setState(() {
      earnedPoints -= withdrawPoints;
      withdrawalHistory.insert(0, {
        "upi": upiId,
        "amount": finalAmount.toStringAsFixed(2),
        "transaction_fee": transactionFee.toStringAsFixed(2),
        "status": "Processing",
        "date": DateTime.now().toLocal().toString().split(".")[0],
      });
    });

    await _saveWithdrawalHistory();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('earnedPoints', earnedPoints);

    _showMessage("Withdrawal request submitted! Amount will be transferred in 2 working days.");
  }

  Future<bool> _showConfirmationDialog(double finalAmount, double fee) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Withdrawal"),
        content: Text(
            "Transaction Fee: ₹${fee.toStringAsFixed(2)}\nFinal Amount: ₹${finalAmount.toStringAsFixed(2)}\n\nDo you want to proceed?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Confirm"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _upiController.dispose();
    _withdrawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Wallet 👜",
          style: TextStyle(
            color: Colors.white, // White text color
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.05, // Flexible size
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white), // White back arrow
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isTopBannerLoaded)
                Container(height: 50, child: AdWidget(ad: _topBannerAd)),
              SizedBox(height: 20),
              _walletBalance(),
              SizedBox(height: 20),
              _withdrawSection(),
              SizedBox(height: 30),
              _historySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletBalance() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _walletRow("Total Points:", "$earnedPoints"),
          _walletRow("100 Points:", "₹1.00"),
          _walletRow("Earnings:", "₹${(earnedPoints / 100).toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _walletRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _withdrawSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Enter Your UPI ID"),
        SizedBox(height: 6),
        TextField(
          controller: _upiController,
          decoration: InputDecoration(border: OutlineInputBorder(), hintText: "example@upi"),
        ),
        SizedBox(height: 16),
        Text("Enter Withdrawal Amount (Min ₹10)"),
        SizedBox(height: 6),
        TextField(
          controller: _withdrawController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(border: OutlineInputBorder(), hintText: "1000 (for ₹10)"),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity, // Full width
          child: ElevatedButton(
            onPressed: _requestWithdrawal,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16), // Increased height
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Smooth rounded corners
              ),
              backgroundColor: Colors.orangeAccent, // Attractive color
              shadowColor: Colors.orange.withOpacity(0.5), // Glow effect
              elevation: 10, // 3D effect
            ),
            child: Text(
              "Withdraw",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05, // Flexible text size
                fontWeight: FontWeight.bold,
                color: Colors.black, // White text
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity, // Full width
          child: ElevatedButton(
            onPressed: _emailSupport,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16), // Increased height
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Smooth rounded corners
              ),
              backgroundColor: Colors.orangeAccent, // Attractive color
              shadowColor: Colors.orange.withOpacity(0.5), // Glow effect
              elevation: 10, // 3D effect
            ),
            child: Text(
              "Support Team",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05, // Flexible text size
                fontWeight: FontWeight.bold,
                color: Colors.black, // White text
              ),
            ),
          ),
        )
      ],
    );
  }





  Widget _historySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Withdrawal History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        withdrawalHistory.isEmpty
            ? Text("No withdrawal requests found.")
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: withdrawalHistory.length,
          itemBuilder: (context, index) => _historyItem(withdrawalHistory[index]),
        ),
      ],
    );
  }

  Widget _historyItem(Map<String, dynamic> item) {
    return ListTile(
      title: Text("Amount: ₹${item['amount']}"),
      subtitle: Text("Date: ${item['date']}"),
    );
  }
}
