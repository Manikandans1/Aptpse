import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'Wallet.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int earnedPoints = 0;

  // Initialize _screens with placeholder data (earnedPoints will update later)
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _screens = [
      HomePage(earnedPoints: earnedPoints),
      HomePage(earnedPoints: earnedPoints),
      // VewieAds(),
      // WalletScreen(earnedPoints: earnedPoints),
    ];

    _loadSavedPoints(); // Load points from SharedPreferences
  }

  Future<void> _loadSavedPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      earnedPoints = prefs.getInt('earnedPoints') ?? 0;

      // Update _screens after loading points
      _screens = [
        HomePage(earnedPoints: earnedPoints),
        HomePage(earnedPoints: earnedPoints),
        // HomePage1(earnedPoints: earnedPoints),
        // VewieAds(),
        // WalletScreen(earnedPoints: earnedPoints),
      ];
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppOpenAdManager.showAdIfAvailable();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "APTPSE",
          style: TextStyle(
            color: Colors.white, // White text color
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.05, // Flexible size
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.blue,
      //   selectedItemColor: Colors.white,
      //   unselectedItemColor: Colors.white70,
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   items: [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      //     BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Charts"),
      //     // BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
      //   ],
      // ),
    );
  }
}




class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.earnedPoints}) : super(key: key);
  final int earnedPoints;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BannerAd _topBannerAd;
  bool _isTopBannerLoaded = false;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  int earnedPoints = 0;
  Map<String, int> buttonClicks = {};
  Map<String, bool> isButtonDisabled = {};

  @override
  void initState() {
    super.initState();
    earnedPoints = widget.earnedPoints;
    _loadBannerAds();
    _loadInterstitialAd();
    _loadSavedPoints();
  }

  Future<void> _loadSavedPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      earnedPoints = prefs.getInt('earnedPoints') ?? 0;
    });
  }

  Future<void> _savePoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('earnedPoints', earnedPoints);
  }

  void _withdrawPoints(int amount) async {
    if (amount > earnedPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Not enough points to withdraw!")),
      );
      return;
    }

    setState(() => earnedPoints -= amount);
    await _savePoints();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$amount points withdrawn!")),
    );
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

  // void _loadInterstitialAd() {
  //   InterstitialAd.load(
  //     // adUnitId: 'ca-app-pub-3940256099942544/1033173712',
  //     adUnitId: 'ca-app-pub-7067890046040375/3166709104',
  //     request: AdRequest(),
  //     adLoadCallback: InterstitialAdLoadCallback(
  //       onAdLoaded: (ad) => _interstitialAd = ad,
  //       onAdFailedToLoad: (error) => _interstitialAd = null,
  //     ),
  //   );
  // }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7067890046040375/3166709104', // Replace with your AdMob Ad Unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }




  void _showInterstitialAd(VoidCallback onComplete) {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
      onComplete();
    } else {
      onComplete();
    }
  }


  void _loadRewardedAd(String title, int points) {
    RewardedAd.load(
      // adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      adUnitId: 'ca-app-pub-7067890046040375/5677322375',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _showRewardedAd(title, points);
        },
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void _showRewardedAd(String title, int points) {
    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) {
        setState(() => earnedPoints += points);
        _savePoints();
      },
    );
  }

  // void _handleButtonClick(String title, int points) {
  //   if (isButtonDisabled[title] == true) return;
  //
  //   buttonClicks[title] = (buttonClicks[title] ?? 0) + 1;
  //   if (buttonClicks[title]! >= 5) {
  //     setState(() => isButtonDisabled[title] = true);
  //     Timer(Duration(minutes: 1), () {
  //       setState(() {
  //         buttonClicks[title] = 0;
  //         isButtonDisabled[title] = false;
  //       });
  //     });
  //   }
  //
  //   _showInterstitialAd(() => _loadRewardedAd(title, points));
  // }


  void _handleButtonClick(String title, int points) {
    if (isButtonDisabled[title] == true) return;

    buttonClicks[title] = (buttonClicks[title] ?? 0) + 1;
    if (buttonClicks[title]! >= 5) {
      setState(() => isButtonDisabled[title] = true);
      Timer(Duration(minutes: 1), () {
        setState(() {
          buttonClicks[title] = 0;
          isButtonDisabled[title] = false;
        });
      });
    }
    // Only show the rewarded ad
    _loadRewardedAd(title, points);
  }

  void _navigateToWallet() async {
    if (_isInterstitialAdLoaded) {
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (Ad ad) {
          ad.dispose();  // Dispose the ad after it's closed
          _loadInterstitialAd(); // Load a new ad for next time

          // Navigate to WalletScreen after ad is dismissed
          _goToWalletScreen();
        },
        onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
          ad.dispose();
          _goToWalletScreen(); // Navigate even if the ad fails
        },
      );
    } else {
      // Navigate to WalletScreen immediately if the ad is not loaded
      _goToWalletScreen();
    }
  }

  void _goToWalletScreen() async {
    int updatedPoints = earnedPoints;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WalletScreen(earnedPoints: updatedPoints)),
    );
    _loadSavedPoints();
  }


  // void _navigateToWallet() async {
  //   int updatedPoints = earnedPoints;
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => WalletScreen(earnedPoints: updatedPoints)),
  //   );
  //   _loadSavedPoints();
  // }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonHeight = screenHeight * 0.08; // Responsive button height

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Watch & Earn",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width * 0.05, // Scales text based on screen width
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFff9966), Color(0xFFff5e62)], // Warm red-orange gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), // Dark background for contrast
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amberAccent.withOpacity(0.7), // Golden glow
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Prevent unnecessary width
                children: [
                  Icon(Icons.star, color: Colors.amber, size: MediaQuery.of(context).size.width * 0.06), // Responsive icon
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "$earnedPoints",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05, // Responsive text size
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent, // Shiny gold color
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: _navigateToWallet,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Rounded rectangle shape
                  gradient: LinearGradient(
                    colors: [Color(0xFFffd700), Color(0xFFffa500)], // Gold-Orange gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(2, 3), // 3D shadow effect
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.black, size: MediaQuery.of(context).size.width * 0.06), // Responsive icon
                    SizedBox(width: 6),
                    Text(
                      "Wallet",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05, // Responsive text size
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),


      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isTopBannerLoaded)
                Container(height: 50, child: AdWidget(ad: _topBannerAd)),
              SizedBox(height: 20),
              _buildEarningButton("Watch & Earn", 5, Color(0xFFE91E63), buttonHeight),
              _buildEarningButton("Earn Rewards", 8, Color(0xFFFFA000), buttonHeight),
              _buildEarningButton("Bonus Points", 11, Color(0xFF00C853), buttonHeight),
              _buildEarningButton("Play & Win", 14, Color(0xFF673AB7), buttonHeight),
              _buildEarningButton("Fast Points", 18, Color(0xFFFF1744), buttonHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningButton(String title, int points, Color buttonColor, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity, // Full width
        height: height, // Dynamic button height
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isButtonDisabled[title] == true ? Colors.grey : buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(horizontal: 10),
          ),
          onPressed: isButtonDisabled[title] == true ? null : () => _handleButtonClick(title, points),
          child: FittedBox(
            fit: BoxFit.scaleDown, // Responsive text
            child: Text(
              isButtonDisabled[title] == true ? "$title (Wait 1 min)" : "$title +$points⭐",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05, // Dynamic font size
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
