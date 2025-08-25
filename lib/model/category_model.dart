// lib/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String categoryId;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int productCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;
  final List<String> tags; // Additional tags for category

  CategoryModel({
    required this.categoryId,
    required this.name,
    required this.description,
    this.icon = '',
    this.color = '#FF6154',
    this.productCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
    this.tags = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'productCount': productCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sortOrder': sortOrder,
      'tags': tags,
    };
  }

  // Create from Firestore Document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      categoryId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '#FF6154',
      productCount: data['productCount']?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      sortOrder: data['sortOrder']?.toInt() ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Create from Map
  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      categoryId: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '#FF6154',
      productCount: map['productCount']?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      sortOrder: map['sortOrder']?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Copy with new values
  CategoryModel copyWith({
    String? categoryId,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? productCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    List<String>? tags,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      productCount: productCount ?? this.productCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
    );
  }

  // Create default categories for Product Hunt
  static List<CategoryModel> getDefaultCategories() {
    DateTime now = DateTime.now();

    return [
      CategoryModel(
        categoryId: 'productivity',
        name: 'Productivity',
        description: 'Tools and apps to boost your productivity',
        icon: '📊',
        color: '#4F46E5',
        createdAt: now,
        updatedAt: now,
        sortOrder: 1,
        tags: ['tools', 'efficiency', 'work'],
      ),
      CategoryModel(
        categoryId: 'developer-tools',
        name: 'Developer Tools',
        description: 'Tools and resources for developers',
        icon: '⚡',
        color: '#059669',
        createdAt: now,
        updatedAt: now,
        sortOrder: 2,
        tags: ['coding', 'development', 'programming'],
      ),
      CategoryModel(
        categoryId: 'design-tools',
        name: 'Design Tools',
        description: 'Creative tools for designers',
        icon: '🎨',
        color: '#DC2626',
        createdAt: now,
        updatedAt: now,
        sortOrder: 3,
        tags: ['design', 'creative', 'graphics'],
      ),
      CategoryModel(
        categoryId: 'ai-ml',
        name: 'AI/Machine Learning',
        description: 'Artificial Intelligence and ML products',
        icon: '🤖',
        color: '#7C3AED',
        createdAt: now,
        updatedAt: now,
        sortOrder: 4,
        tags: ['ai', 'machine-learning', 'automation'],
      ),
      CategoryModel(
        categoryId: 'games',
        name: 'Games',
        description: 'Games and entertainment apps',
        icon: '🎮',
        color: '#EA580C',
        createdAt: now,
        updatedAt: now,
        sortOrder: 5,
        tags: ['gaming', 'entertainment', 'fun'],
      ),
      CategoryModel(
        categoryId: 'health-fitness',
        name: 'Health & Fitness',
        description: 'Health and fitness applications',
        icon: '💪',
        color: '#10B981',
        createdAt: now,
        updatedAt: now,
        sortOrder: 6,
        tags: ['health', 'fitness', 'wellness'],
      ),
      CategoryModel(
        categoryId: 'finance',
        name: 'Finance',
        description: 'Financial tools and services',
        icon: '💰',
        color: '#F59E0B',
        createdAt: now,
        updatedAt: now,
        sortOrder: 7,
        tags: ['money', 'investment', 'banking'],
      ),
      CategoryModel(
        categoryId: 'education',
        name: 'Education',
        description: 'Learning and educational platforms',
        icon: '📚',
        color: '#3B82F6',
        createdAt: now,
        updatedAt: now,
        sortOrder: 8,
        tags: ['learning', 'courses', 'knowledge'],
      ),
    ];
  }

  // Get category by name
  static CategoryModel? getCategoryByName(
    String name,
    List<CategoryModel> categories,
  ) {
    try {
      return categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Filter active categories
  static List<CategoryModel> getActiveCategories(
    List<CategoryModel> categories,
  ) {
    return categories.where((category) => category.isActive).toList();
  }

  @override
  String toString() {
    return 'CategoryModel(categoryId: $categoryId, name: $name, productCount: $productCount, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;
}
