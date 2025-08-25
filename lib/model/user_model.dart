import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String username;
  final String email;
  final String displayName;
  final String profilePicture;
  final String bio;
  final String website;
  final String twitter;
  final String linkedin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int reputation;
  final int totalUpvotes;
  final bool isVerified;
  final String role;
  final List<String> following;
  final List<String> followers;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    this.profilePicture = '',
    this.bio = '',
    this.website = '',
    this.twitter = '',
    this.linkedin = '',
    required this.createdAt,
    required this.updatedAt,
    this.reputation = 0,
    this.totalUpvotes = 0,
    this.isVerified = false,
    this.role = 'user',
    this.following = const [],
    this.followers = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'displayName': displayName,
      'profilePicture': profilePicture,
      'bio': bio,
      'website': website,
      'twitter': twitter,
      'linkedin': linkedin,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reputation': reputation,
      'totalUpvotes': totalUpvotes,
      'isVerified': isVerified,
      'role': role,
      'following': following,
      'followers': followers,
    };
  }

  // Create from Firestore Document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      bio: data['bio'] ?? '',
      website: data['website'] ?? '',
      twitter: data['twitter'] ?? '',
      linkedin: data['linkedin'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      reputation: data['reputation']?.toInt() ?? 0,
      totalUpvotes: data['totalUpvotes']?.toInt() ?? 0,
      isVerified: data['isVerified'] ?? false,
      role: data['role'] ?? 'user',
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }

  // Copy with new values
  UserModel copyWith({
    String? username,
    String? displayName,
    String? profilePicture,
    String? bio,
    String? website,
    String? twitter,
    String? linkedin,
    int? reputation,
    int? totalUpvotes,
    bool? isVerified,
    List<String>? following,
    List<String>? followers,
  }) {
    return UserModel(
      userId: userId,
      username: username ?? this.username,
      email: email,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      reputation: reputation ?? this.reputation,
      totalUpvotes: totalUpvotes ?? this.totalUpvotes,
      isVerified: isVerified ?? this.isVerified,
      role: role,
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }
}
