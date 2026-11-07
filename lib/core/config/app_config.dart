class AppConfig {

  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  factory AppConfig.fromEnv(Map<String, String> values) {

    final rawUrl = values['API_BASE_URL']?.trim();

    final String apiBaseUrl = _getApiBaseUrl(rawUrl);
    return AppConfig(apiBaseUrl: apiBaseUrl);
  }


 //valida url exista, tenga estructura valida
  static String _getApiBaseUrl(String? rawUrl) {

    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('Falta configurar API_BASE_URL en el archivo .env.');
    }

    final uri = Uri.tryParse(rawUrl);

    if( uri == null || 
        !uri.hasScheme ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme)
    ){
      throw StateError('API_BASE_URL debe ser una url http valida');
    }

    return (rawUrl.endsWith('/') 
            ? rawUrl.substring(0, rawUrl.length - 1)
            : rawUrl );

  }
}