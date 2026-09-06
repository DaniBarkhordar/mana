/// Keeps the local database out of iCloud.
///
/// Personal health data must not ride along in a cloud backup (CLAUDE.md,
/// "Don't"). Android is handled in the manifest (`allowBackup="false"` and
/// data-extraction rules). iOS needs `NSURLIsExcludedFromBackupKey` set on
/// the file itself, which only native code can do — a few lines in
/// `AppDelegate.swift` behind this channel.
library;

import 'dart:io';

import 'package:flutter/services.dart';

class BackupExclusion {
  const BackupExclusion._();

  static const _channel = MethodChannel('com.mananu/files');

  /// Marks [path] as excluded. A no-op off iOS, and quiet on failure: the
  /// database must open even if the flag could not be set, and the runbook's
  /// release checklist verifies the flag on a device.
  static Future<bool> exclude(String path) async {
    if (!Platform.isIOS && !Platform.isMacOS) return true;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'excludeFromBackup',
        {'path': path},
      );
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
