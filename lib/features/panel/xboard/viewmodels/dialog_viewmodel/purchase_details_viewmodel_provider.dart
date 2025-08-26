// purchase_details_view_model_provider.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/purchase_details_viewmodel.dart';

class PurchaseDetailsViewModelParams {
  final int planId;
  final String? initialPeriod;
  final double? initialPrice;

  PurchaseDetailsViewModelParams({
    required this.planId,
    this.initialPeriod,
    this.initialPrice,
  });
}

final purchaseDetailsViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PurchaseDetailsViewModel, PurchaseDetailsViewModelParams>(
  (ref, params) => PurchaseDetailsViewModel(
    planId: params.planId,
    selectedPeriod: params.initialPeriod,
    selectedPrice: params.initialPrice,
  ),
);
