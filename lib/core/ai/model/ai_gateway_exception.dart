enum AiGatewayErrorCode {
  authenticationRequired,
  quotaExceeded,
  invalidInput,
  aiTemporarilyUnavailable,
  emptyResponse,
  unknown;

  static AiGatewayErrorCode fromString(String? code) {
    switch (code) {
      case 'authentication_required':
        return AiGatewayErrorCode.authenticationRequired;
      case 'quota_exceeded':
        return AiGatewayErrorCode.quotaExceeded;
      case 'invalid_input':
      case 'invalid_action':
        return AiGatewayErrorCode.invalidInput;
      case 'ai_temporarily_unavailable':
        return AiGatewayErrorCode.aiTemporarilyUnavailable;
      case 'empty_response':
        return AiGatewayErrorCode.emptyResponse;
      default:
        return AiGatewayErrorCode.unknown;
    }
  }
}

class AiGatewayException implements Exception {
  const AiGatewayException({
    required this.code,
    required this.message,
    this.details,
  });

  final AiGatewayErrorCode code;
  final String message;
  final dynamic details;

  bool get isQuotaExceeded => code == AiGatewayErrorCode.quotaExceeded;
  bool get isAuthRequired => code == AiGatewayErrorCode.authenticationRequired;

  @override
  String toString() => 'AiGatewayException($code): $message';
}
