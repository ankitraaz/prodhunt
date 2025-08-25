class AppConstants {
  // App Info
  static const String appName = 'Product Hunt Clone';
  static const String appVersion = '1.0.0';

  // Default URLs
  static const String defaultProfilePic =
      'https://ui-avatars.com/api/?name=User&background=ff6154&color=fff';
  static const String defaultProductLogo =
      'https://via.placeholder.com/200x200/ff6154/ffffff?text=Logo';

  // File Upload Limits
  static const int maxImageSizeMB = 5;
  static const int maxGalleryImages = 5;
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  // Product Categories
  static const List<String> productCategories = [
    'Productivity',
    'Developer Tools',
    'Design Tools',
    'Games',
    'Health & Fitness',
    'Education',
    'Social Media',
    'E-commerce',
    'Marketing',
    'Finance',
    'Travel',
    'Food & Drink',
    'Music',
    'Video',
    'Photography',
    'Security',
    'AI/ML',
    'Blockchain',
    'IoT',
    'Other',
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Cache Keys
  static const String userProfileCacheKey = 'user_profile';
  static const String categoriesCacheKey = 'categories';

  // Time Limits
  static const Duration cacheTimeout = Duration(minutes: 10);
  static const Duration networkTimeout = Duration(seconds: 30);

  // Product Status
  static const String statusDraft = 'draft';
  static const String statusPublished = 'published';
  static const String statusRejected = 'rejected';
  static const String statusFeatured = 'featured';

  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';

  // Validation Rules
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxBioLength = 500;
  static const int maxProductNameLength = 100;
  static const int maxTaglineLength = 200;
  static const int maxDescriptionLength = 2000;
  static const int maxCommentLength = 1000;

  // Regex Patterns
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
  static const String emailRegex = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';
  static const String urlRegex =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network.';
  static const String authError = 'Authentication failed. Please login again.';
  static const String permissionError =
      'You don\'t have permission to perform this action.';

  // Success Messages
  static const String productCreatedSuccess = 'Product created successfully!';
  static const String profileUpdatedSuccess = 'Profile updated successfully!';
  static const String commentAddedSuccess = 'Comment added successfully!';
}

// Firebase Collection Names
class FirebaseCollections {
  static const String users = 'users';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String upvotes = 'upvotes';
  static const String comments = 'comments';
  static const String notifications = 'notifications';
  static const String reports = 'reports';
  static const String dailyRankings = 'dailyRankings';
}

// Storage Paths
class StoragePaths {
  static const String profilePictures = 'profile_pictures';
  static const String productLogos = 'product_logos';
  static const String productGallery = 'product_gallery';
  static const String temp = 'temp';
}
