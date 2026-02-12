import '../domain/auth_state.dart';
import 'auth_gateways.dart';
import 'auth_session_service.dart';

class RestoreSessionUseCase {
  RestoreSessionUseCase({
    required AuthGateway authGateway,
    required ProfileGateway profileGateway,
    required AuthSessionService sessionService,
  })  : _authGateway = authGateway,
        _profileGateway = profileGateway,
        _sessionService = sessionService;

  final AuthGateway _authGateway;
  final ProfileGateway _profileGateway;
  final AuthSessionService _sessionService;

  Future<AuthState> execute() async {
    final session = await _authGateway.currentSession();
    if (session == null) {
      return const AuthState();
    }

    final facilityId =
        await _profileGateway.fetchFacilityId(userId: session.userId);
    return _sessionService.establishSession(
      staffId: session.userId,
      facilityId: facilityId,
      accessToken: session.accessToken,
    );
  }
}
