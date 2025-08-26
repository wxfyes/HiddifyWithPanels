import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  const PaymentWebViewPage({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  InAppWebViewController? _controller;
  String? _targetUrl;

  @override
  void initState() {
    super.initState();
    _bootstrapAndLoad();
  }

  String _buildCashierUrl() {
    // 直接使用传入的支付链接
    return widget.paymentUrl;
  }

  Future<void> _bootstrapAndLoad() async {
    _targetUrl = _buildCashierUrl();

    // 对于支付链接，我们优先在应用内显示，而不是外跳
    // 只有在加载失败时才考虑外跳
    if (kDebugMode) {
      print('PaymentWebViewPage: 准备加载支付链接: $_targetUrl');
    }

    final token = await getToken();
    if (!mounted) return;
    setState(() {});

    if (Platform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }

    Future<void> _openExternal() async {
      final uri = Uri.parse(_targetUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop();
    }

    final initialSettings = InAppWebViewSettings(
      javaScriptEnabled: true,
      transparentBackground: true,
      allowsInlineMediaPlayback: true,
      useOnDownloadStart: true,
      allowsBackForwardNavigationGestures: true,
    );

    final cookieManager = CookieManager.instance();
    if (token != null) {
      try {
        final host = Uri.parse(HttpService.baseUrl).host;
        await cookieManager.setCookie(
          url: WebUri(HttpService.baseUrl),
          name: 'token',
          value: token,
          domain: host,
          path: '/',
        );
      } catch (_) {}
    }

    // 不使用变量 webView，直接由 build 返回 Widget
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 优先在应用内显示支付页面，而不是外跳
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              // 提供外跳选项
              await launchUrl(Uri.parse(_targetUrl!), mode: LaunchMode.externalApplication);
            },
            tooltip: '在外部浏览器中打开',
          ),
        ],
      ),
      body: _targetUrl == null
          ? const Center(child: CircularProgressIndicator())
          : InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_targetUrl!)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                  ),
                  onWebViewCreated: (c) => _controller = c,
                  onLoadStart: (c, url) async {
                    final token = await getToken();
                    if (token != null) {
                      await c.evaluateJavascript(source: "try{localStorage.setItem('token','${token.replaceAll("'", "\\'")}');}catch(e){}");
                    }
                  },
                  onReceivedServerTrustAuthRequest: (c, challenge) async {
                    final host = challenge.protectionSpace.host;
                    final port = challenge.protectionSpace.port ?? 443;
                    final hostPort = "$host:$port";
                    if (DomainService.allowSelfSigned && DomainService.paymentHosts.contains(hostPort)) {
                      return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                    }
                    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
                  },
                  onReceivedError: (c, request, error) async {
                    await launchUrl(Uri.parse(_targetUrl!), mode: LaunchMode.externalApplication);
                    if (mounted) Navigator.of(context).pop();
                  },
                  onReceivedHttpError: (c, request, error) async {
                    if ((error.statusCode ?? 0) >= 400) {
                      await launchUrl(Uri.parse(_targetUrl!), mode: LaunchMode.externalApplication);
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                ),
    );
  }
}
