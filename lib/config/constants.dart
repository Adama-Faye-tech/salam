class AppConstants {
  // App Info
  static const String appName = 'SALAM';
  static const String appVersion = '1.0.0';

  // API Endpoints (à remplacer avec vos vraies URLs)
  static const String baseUrl = 'https://api.salam-agri.app';
  static const String equipmentEndpoint = '/api/equipment';
  static const String servicesEndpoint = '/api/services';
  static const String ordersEndpoint = '/api/orders';
  static const String usersEndpoint = '/api/users';
  static const String reviewsEndpoint = '/api/reviews';
  static const String notificationsEndpoint = '/api/notifications';

  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserToken = 'user_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFavorites = 'favorites';
  static const String keyCart = 'cart';

  // Pagination
  static const int defaultPageSize = 20;

  // Distance
  static const double maxDistance = 100.0; // km
  static const double defaultRadius = 50.0; // km

  // Price Ranges
  static const double minPrice = 0;
  static const double maxPrice = 1000000;

  // Categories
  static const List<String> equipmentCategories = [
    'Tracteur',
    'Charrue',
    'Semoir',
    'Moissonneuse',
    'Motoculteur',
    'Remorque',
    'Irrigation',
    'Pulvérisateur',
    'Autre',
  ];

  static const List<String> serviceCategories = [
    'Labour',
    'Semis',
    'Moisson',
    'Transport',
    'Irrigation',
    'Pulvérisation',
    'Fertilisation',
    'Autre',
  ];

  // Time
  static const int notificationCheckInterval = 60; // seconds
  static const int orderRefreshInterval = 30; // seconds

  // Images
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String logoImage = 'assets/images/logo.png';

  // Messages
  static const String noInternetMessage = 'Pas de connexion Internet';
  static const String errorMessage =
      'Une erreur s'
      'est produite';
  static const String successMessage = 'Opération réussie';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 500;
  static const int maxCommentLength = 300;
}
