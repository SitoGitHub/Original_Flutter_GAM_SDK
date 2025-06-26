import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final List<AdManagerBannerAd> _bannerAds = [];
  final List<bool> _bannerLoadStates = [];

  // Interstitial Ad variables
  AdManagerInterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  final bannerAdUnitId = '/23081467975/beeline_uzbekistan_android/beeline_uz_android_manual_veon_320x50';
  final interstitialAdUnitId = '/23081467975/beeline_uzbekistan_android/beeline_uz_android_universal_interstitial_test2';

  @override
  void initState() {
    super.initState();
    loadInterstitialAd();
  }

  @override
  void dispose() {
    for (final ad in _bannerAds) {
      ad.dispose();
    }
    _interstitialAd?.dispose();
    super.dispose();
  }

  /// Adds a new banner ad without removing existing ones
  void addNewBanner() {
    final newIndex = _bannerAds.length;
    _bannerLoadStates.add(false); // Add loading state

    const size = AdSize(width: 320, height: 50);

    final newAd = AdManagerBannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdManagerAdRequest(),
      sizes: [size],
      listener: AdManagerBannerAdListener(
        onAdImpression: (ad) {
          debugPrint('Banner ad $newIndex impressed');
        },
        onAdLoaded: (ad) {
          debugPrint('Banner ad $newIndex loaded');
          setState(() {
            _bannerLoadStates[newIndex] = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad $newIndex failed to load: $error');
          ad.dispose();
          setState(() {
            _bannerLoadStates.removeAt(newIndex);
            _bannerAds.removeAt(newIndex);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load banner: $error')),
          );
        },
      ),
    )..load();

    setState(() {
      _bannerAds.add(newAd);
    });
  }

  /// Loads an interstitial ad
  void loadInterstitialAd() async {
    AdManagerInterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdManagerAdRequest(),
      adLoadCallback: AdManagerInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          setState(() {
            _isInterstitialAdLoaded = true;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show interstitial ad: $error');
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  /// Shows the interstitial ad
  void showInterstitialAd() {
    if (_interstitialAd != null && _isInterstitialAdLoaded) {
      _interstitialAd!.show();
      setState(() {
        _isInterstitialAdLoaded = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interstitial ad is not ready yet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Scrollable list of banner ads
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 1.2,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward, size: 60, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          '👇 Scroll down for ads 👇',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                for (int i = 0; i < _bannerAds.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _bannerLoadStates[i]
                        ? Container(
                      alignment: Alignment.center,
                      width: _bannerAds[i].sizes.first.width.toDouble(),
                      height: _bannerAds[i].sizes.first.height.toDouble(),
                      child: AdWidget(ad: _bannerAds[i]),
                    )
                        : Container(
                      height: 60,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),

          // Ad control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: showInterstitialAd,
                  child: const Text('Show Fullscreen Ad'),
                ),
                ElevatedButton(
                  onPressed: addNewBanner,
                  child: const Text('Add New Banner'),
                ),
              ],
            ),
          ),

          // Banner counter
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Total banners: ${_bannerAds.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}