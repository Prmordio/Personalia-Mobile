import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:personalia_app/core/billing/store_billing_controller.dart';

class _Store implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  int completed = 0;
  String? account;
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
  ) async => ProductDetailsResponse(productDetails: [product], notFoundIDs: []);
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    account = purchaseParam.applicationUserName;
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
  setUp(() async {
    store = _Store();
    backend = _Backend();
    verified = false;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = backend;
    controller = StoreBillingController(
      dio,
      () => verified = true,
      store: store,
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
}
