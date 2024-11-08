
class SubaddressingException implements Exception {
  final String message;

  SubaddressingException(this.message);

  @override
  String toString() => 'SubaddressingException: $message';
}
