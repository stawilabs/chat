import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_info_provider.g.dart';

/// User profile information from ID token claims.
class UserInfo {
  const UserInfo({this.id, this.name, this.email, this.picture, this.phone});

  factory UserInfo.fromClaims(UserClaims claims) => UserInfo(
    id: claims.sub,
    name: claims.name ?? claims.raw['preferred_username'] as String?,
    email: claims.email,
    picture: claims.picture,
    phone: claims.raw['phone_number'] as String?,
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
  final rt = ref.watch(authRuntimeProvider);
  if (!rt.isAuthenticated) return null;
  final claims = await rt.getUserClaims();
  if (claims.sub == null) return null;
  return UserInfo.fromClaims(claims);
}
