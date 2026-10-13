import 'package:local_auth/local_auth.dart';

/// Result of a fingerprint check. Anything other than [success] falls back
/// to the app PIN and must not block My Health.
enum BiometricResult {
  success,
  unavailable,
  notEnrolled,
  cancelled,
  lockout,
  failed,
}

/// On-device fingerprint or face check. Tests pass a fake.
abstract class BiometricAuthenticator {
  Future<bool> isAvailable();
  Future<BiometricResult> authenticate();
}

/// Used when no authenticator is injected. Never touches the platform.
class UnavailableBiometricAuthenticator implements BiometricAuthenticator {
  const UnavailableBiometricAuthenticator();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricResult> authenticate() async => BiometricResult.unavailable;
}

/// Maps plugin failure codes. New codes stay a PIN fallback.
BiometricResult biometricResultForException(LocalAuthExceptionCode code) {
  switch (code) {
    case LocalAuthExceptionCode.noBiometricHardware:
    case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
    case LocalAuthExceptionCode.uiUnavailable:
      return BiometricResult.unavailable;
    case LocalAuthExceptionCode.noBiometricsEnrolled:
    case LocalAuthExceptionCode.noCredentialsSet:
      return BiometricResult.notEnrolled;
    case LocalAuthExceptionCode.temporaryLockout:
    case LocalAuthExceptionCode.biometricLockout:
      return BiometricResult.lockout;
    case LocalAuthExceptionCode.userCanceled:
    case LocalAuthExceptionCode.systemCanceled:
    case LocalAuthExceptionCode.timeout:
    case LocalAuthExceptionCode.userRequestedFallback:
      return BiometricResult.cancelled;
    default:
      return BiometricResult.failed;
  }
}

/// Wraps [LocalAuthentication]. Errors become a PIN fallback, never a block.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricResult> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Open My Health',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (error) {
      return biometricResultForException(error.code);
    } catch (_) {
      return BiometricResult.failed;
    }
  }
}
