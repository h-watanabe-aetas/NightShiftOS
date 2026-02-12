import '../domain/auth_state.dart';
import 'auth_gateways.dart';
import 'auth_session_service.dart';

class EmailPasswordLoginUseCase {
  EmailPasswordLoginUseCase({
    required AuthGateway authGateway,
    required ProfileGateway profileGateway,
    required AuthSessionService sessionService,
  })  : _authGateway = authGateway,
        _profileGateway = profileGateway,
        _sessionService = sessionService;

  final AuthGateway _authGateway;
  final ProfileGateway _profileGateway;
  final AuthSessionService _sessionService;

  Future<AuthState> execute({
    required String email,
    required String password,
  }) async {
    final auth = await _authGateway.signInWithEmail(
      email: email,
      password: password,
    );

    final facilityId = await _profileGateway.fetchFacilityId(userId: auth.userId);
    return _sessionService.establishSession(
      staffId: auth.userId,
      facilityId: facilityId,
      accessToken: auth.accessToken,
    );
  }
}
