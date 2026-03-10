import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TawkChatPage extends StatefulWidget {
  const TawkChatPage({super.key});

  @override
  State<TawkChatPage> createState() => _TawkChatPageState();
}

class _TawkChatPageState extends State<TawkChatPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse("https://tawk.to/chat/69a4f86fbf6d5f1c3490f1c9/1jim6ktsp"),
      );
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        appBar: AppBar(title: const Text("Live Support"), centerTitle: true),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),

              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
