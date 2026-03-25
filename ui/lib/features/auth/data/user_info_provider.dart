import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository.dart';

part 'user_info_provider.g.dart';

/// User profile information from ID token
class UserInfo {
  const UserInfo({this.id, this.name, this.email, this.picture, this.phone});

  factory UserInfo.fromClaims(Map<String, dynamic> claims) => UserInfo(
    id: claims['sub'] as String?,
    name: claims['name'] as String? ?? claims['preferred_username'] as String?,
    email: claims['email'] as String?,
    picture: claims['picture'] as String?,
    phone: claims['phone_number'] as String?,
  );
  final String? id;
  final String? name;
  final String? email;
  final String? picture;
  final String? phone;

  String get displayName => name ?? email ?? phone ?? 'User';

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }
}

@riverpod
Future<UserInfo?> userInfo(Ref ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final claims = await authRepo.getUserInfo();
  if (claims == null) return null;
  return UserInfo.fromClaims(claims);
}
