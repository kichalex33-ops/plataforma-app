import 'app_auth_models.dart';
import 'auth_api_service.dart';
import 'secure_session_storage.dart';

typedef AuthFallback =
    Future<AuthApiLoginResult> Function({
      required String login,
      required String senha,
    });

class PanelAuthService {
  static const permissionDeniedMessage =
      PanelAuthMessages.permissionDeniedMessage;

  final AuthApiService apiService;
  final SecureSessionStorage sessionStorage;
  final AuthFallback? fallback;
  AppUser? _lastAuthenticatedUser;

  PanelAuthService({
    AuthApiService? apiService,
    SecureSessionStorage? sessionStorage,
    this.fallback,
  }) : apiService = apiService ?? AuthApiService(),
       sessionStorage = sessionStorage ?? const SecureSessionStorage();

  Future<AuthResult> authenticate({
    required String login,
    required String senha,
  }) async {
    final result = await _authenticateWithApiOrFallback(
      login: login,
      senha: senha,
    );
    if (!result.authResult.allowed || result.authResult.user == null) {
      return result.authResult;
    }

    final user = result.authResult.user!;
    if (!user.temPermissaoAtiva) {
      return const AuthResult.denied(permissionDeniedMessage);
    }

    _lastAuthenticatedUser = user;
    final token = result.token;
    if (token != null && token.trim().isNotEmpty) {
      await sessionStorage.save(
        user: user,
        token: token,
        refreshToken: result.refreshToken,
      );
    }
    return AuthResult.allowed(user);
  }

  Future<AppUser?> userByLogin(String login) async {
    final session = await sessionStorage.load();
    if (session?.user.login.trim().toLowerCase() ==
        login.trim().toLowerCase()) {
      return session!.user;
    }
    if (_lastAuthenticatedUser?.login.trim().toLowerCase() ==
        login.trim().toLowerCase()) {
      return _lastAuthenticatedUser;
    }
    return null;
  }

  Future<bool> alterarSenha({
    required String login,
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    final nova = novaSenha.trim();
    if (nova != confirmarNovaSenha.trim()) {
      throw const AuthValidationException('As senhas nao conferem.');
    }
    if (!_senhaForte(nova)) {
      throw const AuthValidationException(
        'A nova senha deve ter pelo menos 6 caracteres, letras e numeros.',
      );
    }

    final session = await sessionStorage.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const AuthValidationException(
        'Sessao expirada. Entre novamente para alterar a senha.',
      );
    }

    try {
      await apiService.changePassword(
        token: session.token,
        senhaAtual: senhaAtual.trim(),
        novaSenha: nova,
      );
      final updatedUser = session.user.copyWith(primeiroAcesso: false);
      await sessionStorage.save(
        user: updatedUser,
        token: session.token,
        refreshToken: session.refreshToken,
      );
      _lastAuthenticatedUser = updatedUser;
      return true;
    } on AuthApiException catch (error) {
      throw AuthValidationException(error.message);
    }
  }

  Future<AuthApiLoginResult> _authenticateWithApiOrFallback({
    required String login,
    required String senha,
  }) async {
    try {
      return await apiService.login(login: login.trim(), senha: senha.trim());
    } catch (_) {
      if (fallback != null) {
        return fallback!(login: login.trim(), senha: senha.trim());
      }
      rethrow;
    }
  }

  bool _senhaForte(String senha) {
    final hasMinLength = senha.length >= 6;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(senha);
    final hasNumber = RegExp(r'\d').hasMatch(senha);
    return hasMinLength && hasLetter && hasNumber;
  }
}
