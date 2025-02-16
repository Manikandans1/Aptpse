import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ApTpSe/Home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  AppOpenAdManager.loadAd(); // Load App Open Ad at startup
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Delay ad display for 5 seconds after app launch
    Future.delayed(Duration(seconds: 5), () {
      AppOpenAdManager.showAdIfAvailable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TapSee',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}


// App Open Ad Manager
class AppOpenAdManager {
  static AppOpenAd? _appOpenAd;

  // Load App Open Ad
  static void loadAd() {
    AppOpenAd.load(
      // adUnitId: 'ca-app-pub-3940256099942544/9257395921', // Test Ad Unit ID
      adUnitId: 'ca-app-pub-7067890046040375/4527353232',
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ App Open Ad Loaded Successfully");
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          print("❌ Failed to load App Open Ad: $error");
        },
      ),
      orientation: AppOpenAd.orientationPortrait, // Ensure correct orientation
    );
  }

  // Show App Open Ad when available
  static void showAdIfAvailable() {
    if (_appOpenAd != null) {
      print("📢 Showing App Open Ad...");
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print("✅ App Open Ad Dismissed");
          ad.dispose();
          _appOpenAd = null;
          loadAd(); // Load new ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print("❌ Failed to Show App Open Ad: $error");
          ad.dispose();
          _appOpenAd = null;
          loadAd();
        },
      );
      _appOpenAd!.show(); // 🚀 Show Ad
      _appOpenAd = null;  // Clear after showing
    } else {
      print("⚠ App Open Ad Not Available");
      loadAd();  // Reload if not available
    }
  }
}

