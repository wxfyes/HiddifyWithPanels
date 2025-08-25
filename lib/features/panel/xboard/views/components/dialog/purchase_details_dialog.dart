// purchase_details_dialog.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/purchase_details_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/purchase_details_viewmodel_provider.dart';
import 'package:hiddify/features/panel/xboard/views/components/dialog/payment_methods_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/views/payment_webview_page.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

void showPurchaseDialog(
    BuildContext context, Plan plan, Translations t, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PurchaseDetailsDialog(plan: plan, t: t, ref: ref);
    },
  );
}

class PurchaseDetailsDialog extends ConsumerStatefulWidget {
  final Plan plan;
  final Translations t;
  final WidgetRef ref;

  const PurchaseDetailsDialog(
      {super.key, required this.plan, required this.t, required this.ref});

  @override
  _PurchaseDetailsDialogState createState() => _PurchaseDetailsDialogState();
}

class _PurchaseDetailsDialogState extends ConsumerState<PurchaseDetailsDialog> {
  late final PurchaseDetailsViewModelParams _params;
  late final AutoDisposeChangeNotifierProvider<PurchaseDetailsViewModel>
      _provider;

  @override
  void initState() {
    super.initState();

    _params = PurchaseDetailsViewModelParams(
      planId: widget.plan.id,
    );

    _provider = purchaseDetailsViewModelProvider(_params);

    // 初始化选择的价格和周期
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(_provider);
      final cheapestPrice = _findCheapestPrice();
      final cheapestPeriod = _findCheapestPeriod(cheapestPrice);
      if (cheapestPrice != null && cheapestPeriod != null) {
        viewModel.setSelectedPrice(cheapestPrice, cheapestPeriod);
      }
    });
  }

  double? _findCheapestPrice() {
    final prices = [
      widget.plan.monthPrice,
      widget.plan.quarterPrice,
      widget.plan.halfYearPrice,
      widget.plan.yearPrice,
      widget.plan.twoYearPrice,
      widget.plan.threeYearPrice,
      widget.plan.onetimePrice
    ].where((price) => price != null).toList();

    if (prices.isNotEmpty) {
      return prices.reduce((a, b) => a! < b! ? a : b);
    }
    return null;
  }

  String? _findCheapestPeriod(double? cheapestPrice) {
    if (cheapestPrice == null) return null;
    if (widget.plan.monthPrice != null && cheapestPrice == widget.plan.monthPrice) return 'month_price';
    if (widget.plan.quarterPrice != null && cheapestPrice == widget.plan.quarterPrice) return 'quarter_price';
    if (widget.plan.halfYearPrice != null && cheapestPrice == widget.plan.halfYearPrice) return 'half_year_price';
    if (widget.plan.yearPrice != null && cheapestPrice == widget.plan.yearPrice) return 'year_price';
    if (widget.plan.twoYearPrice != null && cheapestPrice == widget.plan.twoYearPrice) return 'two_year_price';
    if (widget.plan.threeYearPrice != null && cheapestPrice == widget.plan.threeYearPrice) return 'three_year_price';
    if (widget.plan.onetimePrice != null && cheapestPrice == widget.plan.onetimePrice) return 'onetime_price';
    return null;
  }

  Widget _buildPriceRadio(
      String label, double price, String period, PurchaseDetailsViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: RadioListTile<String>(
        title: Text(
          '$label: ${price.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
        ),
        value: period,
        groupValue: vm.selectedPeriod,
        onChanged: (String? selected) {
          vm.setSelectedPrice(price, selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(_provider);
    final t = ref.watch(translationsProvider);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.plan.name,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.purchase.subscriptionDuration}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.plan.monthPrice != null)
              _buildPriceRadio(
                widget.t.purchase.monthPrice,
                widget.plan.monthPrice!,
                'month_price',
                viewModel,
              ),
            if (widget.plan.quarterPrice != null)
              _buildPriceRadio(
                widget.t.purchase.quarterPrice,
                widget.plan.quarterPrice!,
                'quarter_price',
                viewModel,
              ),
            if (widget.plan.halfYearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.halfYearPrice,
                widget.plan.halfYearPrice!,
                'half_year_price',
                viewModel,
              ),
            if (widget.plan.yearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.yearPrice,
                widget.plan.yearPrice!,
                'year_price',
                viewModel,
              ),
            if (widget.plan.twoYearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.twoYearPrice,
                widget.plan.twoYearPrice!,
                'two_year_price',
                viewModel,
              ),
            if (widget.plan.threeYearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.threeYearPrice,
                widget.plan.threeYearPrice!,
                'three_year_price',
                viewModel,
              ),
            if (widget.plan.onetimePrice != null)
              _buildPriceRadio(
                widget.t.purchase.onetimePrice,
                widget.plan.onetimePrice!,
                'onetime_price',
                viewModel,
              ),
            const SizedBox(height: 16),
            Text(
              "${t.purchase.total}:${viewModel.selectedPrice != null ? '${viewModel.selectedPrice!.toStringAsFixed(2)} ${widget.t.purchase.rmb}' : widget.t.purchase.noData}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  // 兜底：若出现价格已选但周期丢失的情况，按价格反推周期
                  if (viewModel.selectedPeriod == null && viewModel.selectedPrice != null) {
                    final inferred = _findCheapestPeriod(viewModel.selectedPrice);
                    if (inferred != null) {
                      viewModel.setSelectedPrice(viewModel.selectedPrice, inferred);
                    }
                  }

                  if (viewModel.selectedPrice != null && viewModel.selectedPeriod != null) {
                    final paymentMethods = await viewModel.handleSubscribe();
                    final tradeNo = viewModel.tradeNo;
                    if (tradeNo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.payments.noSuchPlan)),
                      );
                      return;
                    }

                    if (paymentMethods.isNotEmpty) {
                      // 显示支付方式对话框
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return PaymentMethodsDialog(
                            tradeNo: tradeNo,
                            paymentMethods: paymentMethods,
                            totalAmount: viewModel.selectedPrice!,
                            t: widget.t,
                            ref: widget.ref,
                          );
                        },
                      );
                    } else {
                      // 兜底：改为携带 token 直接外部浏览器拉起
                      final token = await getToken();
                      final base = HttpService.baseUrl;
                      final path = DomainService.cashierPath; // '/#/payment?trade_no='
                      final extra = token != null
                          ? '&auth_data=${Uri.encodeComponent(token)}&token=${Uri.encodeComponent(token)}&access_token=${Uri.encodeComponent(token)}'
                          : '';
                      final uri = Uri.parse('$base$path$tradeNo$extra');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.payments.noSuchPlan)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.t.purchase.subscribe,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
