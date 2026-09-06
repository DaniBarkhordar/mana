import 'package:flutter_test/flutter_test.dart';
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/pp_bluetooth_kit_flutter.dart';
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPpBluetoothKitFlutterPlatform
    with MockPlatformInterfaceMixin {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PPBluetoothKitFlutterPlatform initialPlatform = PPBluetoothKitFlutterPlatform.instance;

  test('$MethodChannelPpBluetoothKitFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPpBluetoothKitFlutter>());
  });

  test('getPlatformVersion', () async {
    expect(await PPBluetoothKitFlutter.getPlatformVersion(), '42');
  });
}
