enum AreaCatalogFailure {
  timeout,
  connection,
  notFound,
  server,
  http,
  invalidResponse,
  unknown,
}

final class AreaCatalogFailureException implements Exception {
  const AreaCatalogFailureException(this.failure);

  final AreaCatalogFailure failure;
}
