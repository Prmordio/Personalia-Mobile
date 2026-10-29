import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers.dart';
import '../telemetry/app_telemetry.dart';
import '../../features/home/data/app_api.dart';

class StoreBillingState {
  const StoreBillingState({
    this.products = const [],
    this.busy = false,
    this.canPurchase = false,
    this.error,
    this.success = false,
  });
  final List<ProductDetails> products;
  final bool busy;
  final bool canPurchase;
  final String? error;
  final bool success;
}

typedef StoreErrorReporter =
    void Function(Object error, StackTrace stack, String operation);

class StoreBillingController extends StateNotifier<StoreBillingState> {
  StoreBillingController(
    this._dio,
    this._onVerified, {
    InAppPurchase? store,
    StoreErrorReporter? reportError,
  }) : _store = store ?? InAppPurchase.instance,
       _reportError = reportError ?? AppTelemetry.instance.recoverableError,
       super(const StoreBillingState());
  final Dio _dio;
  final void Function() _onVerified;
  final InAppPurchase _store;
  final StoreErrorReporter _reportError;
  StreamSubscription<List<PurchaseDetails>>? _listener;
  String? _userId;
  String? termsUrl;
  String? privacyUrl;
  Future<void> _queue = Future.value();
  @visibleForTesting
  Future<void> get pendingVerification => _queue;
  String get _provider =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'apple' : 'google';

  Future<void> initialize() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      if (mounted) state = const StoreBillingState(error: 'storeUnavailable');
      return;
    }
    state = StoreBillingState(products: state.products, busy: true);
    try {
      final config = (await _dio.post(
        '/app/store-billing/config',
        data: {'provider': _provider},
      )).data;
      if (!mounted) return;
      _userId = config['userId'] as String;
      termsUrl = config['termsUrl'] as String?;
      privacyUrl = config['privacyUrl'] as String?;
      if (config['enabled'] != true || !await _store.isAvailable())
        throw StateError('Unavailable');
      _listener ??= _store.purchaseStream.listen(
        (purchases) {
          _queue = _queue.then((_) => _process(purchases)).catchError((
            Object _,
          ) {
            if (mounted)
              state = StoreBillingState(
                products: state.products,
                error: 'storeVerificationFailed',
              );
          });
        },
        onError: (Object _) {
          if (mounted)
            state = StoreBillingState(
              products: state.products,
              error: 'storeVerificationFailed',
            );
        },
      );
      final ids = Set<String>.from(config['products'] as List);
      final response = await _store.queryProductDetails(ids);
      if (!mounted) return;
      if (response.error != null ||
          response.notFoundIDs.isNotEmpty ||
          response.productDetails.isEmpty)
        throw StateError('Products unavailable');
      state = StoreBillingState(
        products: response.productDetails,
        canPurchase: config['canPurchase'] == true,
        error: config['canPurchase'] == true ? null : 'storeAlreadyActive',
      );
    } catch (_) {
      if (mounted) state = const StoreBillingState(error: 'storeUnavailable');
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (state.busy || !state.canPurchase || _userId == null) return;
    state = StoreBillingState(products: state.products, busy: true);
    // Etapa da falha, para o Crashlytics dizer onde a loja recusou a compra.
    var stage = 'config';
    try {
      // Recheck access immediately before offering a second recurring payment.
      final config = (await _dio.post(
        '/app/store-billing/config',
        data: {'provider': _provider},
      )).data;
      if (config['canPurchase'] != true || config['userId'] != _userId) {
        if (mounted)
          state = StoreBillingState(
            products: state.products,
            error: 'storeAlreadyActive',
          );
        return;
      }
      if (!mounted) return;
      final allowedIds = Set<String>.from(config['products'] as List);
      if (config['enabled'] != true || !allowedIds.contains(product.id)) {
        throw StateError('Product unavailable');
      }
      stage = 'product';
      // ProductDetails and its offer may become stale while the sheet is open.
      final response = await _store.queryProductDetails({product.id});
      if (!mounted) return;
      if (response.error != null || response.notFoundIDs.contains(product.id)) {
        throw StateError('Product unavailable');
      }
      final freshProduct = response.productDetails.firstWhere(
        (item) => item.id == product.id,
      );
      final products = state.products
          .map((item) => item.id == product.id ? freshProduct : item)
          .toList();
      if (freshProduct.price != product.price ||
          freshProduct.currencyCode != product.currencyCode) {
        // Let the user review a changed price before opening the purchase flow.
        state = StoreBillingState(products: products, canPurchase: true);
        return;
      }
      state = StoreBillingState(products: products, busy: true);
      stage = 'launch';
      final launched = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: freshProduct,
          applicationUserName: _userId,
        ),
      );
      if (!launched) {
        _report('buy_$stage', StateError('not_launched'), StackTrace.current);
      }
      if (!launched && mounted)
        state = StoreBillingState(
          products: state.products,
          canPurchase: true,
          error: 'storeUnavailable',
        );
    } catch (error, stack) {
      _report('buy_$stage', error, stack);
      if (mounted)
        state = StoreBillingState(
          products: state.products,
          canPurchase: true,
          error: 'storeUnavailable',
        );
    }
  }

  Future<void> restore() async {
    if (state.busy || _userId == null || _listener == null) return;
    state = StoreBillingState(products: state.products, busy: true);
    try {
      await _store.restorePurchases(applicationUserName: _userId);
      final result = (await _dio.post('/app/store-billing/refresh')).data;
      _onVerified();
      if (mounted)
        state = StoreBillingState(
          products: state.products,
          canPurchase: result['isValid'] != true,
          success: result['isValid'] == true,
        );
    } catch (_) {
      if (mounted)
        state = StoreBillingState(
          products: state.products,
          error: 'storeVerificationFailed',
        );
    }
  }

  Future<void> _process(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!mounted) return;
      if (purchase.status == PurchaseStatus.pending) {
        state = StoreBillingState(products: state.products, busy: true);
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        if (purchase.status == PurchaseStatus.error) {
          _report(
            'purchase',
            purchase.error ?? StateError('unknown'),
            StackTrace.current,
          );
        }
        state = StoreBillingState(
          products: state.products,
          canPurchase: true,
          error: purchase.status == PurchaseStatus.error
              ? 'storeUnavailable'
              : null,
        );
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final token = _provider == 'apple'
              ? purchase.purchaseID
              : purchase.verificationData.serverVerificationData;
          if (token == null || token.isEmpty)
            throw StateError('Missing transaction');
          final result = (await _dio.post(
            '/app/store-billing/verify',
            data: {'provider': _provider, 'token': token},
          )).data;
          // Never finish a purchase that has not been verified by our backend.
          if (purchase.pendingCompletePurchase)
            await _store.completePurchase(purchase);
          _onVerified();
          if (mounted)
            state = StoreBillingState(
              products: state.products,
              success: result['isValid'] == true,
            );
        } catch (_) {
          if (mounted)
            state = StoreBillingState(
              products: state.products,
              error: 'storeVerificationFailed',
            );
        }
      }
    }
  }

  /// Só código e mensagem do erro da loja (sem token): ex. `storekit_duplicate_product_object`.
  void _report(String stage, Object error, StackTrace stack) {
    final (code, message) = switch (error) {
      PlatformException e => (e.code, e.message),
      IAPError e => (e.code, e.message),
      StateError e => (e.message, null),
      _ => (error.runtimeType.toString(), null),
    };
    final detail = message == null || message.isEmpty
        ? ''
        : ': ${message.length > 120 ? message.substring(0, 120) : message}';
    _reportError(error, stack, 'store_billing_${stage}_$code$detail');
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }
}

final storeBillingProvider =
    StateNotifierProvider<StoreBillingController, StoreBillingState>((ref) {
      return StoreBillingController(
        ref.watch(apiClientProvider).dio,
        () => ref.invalidate(subscriptionProvider),
      );
    });
