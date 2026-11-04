import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Google OAuth 2.0 sign-in for Drive appDataFolder backup.
/// Scopes: email + Drive appData only (app can only see its own hidden folder).
class GoogleAuthService {
  final GoogleSignIn _signIn = GoogleSignIn(scopes: ['email', drive.DriveApi.driveAppdataScope]);
  GoogleSignInAccount? get currentUser => _signIn.currentUser;
  Stream<GoogleSignInAccount?> get onUserChanged => _signIn.onCurrentUserChanged;
  Future<GoogleSignInAccount?> signIn() => _signIn.signIn();
  Future<GoogleSignInAccount?> signInSilently() => _signIn.signInSilently();
  Future<void> signOut() => _signIn.signOut();
  Future<AuthenticatedClient?> authenticatedClient() async {
    final user = _signIn.currentUser ?? await _signIn.signInSilently();
    if (user == null) return null;
    final headers = await user.authHeaders;
    return AuthenticatedClient(http.Client(), headers);
  }
}

class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient(this._inner, this._headers);
  final http.Client _inner; final Map<String, String> _headers;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) { request.headers.addAll(_headers); return _inner.send(request); }
  @override
  void close() => _inner.close();
}
