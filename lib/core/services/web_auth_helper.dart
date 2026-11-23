import 'web_auth_helper_stub.dart'
    if (dart.library.html) 'web_auth_helper_web.dart' as impl;

class WebAuthHelper {
  WebAuthHelper._();

  static Future<bool> isAvailable() => impl.checkWebAuthnAvailable();

  static Future<bool> authenticate(String reason) => impl.performWebAuthn(reason);
}
