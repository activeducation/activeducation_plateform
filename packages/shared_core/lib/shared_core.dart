/// Package partagé ActivEducation — shared_core
///
/// Exporte les abstractions communes entre activ_education_app et admin_dashboard.
library shared_core;

// Auth
export 'src/auth/token_storage_interface.dart';
export 'src/auth/auth_interceptor_base.dart';

// Network
export 'src/network/api_base_client.dart';
export 'src/network/api_response.dart';

// Constants
export 'src/constants/api_endpoints_base.dart';
