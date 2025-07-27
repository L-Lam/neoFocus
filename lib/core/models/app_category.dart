class AppCategory {
  final String name;
  final List<String> keywords;
  final bool isProductive;
  final double focusImpact; // -1.0 to 1.0 (negative = distracting)

  const AppCategory({
    required this.name,
    required this.keywords,
    required this.isProductive,
    required this.focusImpact,
  });
}

class AppCategories {
  static const List<AppCategory> categories = [
    // Productive apps
    AppCategory(
      name: 'Development',
      keywords: [
        'code',
        'visual studio',
        'android studio',
        'xcode',
        'terminal',
        'git',
      ],
      isProductive: true,
      focusImpact: 1.0,
    ),
    AppCategory(
      name: 'Productivity',
      keywords: ['notion', 'obsidian', 'calendar', 'todo', 'task', 'notes'],
      isProductive: true,
      focusImpact: 0.8,
    ),
    AppCategory(
      name: 'Education',
      keywords: [
        'coursera',
        'udemy',
        'khan',
        'learn',
        'study',
        'book',
        'reader',
      ],
      isProductive: true,
      focusImpact: 0.9,
    ),
    AppCategory(
      name: 'Work',
      keywords: ['slack', 'teams', 'zoom', 'meet', 'office', 'docs', 'sheets'],
      isProductive: true,
      focusImpact: 0.7,
    ),

    // Distracting apps
    AppCategory(
      name: 'Social Media',
      keywords: [
        'facebook',
        'instagram',
        'twitter',
        'tiktok',
        'snapchat',
        'reddit',
      ],
      isProductive: false,
      focusImpact: -1.0,
    ),
    AppCategory(
      name: 'Entertainment',
      keywords: ['youtube', 'netflix', 'spotify', 'twitch', 'gaming', 'video'],
      isProductive: false,
      focusImpact: -0.9,
    ),
    AppCategory(
      name: 'Shopping',
      keywords: ['amazon', 'ebay', 'shop', 'store', 'buy', 'cart'],
      isProductive: false,
      focusImpact: -0.7,
    ),
    AppCategory(
      name: 'News',
      keywords: ['news', 'reddit', 'medium', 'blog', 'article'],
      isProductive: false,
      focusImpact: -0.5,
    ),
  ];

  static AppCategory categorizeApp(String appName) {
    final lowerName = appName.toLowerCase();

    for (final category in categories) {
      for (final keyword in category.keywords) {
        if (lowerName.contains(keyword)) {
          return category;
        }
      }
    }

    // Default to neutral
    return const AppCategory(
      name: 'Other',
      keywords: [],
      isProductive: true,
      focusImpact: 0.0,
    );
  }
}
