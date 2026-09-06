import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_method_channel.dart';

void main() {
  MethodChannelPpBluetoothKitFlutter platform = MethodChannelPpBluetoothKitFlutter();
  const MethodChannel channel = MethodChannel('pp_bluetooth_kit_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
