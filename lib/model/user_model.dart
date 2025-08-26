import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _tsToDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

int _toInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<String> _safeStringList(dynamic v) {
  if (v is Iterable) return v.whereType<String>().toList();
  return const <String>[];
}

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
  final DateTime? createdAt; // nullable for safety
  final DateTime? updatedAt; // nullable for safety
  final int reputation;
  final int totalUpvotes;
  final bool isVerified;
  final String role;
  final List<String> following;
  final List<String> followers;
  final int followersCount; // NEW
  final int followingCount; // NEW

  const UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    this.profilePicture = '',
    this.bio = '',
    this.website = '',
    this.twitter = '',
    this.linkedin = '',
    this.createdAt,
    this.updatedAt,
    this.reputation = 0,
    this.totalUpvotes = 0,
    this.isVerified = false,
    this.role = 'user',
    this.following = const [],
    this.followers = const [],
    this.followersCount = 0, // defaults
    this.followingCount = 0, // defaults
  });

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
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
      if (includeTimestamps && createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!),
      if (includeTimestamps && updatedAt != null)
        'updatedAt': Timestamp.fromDate(updatedAt!),
      'reputation': reputation,
      'totalUpvotes': totalUpvotes,
      'isVerified': isVerified,
      'role': role,
      'following': following,
      'followers': followers,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel(
      userId: doc.id,
      username: (data['username'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      displayName: (data['displayName'] ?? '') as String,
      profilePicture: (data['profilePicture'] ?? '') as String,
      bio: (data['bio'] ?? '') as String,
      website: (data['website'] ?? '') as String,
      twitter: (data['twitter'] ?? '') as String,
      linkedin: (data['linkedin'] ?? '') as String,
      createdAt: _tsToDate(data['createdAt']),
      updatedAt: _tsToDate(data['updatedAt']),
      reputation: _toInt(data['reputation']),
      totalUpvotes: _toInt(data['totalUpvotes']),
      isVerified: (data['isVerified'] ?? false) as bool,
      role: (data['role'] ?? 'user') as String,
      following: _safeStringList(data['following']),
      followers: _safeStringList(data['followers']),
      followersCount: _toInt(data['followersCount']),
      followingCount: _toInt(data['followingCount']),
    );
  }

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
    int? followersCount,
    int? followingCount,
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
      updatedAt:
          DateTime.now(), // local; service overwrites with serverTimestamp
      reputation: reputation ?? this.reputation,
      totalUpvotes: totalUpvotes ?? this.totalUpvotes,
      isVerified: isVerified ?? this.isVerified,
      role: role,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
