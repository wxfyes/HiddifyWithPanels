import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String tradeNo;
  const PaymentWebViewPage({super.key, required this.tradeNo});

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
    final base = HttpService.baseUrl;
    final cashPath = DomainService.cashierPath;
    // 如果路径里已有 trade_no 用 &trade_no= 方式拼接，否则追加参数
    if (cashPath.contains('trade_no=')) {
      return "$base$cashPath${cashPath.contains('?') ? '&' : '?'}trade_no=${widget.tradeNo}";
    }
    // 常见 "#/payment?from=orders" 需要拼接 &trade_no=
    if (cashPath.contains('?')) {
      return "$base$cashPath&trade_no=${widget.tradeNo}";
    }
    // 如 "#/order" 使用 /{trade_no}
    return "$base$cashPath/${widget.tradeNo}";
  }

  Future<void> _bootstrapAndLoad() async {
    final token = await getToken();
    _targetUrl = _buildCashierUrl();
    if (!mounted) return;
    setState(() {});

    // Android 需初始化
    if (Platform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }

    // 尝试打开外部浏览器的兜底函数
    Future<void> _openExternal() async {
      final uri = Uri.parse(_targetUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop();
    }

    // 控制器创建后注入 token
    final initialSettings = InAppWebViewSettings(
      javaScriptEnabled: true,
      transparentBackground: true,
      allowsInlineMediaPlayback: true,
      useOnDownloadStart: true,
      allowsBackForwardNavigationGestures: true,
    );

    final hostWhitelist = DomainService.paymentHosts.map((e) => e.split(':').first).toSet();

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

    // 构建 InAppWebView widget
    final webView = InAppWebView(
      initialSettings: initialSettings,
      initialUrlRequest: URLRequest(url: WebUri(_targetUrl!)),
      onWebViewCreated: (c) async {
        _controller = c;
      },
      onLoadStart: (c, url) async {
        // 在每次 page start 注入 localStorage token
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
        await _openExternal();
      },
      onReceivedHttpError: (c, request, error) async {
        if ((error.statusCode ?? 0) >= 400) await _openExternal();
      },
    );

    if (!mounted) return;
    setState(() {
      // show webview via build
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('支付')),
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
