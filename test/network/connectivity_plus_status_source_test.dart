import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('none以外の接続結果をonline=trueへ変換する', () {
    expect(
      ConnectivityPlusStatusSource.isOnline([ConnectivityResult.none]),
      isFalse,
    );
    expect(
      ConnectivityPlusStatusSource.isOnline([ConnectivityResult.wifi]),
      isTrue,
    );
    expect(
      ConnectivityPlusStatusSource.isOnline([
        ConnectivityResult.none,
        ConnectivityResult.mobile,
      ]),
      isTrue,
    );
  });

  test('onStatusChangedは接続状態変化をbool streamで返す', () async {
    final controller = StreamController<List<ConnectivityResult>>.broadcast();
    final source = ConnectivityPlusStatusSource(
      onConnectivityChanged: () => controller.stream,
    );
    addTearDown(controller.close);

    final values = <bool>[];
    final subscription = source.onStatusChanged.listen(values.add);
    addTearDown(subscription.cancel);

    controller.add([ConnectivityResult.none]);
    controller.add([ConnectivityResult.wifi]);
    controller.add([ConnectivityResult.wifi]); // distinct
    controller.add([ConnectivityResult.mobile]);
    controller.add([ConnectivityResult.none]);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(values, [false, true, false]);
  });
}
