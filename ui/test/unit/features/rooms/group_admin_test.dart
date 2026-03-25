import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/sync/pending_job.dart';
import 'package:stawi/features/rooms/data/room_subscription_repository.dart';
import 'package:stawi/features/rooms/ui/member_action_sheet.dart';

void main() {
  group('GROUP-ADMIN-001: Group Admin Controls', () {
    group('MemberRole', () {
      test('isAdmin returns true for admin role', () {
        expect(MemberRole.isAdmin('admin'), isTrue);
        expect(MemberRole.isAdmin('Admin'), isTrue);
        expect(MemberRole.isAdmin('ADMIN'), isTrue);
      });

      test('isAdmin returns true for owner role', () {
        expect(MemberRole.isAdmin('owner'), isTrue);
        expect(MemberRole.isAdmin('Owner'), isTrue);
      });

      test('isAdmin returns false for member role', () {
        expect(MemberRole.isAdmin('member'), isFalse);
        expect(MemberRole.isAdmin('moderator'), isFalse);
        expect(MemberRole.isAdmin(null), isFalse);
        expect(MemberRole.isAdmin(''), isFalse);
      });

      test('isOwner returns true only for owner role', () {
        expect(MemberRole.isOwner('owner'), isTrue);
        expect(MemberRole.isOwner('Owner'), isTrue);
        expect(MemberRole.isOwner('admin'), isFalse);
        expect(MemberRole.isOwner(null), isFalse);
      });

      test('displayName returns correct display names', () {
        expect(MemberRole.displayName('owner'), equals('Owner'));
        expect(MemberRole.displayName('admin'), equals('Admin'));
        expect(MemberRole.displayName('moderator'), equals('Moderator'));
        expect(MemberRole.displayName('member'), equals('Member'));
        expect(MemberRole.displayName(null), equals('Member'));
        expect(MemberRole.displayName(''), equals('Member'));
      });
    });

    group('JobType.changeMemberRole', () {
      test('changeMemberRole exists in JobType enum', () {
        expect(JobType.values.contains(JobType.changeMemberRole), isTrue);
      });

      test('changeMemberRole is between removeRoomMembers and leaveRoom', () {
        final removeIndex = JobType.removeRoomMembers.index;
        final changeIndex = JobType.changeMemberRole.index;
        final leaveIndex = JobType.leaveRoom.index;

        expect(changeIndex, greaterThan(removeIndex));
        expect(changeIndex, lessThan(leaveIndex));
      });
    });

    group('RoomSubscriptionRepository', () {
      late AppDatabase db;
      late RoomSubscriptionRepository repo;

      setUp(() async {
        // Create in-memory database for testing
        db = AppDatabase.forTesting(NativeDatabase.memory());
        repo = RoomSubscriptionRepository(db);

        // Insert test profiles first (required by foreign key constraints)
        await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(
                id: 'profile1',
                name: const Value('Admin User'),
              ),
            );
        await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(
                id: 'profile2',
                name: const Value('Member User'),
              ),
            );
        await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(
                id: 'profile3',
                name: const Value('Owner User'),
              ),
            );

        // Insert test room
        await db
            .into(db.rooms)
            .insert(
              RoomsCompanion.insert(
                id: 'room1',
                name: const Value('Test Room'),
              ),
            );

        // Insert test room subscriptions
        await db
            .into(db.roomSubscriptions)
            .insert(
              RoomSubscriptionsCompanion.insert(
                id: 'sub1',
                roomId: 'room1',
                profileId: const Value('profile1'),
                role: const Value('admin'),
                joinedAt: const Value(1000),
              ),
            );
        await db
            .into(db.roomSubscriptions)
            .insert(
              RoomSubscriptionsCompanion.insert(
                id: 'sub2',
                roomId: 'room1',
                profileId: const Value('profile2'),
                role: const Value('member'),
                joinedAt: const Value(2000),
              ),
            );
        await db
            .into(db.roomSubscriptions)
            .insert(
              RoomSubscriptionsCompanion.insert(
                id: 'sub3',
                roomId: 'room1',
                profileId: const Value('profile3'),
                role: const Value('owner'),
                joinedAt: const Value(500),
              ),
            );
      });

      tearDown(() async {
        await db.close();
      });

      test('updateMemberRole updates role successfully', () async {
        final result = await repo.updateMemberRole(
          id: 'sub2',
          newRole: 'admin',
        );

        expect(result, isTrue);

        final member = await repo.getSubscription('sub2');
        expect(member?.role, equals('admin'));
      });

      test(
        'updateMemberRole returns false for non-existent subscription',
        () async {
          final result = await repo.updateMemberRole(
            id: 'non-existent',
            newRole: 'admin',
          );

          expect(result, isFalse);
        },
      );

      test('getMembersByRole returns members with matching role', () async {
        final admins = await repo.getMembersByRole('room1', 'admin');

        expect(admins.length, equals(1));
        expect(admins.first.id, equals('sub1'));
      });

      test('getMembersByRole returns empty list for no matches', () async {
        final moderators = await repo.getMembersByRole('room1', 'moderator');

        expect(moderators, isEmpty);
      });

      test('isRoomAdmin returns true for admin role', () async {
        final isAdmin = await repo.isRoomAdmin('room1', 'profile1');

        expect(isAdmin, isTrue);
      });

      test('isRoomAdmin returns true for owner role', () async {
        final isAdmin = await repo.isRoomAdmin('room1', 'profile3');

        expect(isAdmin, isTrue);
      });

      test('isRoomAdmin returns false for member role', () async {
        final isAdmin = await repo.isRoomAdmin('room1', 'profile2');

        expect(isAdmin, isFalse);
      });

      test('isRoomOwner returns true only for owner role', () async {
        expect(await repo.isRoomOwner('room1', 'profile3'), isTrue);
        expect(await repo.isRoomOwner('room1', 'profile1'), isFalse);
        expect(await repo.isRoomOwner('room1', 'profile2'), isFalse);
      });

      test('getMemberByProfileId returns correct member', () async {
        final member = await repo.getMemberByProfileId('room1', 'profile1');

        expect(member, isNotNull);
        expect(member!.id, equals('sub1'));
        expect(member.role, equals('admin'));
      });

      test(
        'getMemberByProfileId returns null for non-existent profile',
        () async {
          final member = await repo.getMemberByProfileId(
            'room1',
            'non-existent',
          );

          expect(member, isNull);
        },
      );
    });

    group('Role change permissions', () {
      test('admin can change member to admin', () {
        // Admins should be able to promote members
        const currentUserRole = 'admin';
        const targetRole = 'member';

        final canPromote =
            MemberRole.isAdmin(currentUserRole) &&
            !MemberRole.isOwner(targetRole);

        expect(canPromote, isTrue);
      });

      test('admin cannot change owner role', () {
        const currentUserRole = 'admin';
        const targetRole = 'owner';

        final canChange =
            MemberRole.isAdmin(currentUserRole) &&
            !MemberRole.isOwner(targetRole);

        expect(canChange, isFalse);
      });

      test('member cannot promote others', () {
        const currentUserRole = 'member';

        final canPromote = MemberRole.isAdmin(currentUserRole);

        expect(canPromote, isFalse);
      });
    });
  });
}
