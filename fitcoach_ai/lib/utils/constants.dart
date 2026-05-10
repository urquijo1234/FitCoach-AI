class LLMApiException implements Exception {
  final int statusCode;
  final String message;

  LLMApiException(this.statusCode, this.message);

  @override
  String toString() => 'LLMApiException(statusCode: $statusCode, message: $message)';
}

class LLMJsonParseException implements Exception {
  final String rawResponse;

  LLMJsonParseException(this.rawResponse);

  @override
  String toString() => 'LLMJsonParseException(rawResponse: $rawResponse)';
}

class LLMValidationException implements Exception {
  final String reason;

  LLMValidationException(this.reason);

  @override
  String toString() => 'LLMValidationException(reason: $reason)';
}
