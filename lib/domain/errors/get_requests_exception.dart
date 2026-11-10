final class GetRequestsException implements Exception {
  const GetRequestsException(this.message);

  final String message;

  @override
  String toString() => message;
}
