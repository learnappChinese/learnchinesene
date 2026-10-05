class StrokeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double score;

  StrokeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.score = 0.0,
  });
}
