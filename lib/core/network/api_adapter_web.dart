import 'package:dio/browser.dart';

// JSON y Bearer requieren OPTIONS; el backend ya los admite. Dio conserva
// los errores de conexión/CORS aunque desactivemos el aviso por cada petición.
BrowserHttpClientAdapter createApiAdapter() =>
    BrowserHttpClientAdapter(enableCORSWarning: false);
