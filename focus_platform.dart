import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

/// Jembatan ke sistem operasi: membaca aplikasi/jendela yang sedang aktif.
/// Android -> nama package (via UsageStatsManager di Kotlin).
/// Windows -> judul jendela aktif (judul tab browser memuat nama website).
class FocusPlatform {
  static const _ch = MethodChannel('satudulu/focus');

  static Future<bool> hasPermission() async =>
      Platform.isAndroid ? (await _ch.invokeMethod<bool>('hasUsagePermission') ?? false) : true;

  static Future<void> openPermissionSettings() async {
    if (Platform.isAndroid) await _ch.invokeMethod('openUsageSettings');
  }

  static Future<String> foreground() async {
    if (Platform.isAndroid) return await _ch.invokeMethod<String>('foregroundPackage') ?? '';
    if (Platform.isWindows) {
      final buf = wsalloc(512);
      try {
        GetWindowText(GetForegroundWindow(), buf, 512);
        return buf.toDartString();
      } finally {
        free(buf);
      }
    }
    return '';
  }

  static Future<void> bringToFront() async {
    if (Platform.isAndroid) {
      await _ch.invokeMethod('bringToFront');
    } else if (Platform.isWindows) {
      await windowManager.show();
      await windowManager.focus();
    }
  }
}
