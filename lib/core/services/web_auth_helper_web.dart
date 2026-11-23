// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js' as js;

Future<bool> checkWebAuthnAvailable() async {
  try {
    if (js.context.hasProperty('isWebAuthnAvailable')) {
      final completer = Completer<bool>();
      final promise = js.context.callMethod('isWebAuthnAvailable', []);
      promise.callMethod('then', [
        (result) => completer.complete(result == true),
        (error) => completer.complete(false),
      ]);
      return await completer.future;
    }
  } catch (_) {}
  return false;
}

Future<bool> performWebAuthn(String reason) async {
  try {
    if (js.context.hasProperty('authenticateWebAuthn')) {
      final completer = Completer<bool>();
      final promise = js.context.callMethod('authenticateWebAuthn', [reason]);
      promise.callMethod('then', [
        (result) => completer.complete(result == true),
        (error) => completer.complete(false),
      ]);
      return await completer.future;
    }
  } catch (_) {}
  return false;
}
