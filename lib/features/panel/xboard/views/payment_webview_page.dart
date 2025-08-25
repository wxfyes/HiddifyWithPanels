import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String tradeNo;
  const PaymentWebViewPage({super.key, required this.tradeNo});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final params = const PlatformWebViewControllerCreationParams();
    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    _controller = controller;
    _bootstrapAndLoad();
  }

  Future<void> _bootstrapAndLoad() async {
    final base = HttpService.baseUrl;
    final token = await getToken();
    final uri = Uri.parse('$base/#/payment?trade_no=${widget.tradeNo}&from=orders');

    // 在加载前注入 token 到 localStorage
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) async {
          if (token != null) {
            await _controller.runJavaScript(
              "try{localStorage.setItem('token','${token.replaceAll("'", "\\'")}');}catch(e){}",
            );
          }
        },
      ),
    );

    // 可选：设置 cookie（部分主题可能读取 cookie）
    if (token != null) {
      try {
        await WebViewCookieManager().setCookie(
          WebViewCookie(
            name: 'token',
            value: token,
            domain: Uri.parse(base).host,
            path: '/',
          ),
        );
      } catch (_) {}
    }

    await _controller.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('支付')), // 本地化可按需接入
      body: WebViewWidget(controller: _controller),
    );
  }
}
