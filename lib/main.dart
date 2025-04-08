import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(NoReelsApp());
}

class NoReelsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'No Reels Instagram',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: InstagramWrapper(),
    );
  }
}

class InstagramWrapper extends StatefulWidget {
  @override
  _InstagramWrapperState createState() => _InstagramWrapperState();
}

class _InstagramWrapperState extends State<InstagramWrapper> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  final String motivationalMessage = '''
    <html>
      <head>
        <style>
          body {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            font-family: sans-serif;
            text-align: center;
            background-color: #fafafa;
            margin: 0;
            padding: 20px;
          }
          .container {
            max-width: 600px;
            padding: 30px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          }
          h2 {
            color: #262626;
            margin-bottom: 20px;
          }
          p {
            color: #8e8e8e;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h2>Stay Focused! 🚀</h2>
          <p>Reels are blocked to help you stay productive and maintain your focus. You're doing great!</p>
        </div>
      </body>
    </html>
  ''';

  final String blockReelsScript = '''
    function blockReels() {
      // Remove reels from the feed
      const reels = document.querySelectorAll('a[href*="/reels/"], a[href*="/reel/"]');
      reels.forEach(reel => {
        const parent = reel.closest('article, div[role="button"]');
        if (parent) {
          parent.style.display = 'none';
        }
      });

      // Block reels player
      const reelsPlayer = document.querySelector('video[src*="reels"]');
      if (reelsPlayer) {
        reelsPlayer.pause();
        reelsPlayer.style.display = 'none';
        const container = reelsPlayer.closest('div[role="presentation"]');
        if (container) {
          container.style.display = 'none';
        }
      }

      // Block reels tab
      const reelsTab = document.querySelector('a[href*="/reels/"]');
      if (reelsTab) {
        reelsTab.style.display = 'none';
      }

      // Block reels in explore
      const exploreReels = document.querySelectorAll('div[role="tablist"] a[href*="/reels/"]');
      exploreReels.forEach(reel => {
        reel.style.display = 'none';
      });
    }

    // Run immediately
    blockReels();

    // Run periodically to catch dynamically loaded content
    setInterval(blockReels, 1000);

    // Block reels navigation
    document.addEventListener('click', function(e) {
      const target = e.target.closest('a[href*="/reels/"], a[href*="/reel/"]');
      if (target) {
        e.preventDefault();
        e.stopPropagation();
        alert('Reels are blocked to help you stay focused!');
      }
    }, true);
  ''';

  bool _isReelsUrl(String url) {
    final reelsPatterns = [
      '/reels',
      '/explore/reels',
      '/reels/',
      '/p/.*/reel/',
      '/stories/highlights/.*/reels/',
    ];
    return reelsPatterns.any((pattern) => url.contains(pattern));
  }

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url;
                if (_isReelsUrl(url)) {
                  _controller.loadHtmlString(motivationalMessage);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              },
              onPageFinished: (String url) {
                _controller.runJavaScript(blockReelsScript);
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse('https://www.instagram.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load Instagram',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _controller.reload();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RefreshController {
  Future<void> refresh() async {
    // This is a placeholder for the refresh controller
    // The actual refresh is handled by the WebViewController
  }
}
