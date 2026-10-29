import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:personalia_app/core/billing/store_billing_controller.dart';

class _Store implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  int completed = 0;
  int purchasesStarted = 0;
  String? account;
  ProductDetails? purchasedProduct;
  ProductDetails? refreshedProduct;
  bool unavailable = false;
  Object? buyError;
  final product = ProductDetails(
    id: 'monthly',
    title: 'Monthly',
    description: 'Monthly subscription',
    price: 'R\$ 24,90',
    rawPrice: 24.9,
    currencyCode: 'BRL',
  );
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: unavailable ? [] : [refreshedProduct ?? product],
    notFoundIDs: unavailable ? identifiers.toList() : [],
  );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    if (buyError != null) throw buyError!;
    purchasesStarted++;
    account = purchaseParam.applicationUserName;
    purchasedProduct = purchaseParam.productDetails;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed++;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Backend implements HttpClientAdapter {
  int verifyStatus = 200;
  bool canPurchase = true;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.path.endsWith('/config')
        ? {
            'enabled': true,
            'userId': 'owner',
            'products': ['monthly'],
            'canPurchase': canPurchase,
          }
        : {'isValid': true};
    return ResponseBody.fromString(
      jsonEncode(body),
      options.path.endsWith('/verify') ? verifyStatus : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Store store;
  late _Backend backend;
  late StoreBillingController controller;
  late bool verified;
  late List<String> reported;
  setUp(() async {
    reported = [];
    store = _Store();
    backend = _Backend();
    verified = false;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = backend;
    controller = StoreBillingController(
      dio,
      () => verified = true,
      store: store,
      reportError: (_, _, operation) => reported.add(operation),
    );
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
    await store.events.close();
  });
  PurchaseDetails purchase() => PurchaseDetails(
    purchaseID: '123',
    productID: 'monthly',
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: 'token',
      source: 'google_play',
    ),
    transactionDate: '0',
    status: PurchaseStatus.purchased,
  )..pendingCompletePurchase = true;
  test('reports the store code when the purchase cannot start', () async {
    store.buyError = PlatformException(
      code: 'storekit_duplicate_product_object',
      message:
          'There is a pending transaction for the same product identifier.',
    );
    await controller.buy(store.product);
    expect(controller.state.error, 'storeUnavailable');
    expect(reported, [
      'store_billing_buy_launch_storekit_duplicate_product_object: '
          'There is a pending transaction for the same product identifier.',
    ]);
  });
  test('reports the store code of a failed purchase', () async {
    store.events.add([
      PurchaseDetails(
          productID: 'monthly',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'app_store',
          ),
          transactionDate: '0',
          status: PurchaseStatus.error,
        )
        ..error = IAPError(
          source: 'app_store',
          code: 'storekit2_purchase_failed',
          message: 'failed',
        ),
    ]);
    await controller.pendingVerification;
    expect(controller.state.error, 'storeUnavailable');
    expect(reported, [
      'store_billing_purchase_storekit2_purchase_failed: failed',
    ]);
  });
  test('finishes a purchase the backend definitively rejected', () async {
    backend.verifyStatus = 409;
    store.events.add([purchase()]);
    await controller.pendingVerification;
    expect(store.completed, 1);
    expect(verified, false);
    expect(controller.state.error, 'storeVerificationFailed');
    expect(controller.state.canPurchase, true);
    expect(reported, ['store_billing_verify_http_409']);
  });
  test('keeps the purchase pending when the session expired', () async {
    backend.verifyStatus = 401;
    store.events.add([purchase()]);
    await controller.pendingVerification;
    expect(store.completed, 0);
    expect(controller.state.error, 'storeVerificationFailed');
  });
  test('does not finish an unverified purchase', () async {
    backend.verifyStatus = 500;
    store.events.add([purchase()]);
    await controller.pendingVerification;
    expect(store.completed, 0);
    expect(verified, false);
    expect(controller.state.error, 'storeVerificationFailed');
  });
  test(
    'finishes only after server verification and refreshes access',
    () async {
      store.events.add([purchase()]);
      await controller.pendingVerification;
      expect(store.completed, 1);
      expect(verified, true);
      expect(controller.state.success, true);
    },
  );
  test('binds the store purchase to the authenticated account', () async {
    await controller.buy(store.product);
    expect(store.account, 'owner');
  });
  test('rechecks existing access before another subscription', () async {
    backend.canPurchase = false;
    await controller.buy(store.product);
    expect(store.account, isNull);
    expect(controller.state.error, 'storeAlreadyActive');
  });
  test(
    'uses fresh store details rather than the displayed cached object',
    () async {
      store.refreshedProduct = ProductDetails(
        id: 'monthly',
        title: 'Fresh Monthly',
        description: 'Fresh offer',
        price: store.product.price,
        rawPrice: 24.9,
        currencyCode: 'BRL',
      );
      await controller.buy(store.product);
      expect(store.purchasedProduct, same(store.refreshedProduct));
    },
  );
  test('does not launch a product the store no longer offers', () async {
    store.unavailable = true;
    await controller.buy(store.product);
    expect(store.purchasedProduct, isNull);
    expect(controller.state.error, 'storeUnavailable');
  });
  test('shows a changed price for review before purchase', () async {
    store.refreshedProduct = ProductDetails(
      id: 'monthly',
      title: 'Monthly',
      description: 'Subscription',
      price: 'R\$ 29,90',
      rawPrice: 29.9,
      currencyCode: 'BRL',
    );
    await controller.buy(store.product);
    expect(store.purchasedProduct, isNull);
    expect(controller.state.products.single.price, 'R\$ 29,90');
    expect(controller.state.canPurchase, true);
  });
  test('serializes taps while checking access and store details', () async {
    final first = controller.buy(store.product);
    final second = controller.buy(store.product);
    await Future.wait([first, second]);
    expect(store.purchasesStarted, 1);
    expect(store.purchasedProduct, same(store.product));
    expect(controller.state.busy, true);
  });
}
