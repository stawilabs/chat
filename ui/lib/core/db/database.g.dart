// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMessageMeta = const VerificationMeta(
    'statusMessage',
  );
  @override
  late final GeneratedColumn<String> statusMessage = GeneratedColumn<String>(
    'status_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusUpdatedAtMeta = const VerificationMeta(
    'statusUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> statusUpdatedAt = GeneratedColumn<int>(
    'status_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatarUrl,
    updatedAt,
    metadata,
    status,
    statusMessage,
    statusUpdatedAt,
    bio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('status_message')) {
      context.handle(
        _statusMessageMeta,
        statusMessage.isAcceptableOrUnknown(
          data['status_message']!,
          _statusMessageMeta,
        ),
      );
    }
    if (data.containsKey('status_updated_at')) {
      context.handle(
        _statusUpdatedAtMeta,
        statusUpdatedAt.isAcceptableOrUnknown(
          data['status_updated_at']!,
          _statusUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      statusMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_message'],
      ),
      statusUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_updated_at'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String? name;
  final String? avatarUrl;
  final int? updatedAt;
  final String? metadata;

  /// User's presence status (0=offline, 1=online, 2=away, 3=busy, 4=doNotDisturb)
  final int status;

  /// Custom status message (e.g., "In a meeting", "On vacation")
  final String? statusMessage;

  /// Timestamp when status was last updated
  final int? statusUpdatedAt;

  /// User's bio/about text
  final String? bio;
  const Profile({
    required this.id,
    this.name,
    this.avatarUrl,
    this.updatedAt,
    this.metadata,
    required this.status,
    this.statusMessage,
    this.statusUpdatedAt,
    this.bio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || statusMessage != null) {
      map['status_message'] = Variable<String>(statusMessage);
    }
    if (!nullToAbsent || statusUpdatedAt != null) {
      map['status_updated_at'] = Variable<int>(statusUpdatedAt);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      status: Value(status),
      statusMessage: statusMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(statusMessage),
      statusUpdatedAt: statusUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(statusUpdatedAt),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      status: serializer.fromJson<int>(json['status']),
      statusMessage: serializer.fromJson<String?>(json['statusMessage']),
      statusUpdatedAt: serializer.fromJson<int?>(json['statusUpdatedAt']),
      bio: serializer.fromJson<String?>(json['bio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'metadata': serializer.toJson<String?>(metadata),
      'status': serializer.toJson<int>(status),
      'statusMessage': serializer.toJson<String?>(statusMessage),
      'statusUpdatedAt': serializer.toJson<int?>(statusUpdatedAt),
      'bio': serializer.toJson<String?>(bio),
    };
  }

  Profile copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    int? status,
    Value<String?> statusMessage = const Value.absent(),
    Value<int?> statusUpdatedAt = const Value.absent(),
    Value<String?> bio = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    metadata: metadata.present ? metadata.value : this.metadata,
    status: status ?? this.status,
    statusMessage: statusMessage.present
        ? statusMessage.value
        : this.statusMessage,
    statusUpdatedAt: statusUpdatedAt.present
        ? statusUpdatedAt.value
        : this.statusUpdatedAt,
    bio: bio.present ? bio.value : this.bio,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      status: data.status.present ? data.status.value : this.status,
      statusMessage: data.statusMessage.present
          ? data.statusMessage.value
          : this.statusMessage,
      statusUpdatedAt: data.statusUpdatedAt.present
          ? data.statusUpdatedAt.value
          : this.statusUpdatedAt,
      bio: data.bio.present ? data.bio.value : this.bio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('metadata: $metadata, ')
          ..write('status: $status, ')
          ..write('statusMessage: $statusMessage, ')
          ..write('statusUpdatedAt: $statusUpdatedAt, ')
          ..write('bio: $bio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatarUrl,
    updatedAt,
    metadata,
    status,
    statusMessage,
    statusUpdatedAt,
    bio,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.updatedAt == this.updatedAt &&
          other.metadata == this.metadata &&
          other.status == this.status &&
          other.statusMessage == this.statusMessage &&
          other.statusUpdatedAt == this.statusUpdatedAt &&
          other.bio == this.bio);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> avatarUrl;
  final Value<int?> updatedAt;
  final Value<String?> metadata;
  final Value<int> status;
  final Value<String?> statusMessage;
  final Value<int?> statusUpdatedAt;
  final Value<String?> bio;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.metadata = const Value.absent(),
    this.status = const Value.absent(),
    this.statusMessage = const Value.absent(),
    this.statusUpdatedAt = const Value.absent(),
    this.bio = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.metadata = const Value.absent(),
    this.status = const Value.absent(),
    this.statusMessage = const Value.absent(),
    this.statusUpdatedAt = const Value.absent(),
    this.bio = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<int>? updatedAt,
    Expression<String>? metadata,
    Expression<int>? status,
    Expression<String>? statusMessage,
    Expression<int>? statusUpdatedAt,
    Expression<String>? bio,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (metadata != null) 'metadata': metadata,
      if (status != null) 'status': status,
      if (statusMessage != null) 'status_message': statusMessage,
      if (statusUpdatedAt != null) 'status_updated_at': statusUpdatedAt,
      if (bio != null) 'bio': bio,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? avatarUrl,
    Value<int?>? updatedAt,
    Value<String?>? metadata,
    Value<int>? status,
    Value<String?>? statusMessage,
    Value<int?>? statusUpdatedAt,
    Value<String?>? bio,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      bio: bio ?? this.bio,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (statusMessage.present) {
      map['status_message'] = Variable<String>(statusMessage.value);
    }
    if (statusUpdatedAt.present) {
      map['status_updated_at'] = Variable<int>(statusUpdatedAt.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('metadata: $metadata, ')
          ..write('status: $status, ')
          ..write('statusMessage: $statusMessage, ')
          ..write('statusUpdatedAt: $statusUpdatedAt, ')
          ..write('bio: $bio, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RosterTable extends Roster with TableInfo<$RosterTable, RosterData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RosterTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rosterIdMeta = const VerificationMeta(
    'rosterId',
  );
  @override
  late final GeneratedColumn<String> rosterId = GeneratedColumn<String>(
    'roster_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactTypeMeta = const VerificationMeta(
    'contactType',
  );
  @override
  late final GeneratedColumn<int> contactType = GeneratedColumn<int>(
    'contact_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contactDetailMeta = const VerificationMeta(
    'contactDetail',
  );
  @override
  late final GeneratedColumn<String> contactDetail = GeneratedColumn<String>(
    'contact_detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVerifiedMeta = const VerificationMeta(
    'isVerified',
  );
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
    'is_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBlockedMeta = const VerificationMeta(
    'isBlocked',
  );
  @override
  late final GeneratedColumn<bool> isBlocked = GeneratedColumn<bool>(
    'is_blocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_blocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rosterId,
    profileId,
    contactId,
    contactType,
    contactDetail,
    isVerified,
    displayName,
    isBlocked,
    syncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roster';
  @override
  VerificationContext validateIntegrity(
    Insertable<RosterData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('roster_id')) {
      context.handle(
        _rosterIdMeta,
        rosterId.isAcceptableOrUnknown(data['roster_id']!, _rosterIdMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('contact_type')) {
      context.handle(
        _contactTypeMeta,
        contactType.isAcceptableOrUnknown(
          data['contact_type']!,
          _contactTypeMeta,
        ),
      );
    }
    if (data.containsKey('contact_detail')) {
      context.handle(
        _contactDetailMeta,
        contactDetail.isAcceptableOrUnknown(
          data['contact_detail']!,
          _contactDetailMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactDetailMeta);
    }
    if (data.containsKey('is_verified')) {
      context.handle(
        _isVerifiedMeta,
        isVerified.isAcceptableOrUnknown(data['is_verified']!, _isVerifiedMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('is_blocked')) {
      context.handle(
        _isBlockedMeta,
        isBlocked.isAcceptableOrUnknown(data['is_blocked']!, _isBlockedMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RosterData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RosterData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rosterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roster_id'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
      contactType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_type'],
      )!,
      contactDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_detail'],
      )!,
      isVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_verified'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      isBlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_blocked'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $RosterTable createAlias(String alias) {
    return $RosterTable(attachedDatabase, alias);
  }
}

class RosterData extends DataClass implements Insertable<RosterData> {
  final String id;
  final String? rosterId;
  final String? profileId;
  final String? contactId;
  final int contactType;
  final String contactDetail;
  final bool isVerified;
  final String? displayName;
  final bool isBlocked;
  final int? syncedAt;
  final int? createdAt;
  const RosterData({
    required this.id,
    this.rosterId,
    this.profileId,
    this.contactId,
    required this.contactType,
    required this.contactDetail,
    required this.isVerified,
    this.displayName,
    required this.isBlocked,
    this.syncedAt,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || rosterId != null) {
      map['roster_id'] = Variable<String>(rosterId);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    map['contact_type'] = Variable<int>(contactType);
    map['contact_detail'] = Variable<String>(contactDetail);
    map['is_verified'] = Variable<bool>(isVerified);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['is_blocked'] = Variable<bool>(isBlocked);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  RosterCompanion toCompanion(bool nullToAbsent) {
    return RosterCompanion(
      id: Value(id),
      rosterId: rosterId == null && nullToAbsent
          ? const Value.absent()
          : Value(rosterId),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      contactType: Value(contactType),
      contactDetail: Value(contactDetail),
      isVerified: Value(isVerified),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      isBlocked: Value(isBlocked),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory RosterData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RosterData(
      id: serializer.fromJson<String>(json['id']),
      rosterId: serializer.fromJson<String?>(json['rosterId']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      contactType: serializer.fromJson<int>(json['contactType']),
      contactDetail: serializer.fromJson<String>(json['contactDetail']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      isBlocked: serializer.fromJson<bool>(json['isBlocked']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rosterId': serializer.toJson<String?>(rosterId),
      'profileId': serializer.toJson<String?>(profileId),
      'contactId': serializer.toJson<String?>(contactId),
      'contactType': serializer.toJson<int>(contactType),
      'contactDetail': serializer.toJson<String>(contactDetail),
      'isVerified': serializer.toJson<bool>(isVerified),
      'displayName': serializer.toJson<String?>(displayName),
      'isBlocked': serializer.toJson<bool>(isBlocked),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  RosterData copyWith({
    String? id,
    Value<String?> rosterId = const Value.absent(),
    Value<String?> profileId = const Value.absent(),
    Value<String?> contactId = const Value.absent(),
    int? contactType,
    String? contactDetail,
    bool? isVerified,
    Value<String?> displayName = const Value.absent(),
    bool? isBlocked,
    Value<int?> syncedAt = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
  }) => RosterData(
    id: id ?? this.id,
    rosterId: rosterId.present ? rosterId.value : this.rosterId,
    profileId: profileId.present ? profileId.value : this.profileId,
    contactId: contactId.present ? contactId.value : this.contactId,
    contactType: contactType ?? this.contactType,
    contactDetail: contactDetail ?? this.contactDetail,
    isVerified: isVerified ?? this.isVerified,
    displayName: displayName.present ? displayName.value : this.displayName,
    isBlocked: isBlocked ?? this.isBlocked,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  RosterData copyWithCompanion(RosterCompanion data) {
    return RosterData(
      id: data.id.present ? data.id.value : this.id,
      rosterId: data.rosterId.present ? data.rosterId.value : this.rosterId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      contactType: data.contactType.present
          ? data.contactType.value
          : this.contactType,
      contactDetail: data.contactDetail.present
          ? data.contactDetail.value
          : this.contactDetail,
      isVerified: data.isVerified.present
          ? data.isVerified.value
          : this.isVerified,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      isBlocked: data.isBlocked.present ? data.isBlocked.value : this.isBlocked,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RosterData(')
          ..write('id: $id, ')
          ..write('rosterId: $rosterId, ')
          ..write('profileId: $profileId, ')
          ..write('contactId: $contactId, ')
          ..write('contactType: $contactType, ')
          ..write('contactDetail: $contactDetail, ')
          ..write('isVerified: $isVerified, ')
          ..write('displayName: $displayName, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rosterId,
    profileId,
    contactId,
    contactType,
    contactDetail,
    isVerified,
    displayName,
    isBlocked,
    syncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RosterData &&
          other.id == this.id &&
          other.rosterId == this.rosterId &&
          other.profileId == this.profileId &&
          other.contactId == this.contactId &&
          other.contactType == this.contactType &&
          other.contactDetail == this.contactDetail &&
          other.isVerified == this.isVerified &&
          other.displayName == this.displayName &&
          other.isBlocked == this.isBlocked &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt);
}

class RosterCompanion extends UpdateCompanion<RosterData> {
  final Value<String> id;
  final Value<String?> rosterId;
  final Value<String?> profileId;
  final Value<String?> contactId;
  final Value<int> contactType;
  final Value<String> contactDetail;
  final Value<bool> isVerified;
  final Value<String?> displayName;
  final Value<bool> isBlocked;
  final Value<int?> syncedAt;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const RosterCompanion({
    this.id = const Value.absent(),
    this.rosterId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.contactType = const Value.absent(),
    this.contactDetail = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RosterCompanion.insert({
    required String id,
    this.rosterId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.contactType = const Value.absent(),
    required String contactDetail,
    this.isVerified = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contactDetail = Value(contactDetail);
  static Insertable<RosterData> custom({
    Expression<String>? id,
    Expression<String>? rosterId,
    Expression<String>? profileId,
    Expression<String>? contactId,
    Expression<int>? contactType,
    Expression<String>? contactDetail,
    Expression<bool>? isVerified,
    Expression<String>? displayName,
    Expression<bool>? isBlocked,
    Expression<int>? syncedAt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rosterId != null) 'roster_id': rosterId,
      if (profileId != null) 'profile_id': profileId,
      if (contactId != null) 'contact_id': contactId,
      if (contactType != null) 'contact_type': contactType,
      if (contactDetail != null) 'contact_detail': contactDetail,
      if (isVerified != null) 'is_verified': isVerified,
      if (displayName != null) 'display_name': displayName,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RosterCompanion copyWith({
    Value<String>? id,
    Value<String?>? rosterId,
    Value<String?>? profileId,
    Value<String?>? contactId,
    Value<int>? contactType,
    Value<String>? contactDetail,
    Value<bool>? isVerified,
    Value<String?>? displayName,
    Value<bool>? isBlocked,
    Value<int?>? syncedAt,
    Value<int?>? createdAt,
    Value<int>? rowid,
  }) {
    return RosterCompanion(
      id: id ?? this.id,
      rosterId: rosterId ?? this.rosterId,
      profileId: profileId ?? this.profileId,
      contactId: contactId ?? this.contactId,
      contactType: contactType ?? this.contactType,
      contactDetail: contactDetail ?? this.contactDetail,
      isVerified: isVerified ?? this.isVerified,
      displayName: displayName ?? this.displayName,
      isBlocked: isBlocked ?? this.isBlocked,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rosterId.present) {
      map['roster_id'] = Variable<String>(rosterId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (contactType.present) {
      map['contact_type'] = Variable<int>(contactType.value);
    }
    if (contactDetail.present) {
      map['contact_detail'] = Variable<String>(contactDetail.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isBlocked.present) {
      map['is_blocked'] = Variable<bool>(isBlocked.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RosterCompanion(')
          ..write('id: $id, ')
          ..write('rosterId: $rosterId, ')
          ..write('profileId: $profileId, ')
          ..write('contactId: $contactId, ')
          ..write('contactType: $contactType, ')
          ..write('contactDetail: $contactDetail, ')
          ..write('isVerified: $isVerified, ')
          ..write('displayName: $displayName, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastEventIdMeta = const VerificationMeta(
    'lastEventId',
  );
  @override
  late final GeneratedColumn<String> lastEventId = GeneratedColumn<String>(
    'last_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastEventIndexMeta = const VerificationMeta(
    'lastEventIndex',
  );
  @override
  late final GeneratedColumn<int> lastEventIndex = GeneratedColumn<int>(
    'last_event_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disappearingTimeoutMeta =
      const VerificationMeta('disappearingTimeout');
  @override
  late final GeneratedColumn<int> disappearingTimeout = GeneratedColumn<int>(
    'disappearing_timeout',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mutedUntilMeta = const VerificationMeta(
    'mutedUntil',
  );
  @override
  late final GeneratedColumn<int> mutedUntil = GeneratedColumn<int>(
    'muted_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberLimitMeta = const VerificationMeta(
    'memberLimit',
  );
  @override
  late final GeneratedColumn<int> memberLimit = GeneratedColumn<int>(
    'member_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberLimitEnabledMeta =
      const VerificationMeta('memberLimitEnabled');
  @override
  late final GeneratedColumn<bool> memberLimitEnabled = GeneratedColumn<bool>(
    'member_limit_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("member_limit_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    lastEventId,
    lastEventIndex,
    unreadCount,
    metadata,
    disappearingTimeout,
    mutedUntil,
    memberLimit,
    memberLimitEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Room> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('last_event_id')) {
      context.handle(
        _lastEventIdMeta,
        lastEventId.isAcceptableOrUnknown(
          data['last_event_id']!,
          _lastEventIdMeta,
        ),
      );
    }
    if (data.containsKey('last_event_index')) {
      context.handle(
        _lastEventIndexMeta,
        lastEventIndex.isAcceptableOrUnknown(
          data['last_event_index']!,
          _lastEventIndexMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('disappearing_timeout')) {
      context.handle(
        _disappearingTimeoutMeta,
        disappearingTimeout.isAcceptableOrUnknown(
          data['disappearing_timeout']!,
          _disappearingTimeoutMeta,
        ),
      );
    }
    if (data.containsKey('muted_until')) {
      context.handle(
        _mutedUntilMeta,
        mutedUntil.isAcceptableOrUnknown(data['muted_until']!, _mutedUntilMeta),
      );
    }
    if (data.containsKey('member_limit')) {
      context.handle(
        _memberLimitMeta,
        memberLimit.isAcceptableOrUnknown(
          data['member_limit']!,
          _memberLimitMeta,
        ),
      );
    }
    if (data.containsKey('member_limit_enabled')) {
      context.handle(
        _memberLimitEnabledMeta,
        memberLimitEnabled.isAcceptableOrUnknown(
          data['member_limit_enabled']!,
          _memberLimitEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Room map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Room(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      lastEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_event_id'],
      ),
      lastEventIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_event_index'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      disappearingTimeout: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disappearing_timeout'],
      ),
      mutedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}muted_until'],
      ),
      memberLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_limit'],
      ),
      memberLimitEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}member_limit_enabled'],
      )!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  /// Unique room identifier from server
  final String id;

  /// Display name for the room (null for direct messages)
  final String? name;

  /// Room type: 'direct', 'group', or 'channel'
  final String? type;

  /// ID of the last event received in this room
  final String? lastEventId;

  /// Index of the last event for ordering
  final int? lastEventIndex;

  /// Count of unread messages in this room
  final int unreadCount;

  /// JSON-encoded room metadata (avatar, description, etc.)
  final String? metadata;

  /// Disappearing messages timeout in seconds (null = disabled)
  /// Supported values: null (off), 86400 (24h), 604800 (7d), 7776000 (90d)
  final int? disappearingTimeout;

  /// Mute notifications until this epoch timestamp (null = not muted)
  final int? mutedUntil;

  /// Maximum number of members allowed in this room (null = default 256)
  final int? memberLimit;

  /// Whether member limit is enforced (only applicable for groups)
  final bool memberLimitEnabled;
  const Room({
    required this.id,
    this.name,
    this.type,
    this.lastEventId,
    this.lastEventIndex,
    required this.unreadCount,
    this.metadata,
    this.disappearingTimeout,
    this.mutedUntil,
    this.memberLimit,
    required this.memberLimitEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || lastEventId != null) {
      map['last_event_id'] = Variable<String>(lastEventId);
    }
    if (!nullToAbsent || lastEventIndex != null) {
      map['last_event_index'] = Variable<int>(lastEventIndex);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || disappearingTimeout != null) {
      map['disappearing_timeout'] = Variable<int>(disappearingTimeout);
    }
    if (!nullToAbsent || mutedUntil != null) {
      map['muted_until'] = Variable<int>(mutedUntil);
    }
    if (!nullToAbsent || memberLimit != null) {
      map['member_limit'] = Variable<int>(memberLimit);
    }
    map['member_limit_enabled'] = Variable<bool>(memberLimitEnabled);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      lastEventId: lastEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEventId),
      lastEventIndex: lastEventIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEventIndex),
      unreadCount: Value(unreadCount),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      disappearingTimeout: disappearingTimeout == null && nullToAbsent
          ? const Value.absent()
          : Value(disappearingTimeout),
      mutedUntil: mutedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(mutedUntil),
      memberLimit: memberLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(memberLimit),
      memberLimitEnabled: Value(memberLimitEnabled),
    );
  }

  factory Room.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      lastEventId: serializer.fromJson<String?>(json['lastEventId']),
      lastEventIndex: serializer.fromJson<int?>(json['lastEventIndex']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      disappearingTimeout: serializer.fromJson<int?>(
        json['disappearingTimeout'],
      ),
      mutedUntil: serializer.fromJson<int?>(json['mutedUntil']),
      memberLimit: serializer.fromJson<int?>(json['memberLimit']),
      memberLimitEnabled: serializer.fromJson<bool>(json['memberLimitEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String?>(type),
      'lastEventId': serializer.toJson<String?>(lastEventId),
      'lastEventIndex': serializer.toJson<int?>(lastEventIndex),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'metadata': serializer.toJson<String?>(metadata),
      'disappearingTimeout': serializer.toJson<int?>(disappearingTimeout),
      'mutedUntil': serializer.toJson<int?>(mutedUntil),
      'memberLimit': serializer.toJson<int?>(memberLimit),
      'memberLimitEnabled': serializer.toJson<bool>(memberLimitEnabled),
    };
  }

  Room copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> lastEventId = const Value.absent(),
    Value<int?> lastEventIndex = const Value.absent(),
    int? unreadCount,
    Value<String?> metadata = const Value.absent(),
    Value<int?> disappearingTimeout = const Value.absent(),
    Value<int?> mutedUntil = const Value.absent(),
    Value<int?> memberLimit = const Value.absent(),
    bool? memberLimitEnabled,
  }) => Room(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    type: type.present ? type.value : this.type,
    lastEventId: lastEventId.present ? lastEventId.value : this.lastEventId,
    lastEventIndex: lastEventIndex.present
        ? lastEventIndex.value
        : this.lastEventIndex,
    unreadCount: unreadCount ?? this.unreadCount,
    metadata: metadata.present ? metadata.value : this.metadata,
    disappearingTimeout: disappearingTimeout.present
        ? disappearingTimeout.value
        : this.disappearingTimeout,
    mutedUntil: mutedUntil.present ? mutedUntil.value : this.mutedUntil,
    memberLimit: memberLimit.present ? memberLimit.value : this.memberLimit,
    memberLimitEnabled: memberLimitEnabled ?? this.memberLimitEnabled,
  );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      lastEventId: data.lastEventId.present
          ? data.lastEventId.value
          : this.lastEventId,
      lastEventIndex: data.lastEventIndex.present
          ? data.lastEventIndex.value
          : this.lastEventIndex,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      disappearingTimeout: data.disappearingTimeout.present
          ? data.disappearingTimeout.value
          : this.disappearingTimeout,
      mutedUntil: data.mutedUntil.present
          ? data.mutedUntil.value
          : this.mutedUntil,
      memberLimit: data.memberLimit.present
          ? data.memberLimit.value
          : this.memberLimit,
      memberLimitEnabled: data.memberLimitEnabled.present
          ? data.memberLimitEnabled.value
          : this.memberLimitEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('lastEventId: $lastEventId, ')
          ..write('lastEventIndex: $lastEventIndex, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('metadata: $metadata, ')
          ..write('disappearingTimeout: $disappearingTimeout, ')
          ..write('mutedUntil: $mutedUntil, ')
          ..write('memberLimit: $memberLimit, ')
          ..write('memberLimitEnabled: $memberLimitEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    lastEventId,
    lastEventIndex,
    unreadCount,
    metadata,
    disappearingTimeout,
    mutedUntil,
    memberLimit,
    memberLimitEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.lastEventId == this.lastEventId &&
          other.lastEventIndex == this.lastEventIndex &&
          other.unreadCount == this.unreadCount &&
          other.metadata == this.metadata &&
          other.disappearingTimeout == this.disappearingTimeout &&
          other.mutedUntil == this.mutedUntil &&
          other.memberLimit == this.memberLimit &&
          other.memberLimitEnabled == this.memberLimitEnabled);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> type;
  final Value<String?> lastEventId;
  final Value<int?> lastEventIndex;
  final Value<int> unreadCount;
  final Value<String?> metadata;
  final Value<int?> disappearingTimeout;
  final Value<int?> mutedUntil;
  final Value<int?> memberLimit;
  final Value<bool> memberLimitEnabled;
  final Value<int> rowid;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.lastEventId = const Value.absent(),
    this.lastEventIndex = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.metadata = const Value.absent(),
    this.disappearingTimeout = const Value.absent(),
    this.mutedUntil = const Value.absent(),
    this.memberLimit = const Value.absent(),
    this.memberLimitEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.lastEventId = const Value.absent(),
    this.lastEventIndex = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.metadata = const Value.absent(),
    this.disappearingTimeout = const Value.absent(),
    this.mutedUntil = const Value.absent(),
    this.memberLimit = const Value.absent(),
    this.memberLimitEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Room> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? lastEventId,
    Expression<int>? lastEventIndex,
    Expression<int>? unreadCount,
    Expression<String>? metadata,
    Expression<int>? disappearingTimeout,
    Expression<int>? mutedUntil,
    Expression<int>? memberLimit,
    Expression<bool>? memberLimitEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (lastEventId != null) 'last_event_id': lastEventId,
      if (lastEventIndex != null) 'last_event_index': lastEventIndex,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (metadata != null) 'metadata': metadata,
      if (disappearingTimeout != null)
        'disappearing_timeout': disappearingTimeout,
      if (mutedUntil != null) 'muted_until': mutedUntil,
      if (memberLimit != null) 'member_limit': memberLimit,
      if (memberLimitEnabled != null)
        'member_limit_enabled': memberLimitEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? type,
    Value<String?>? lastEventId,
    Value<int?>? lastEventIndex,
    Value<int>? unreadCount,
    Value<String?>? metadata,
    Value<int?>? disappearingTimeout,
    Value<int?>? mutedUntil,
    Value<int?>? memberLimit,
    Value<bool>? memberLimitEnabled,
    Value<int>? rowid,
  }) {
    return RoomsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lastEventId: lastEventId ?? this.lastEventId,
      lastEventIndex: lastEventIndex ?? this.lastEventIndex,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
      disappearingTimeout: disappearingTimeout ?? this.disappearingTimeout,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      memberLimit: memberLimit ?? this.memberLimit,
      memberLimitEnabled: memberLimitEnabled ?? this.memberLimitEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lastEventId.present) {
      map['last_event_id'] = Variable<String>(lastEventId.value);
    }
    if (lastEventIndex.present) {
      map['last_event_index'] = Variable<int>(lastEventIndex.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (disappearingTimeout.present) {
      map['disappearing_timeout'] = Variable<int>(disappearingTimeout.value);
    }
    if (mutedUntil.present) {
      map['muted_until'] = Variable<int>(mutedUntil.value);
    }
    if (memberLimit.present) {
      map['member_limit'] = Variable<int>(memberLimit.value);
    }
    if (memberLimitEnabled.present) {
      map['member_limit_enabled'] = Variable<bool>(memberLimitEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('lastEventId: $lastEventId, ')
          ..write('lastEventIndex: $lastEventIndex, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('metadata: $metadata, ')
          ..write('disappearingTimeout: $disappearingTimeout, ')
          ..write('mutedUntil: $mutedUntil, ')
          ..write('memberLimit: $memberLimit, ')
          ..write('memberLimitEnabled: $memberLimitEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomSubscriptionsTable extends RoomSubscriptions
    with TableInfo<$RoomSubscriptionsTable, RoomSubscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomSubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<int> joinedAt = GeneratedColumn<int>(
    'joined_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomId,
    profileId,
    contactId,
    role,
    joinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'room_subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoomSubscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomSubscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomSubscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}joined_at'],
      ),
    );
  }

  @override
  $RoomSubscriptionsTable createAlias(String alias) {
    return $RoomSubscriptionsTable(attachedDatabase, alias);
  }
}

class RoomSubscription extends DataClass
    implements Insertable<RoomSubscription> {
  final String id;
  final String roomId;
  final String? profileId;
  final String? contactId;
  final String? role;
  final int? joinedAt;
  const RoomSubscription({
    required this.id,
    required this.roomId,
    this.profileId,
    this.contactId,
    this.role,
    this.joinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room_id'] = Variable<String>(roomId);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<int>(joinedAt);
    }
    return map;
  }

  RoomSubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return RoomSubscriptionsCompanion(
      id: Value(id),
      roomId: Value(roomId),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      joinedAt: joinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedAt),
    );
  }

  factory RoomSubscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomSubscription(
      id: serializer.fromJson<String>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      role: serializer.fromJson<String?>(json['role']),
      joinedAt: serializer.fromJson<int?>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roomId': serializer.toJson<String>(roomId),
      'profileId': serializer.toJson<String?>(profileId),
      'contactId': serializer.toJson<String?>(contactId),
      'role': serializer.toJson<String?>(role),
      'joinedAt': serializer.toJson<int?>(joinedAt),
    };
  }

  RoomSubscription copyWith({
    String? id,
    String? roomId,
    Value<String?> profileId = const Value.absent(),
    Value<String?> contactId = const Value.absent(),
    Value<String?> role = const Value.absent(),
    Value<int?> joinedAt = const Value.absent(),
  }) => RoomSubscription(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    profileId: profileId.present ? profileId.value : this.profileId,
    contactId: contactId.present ? contactId.value : this.contactId,
    role: role.present ? role.value : this.role,
    joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
  );
  RoomSubscription copyWithCompanion(RoomSubscriptionsCompanion data) {
    return RoomSubscription(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoomSubscription(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('profileId: $profileId, ')
          ..write('contactId: $contactId, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, roomId, profileId, contactId, role, joinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomSubscription &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.profileId == this.profileId &&
          other.contactId == this.contactId &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt);
}

class RoomSubscriptionsCompanion extends UpdateCompanion<RoomSubscription> {
  final Value<String> id;
  final Value<String> roomId;
  final Value<String?> profileId;
  final Value<String?> contactId;
  final Value<String?> role;
  final Value<int?> joinedAt;
  final Value<int> rowid;
  const RoomSubscriptionsCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomSubscriptionsCompanion.insert({
    required String id,
    required String roomId,
    this.profileId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomId = Value(roomId);
  static Insertable<RoomSubscription> custom({
    Expression<String>? id,
    Expression<String>? roomId,
    Expression<String>? profileId,
    Expression<String>? contactId,
    Expression<String>? role,
    Expression<int>? joinedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (profileId != null) 'profile_id': profileId,
      if (contactId != null) 'contact_id': contactId,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomSubscriptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? roomId,
    Value<String?>? profileId,
    Value<String?>? contactId,
    Value<String?>? role,
    Value<int?>? joinedAt,
    Value<int>? rowid,
  }) {
    return RoomSubscriptionsCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      profileId: profileId ?? this.profileId,
      contactId: contactId ?? this.contactId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<int>(joinedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomSubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('profileId: $profileId, ')
          ..write('contactId: $contactId, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomEventsTable extends RoomEvents
    with TableInfo<$RoomEventsTable, RoomEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderContactIdMeta = const VerificationMeta(
    'senderContactId',
  );
  @override
  late final GeneratedColumn<String> senderContactId = GeneratedColumn<String>(
    'sender_contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverTsMeta = const VerificationMeta(
    'serverTs',
  );
  @override
  late final GeneratedColumn<int> serverTs = GeneratedColumn<int>(
    'server_ts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalContentMeta = const VerificationMeta(
    'originalContent',
  );
  @override
  late final GeneratedColumn<String> originalContent = GeneratedColumn<String>(
    'original_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redactedMeta = const VerificationMeta(
    'redacted',
  );
  @override
  late final GeneratedColumn<bool> redacted = GeneratedColumn<bool>(
    'redacted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("redacted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _redactedAtMeta = const VerificationMeta(
    'redactedAt',
  );
  @override
  late final GeneratedColumn<int> redactedAt = GeneratedColumn<int>(
    'redacted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redactedByMeta = const VerificationMeta(
    'redactedBy',
  );
  @override
  late final GeneratedColumn<String> redactedBy = GeneratedColumn<String>(
    'redacted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _forwardedFromRoomMeta = const VerificationMeta(
    'forwardedFromRoom',
  );
  @override
  late final GeneratedColumn<String> forwardedFromRoom =
      GeneratedColumn<String>(
        'forwarded_from_room',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _forwardedFromEventMeta =
      const VerificationMeta('forwardedFromEvent');
  @override
  late final GeneratedColumn<String> forwardedFromEvent =
      GeneratedColumn<String>(
        'forwarded_from_event',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _forwardCountMeta = const VerificationMeta(
    'forwardCount',
  );
  @override
  late final GeneratedColumn<int> forwardCount = GeneratedColumn<int>(
    'forward_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _forwardRestrictedMeta = const VerificationMeta(
    'forwardRestricted',
  );
  @override
  late final GeneratedColumn<bool> forwardRestricted = GeneratedColumn<bool>(
    'forward_restricted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("forward_restricted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _starredMeta = const VerificationMeta(
    'starred',
  );
  @override
  late final GeneratedColumn<bool> starred = GeneratedColumn<bool>(
    'starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _starredAtMeta = const VerificationMeta(
    'starredAt',
  );
  @override
  late final GeneratedColumn<int> starredAt = GeneratedColumn<int>(
    'starred_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomId,
    senderId,
    senderContactId,
    type,
    content,
    parentId,
    status,
    createdAt,
    serverTs,
    localId,
    editedAt,
    originalContent,
    redacted,
    redactedAt,
    redactedBy,
    retryCount,
    errorMessage,
    forwardedFromRoom,
    forwardedFromEvent,
    forwardCount,
    forwardRestricted,
    expiresAt,
    starred,
    starredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'room_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoomEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_contact_id')) {
      context.handle(
        _senderContactIdMeta,
        senderContactId.isAcceptableOrUnknown(
          data['sender_contact_id']!,
          _senderContactIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('server_ts')) {
      context.handle(
        _serverTsMeta,
        serverTs.isAcceptableOrUnknown(data['server_ts']!, _serverTsMeta),
      );
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('original_content')) {
      context.handle(
        _originalContentMeta,
        originalContent.isAcceptableOrUnknown(
          data['original_content']!,
          _originalContentMeta,
        ),
      );
    }
    if (data.containsKey('redacted')) {
      context.handle(
        _redactedMeta,
        redacted.isAcceptableOrUnknown(data['redacted']!, _redactedMeta),
      );
    }
    if (data.containsKey('redacted_at')) {
      context.handle(
        _redactedAtMeta,
        redactedAt.isAcceptableOrUnknown(data['redacted_at']!, _redactedAtMeta),
      );
    }
    if (data.containsKey('redacted_by')) {
      context.handle(
        _redactedByMeta,
        redactedBy.isAcceptableOrUnknown(data['redacted_by']!, _redactedByMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('forwarded_from_room')) {
      context.handle(
        _forwardedFromRoomMeta,
        forwardedFromRoom.isAcceptableOrUnknown(
          data['forwarded_from_room']!,
          _forwardedFromRoomMeta,
        ),
      );
    }
    if (data.containsKey('forwarded_from_event')) {
      context.handle(
        _forwardedFromEventMeta,
        forwardedFromEvent.isAcceptableOrUnknown(
          data['forwarded_from_event']!,
          _forwardedFromEventMeta,
        ),
      );
    }
    if (data.containsKey('forward_count')) {
      context.handle(
        _forwardCountMeta,
        forwardCount.isAcceptableOrUnknown(
          data['forward_count']!,
          _forwardCountMeta,
        ),
      );
    }
    if (data.containsKey('forward_restricted')) {
      context.handle(
        _forwardRestrictedMeta,
        forwardRestricted.isAcceptableOrUnknown(
          data['forward_restricted']!,
          _forwardRestrictedMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('starred')) {
      context.handle(
        _starredMeta,
        starred.isAcceptableOrUnknown(data['starred']!, _starredMeta),
      );
    }
    if (data.containsKey('starred_at')) {
      context.handle(
        _starredAtMeta,
        starredAt.isAcceptableOrUnknown(data['starred_at']!, _starredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      senderContactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_contact_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      serverTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_ts'],
      ),
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      ),
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
      originalContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_content'],
      ),
      redacted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}redacted'],
      )!,
      redactedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}redacted_at'],
      ),
      redactedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}redacted_by'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      forwardedFromRoom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forwarded_from_room'],
      ),
      forwardedFromEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forwarded_from_event'],
      ),
      forwardCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}forward_count'],
      )!,
      forwardRestricted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}forward_restricted'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      ),
      starred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}starred'],
      )!,
      starredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starred_at'],
      ),
    );
  }

  @override
  $RoomEventsTable createAlias(String alias) {
    return $RoomEventsTable(attachedDatabase, alias);
  }
}

class RoomEvent extends DataClass implements Insertable<RoomEvent> {
  /// Unique event identifier (server-assigned or local UUID)
  final String id;

  /// Room this event belongs to (foreign key)
  final String roomId;

  /// Subscription ID of the sender (room-specific identifier)
  /// Use RoomSubscriptions table to look up the profile ID from this subscription ID
  final String senderId;

  /// Contact ID of the sender (nullable, for additional context)
  final String? senderContactId;

  /// Event type as integer (text=0, image=1, video=2, etc.)
  final int type;

  /// JSON-encoded event content (message text, attachment info, etc.)
  final String? content;

  /// Parent event ID for replies/threads
  final String? parentId;

  /// Event status (pending=0, sent=1, delivered=2, read=3, failed=4)
  final int status;

  /// Client-side creation timestamp
  final int? createdAt;

  /// Server-assigned timestamp for consistent ordering
  final int? serverTs;

  /// Temporary local ID before server confirmation
  final String? localId;

  /// Timestamp when message was last edited (null if never edited)
  final int? editedAt;

  /// Original message content before editing (preserved for history)
  final String? originalContent;

  /// Whether the message has been deleted/redacted
  final bool redacted;

  /// Timestamp when message was redacted
  final int? redactedAt;

  /// Profile ID of who redacted the message (for admin deletions)
  final String? redactedBy;

  /// Number of retry attempts for failed messages
  final int retryCount;

  /// Error message if send failed
  final String? errorMessage;

  /// Room ID this message was forwarded from (null if not forwarded)
  final String? forwardedFromRoom;

  /// Event ID this message was forwarded from (null if not forwarded)
  final String? forwardedFromEvent;

  /// Number of times this message has been forwarded
  final int forwardCount;

  /// Whether this message is restricted from being forwarded
  final bool forwardRestricted;

  /// Timestamp when this message should be deleted (for disappearing messages)
  /// Null means the message does not expire
  final int? expiresAt;

  /// Whether this message is starred/bookmarked by the user
  final bool starred;

  /// Timestamp when the message was starred (for sorting starred messages)
  final int? starredAt;
  const RoomEvent({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.senderContactId,
    required this.type,
    this.content,
    this.parentId,
    required this.status,
    this.createdAt,
    this.serverTs,
    this.localId,
    this.editedAt,
    this.originalContent,
    required this.redacted,
    this.redactedAt,
    this.redactedBy,
    required this.retryCount,
    this.errorMessage,
    this.forwardedFromRoom,
    this.forwardedFromEvent,
    required this.forwardCount,
    required this.forwardRestricted,
    this.expiresAt,
    required this.starred,
    this.starredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room_id'] = Variable<String>(roomId);
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || senderContactId != null) {
      map['sender_contact_id'] = Variable<String>(senderContactId);
    }
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || serverTs != null) {
      map['server_ts'] = Variable<int>(serverTs);
    }
    if (!nullToAbsent || localId != null) {
      map['local_id'] = Variable<String>(localId);
    }
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    if (!nullToAbsent || originalContent != null) {
      map['original_content'] = Variable<String>(originalContent);
    }
    map['redacted'] = Variable<bool>(redacted);
    if (!nullToAbsent || redactedAt != null) {
      map['redacted_at'] = Variable<int>(redactedAt);
    }
    if (!nullToAbsent || redactedBy != null) {
      map['redacted_by'] = Variable<String>(redactedBy);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || forwardedFromRoom != null) {
      map['forwarded_from_room'] = Variable<String>(forwardedFromRoom);
    }
    if (!nullToAbsent || forwardedFromEvent != null) {
      map['forwarded_from_event'] = Variable<String>(forwardedFromEvent);
    }
    map['forward_count'] = Variable<int>(forwardCount);
    map['forward_restricted'] = Variable<bool>(forwardRestricted);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    map['starred'] = Variable<bool>(starred);
    if (!nullToAbsent || starredAt != null) {
      map['starred_at'] = Variable<int>(starredAt);
    }
    return map;
  }

  RoomEventsCompanion toCompanion(bool nullToAbsent) {
    return RoomEventsCompanion(
      id: Value(id),
      roomId: Value(roomId),
      senderId: Value(senderId),
      senderContactId: senderContactId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderContactId),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      serverTs: serverTs == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTs),
      localId: localId == null && nullToAbsent
          ? const Value.absent()
          : Value(localId),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      originalContent: originalContent == null && nullToAbsent
          ? const Value.absent()
          : Value(originalContent),
      redacted: Value(redacted),
      redactedAt: redactedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(redactedAt),
      redactedBy: redactedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(redactedBy),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      forwardedFromRoom: forwardedFromRoom == null && nullToAbsent
          ? const Value.absent()
          : Value(forwardedFromRoom),
      forwardedFromEvent: forwardedFromEvent == null && nullToAbsent
          ? const Value.absent()
          : Value(forwardedFromEvent),
      forwardCount: Value(forwardCount),
      forwardRestricted: Value(forwardRestricted),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      starred: Value(starred),
      starredAt: starredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(starredAt),
    );
  }

  factory RoomEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomEvent(
      id: serializer.fromJson<String>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      senderContactId: serializer.fromJson<String?>(json['senderContactId']),
      type: serializer.fromJson<int>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      serverTs: serializer.fromJson<int?>(json['serverTs']),
      localId: serializer.fromJson<String?>(json['localId']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
      originalContent: serializer.fromJson<String?>(json['originalContent']),
      redacted: serializer.fromJson<bool>(json['redacted']),
      redactedAt: serializer.fromJson<int?>(json['redactedAt']),
      redactedBy: serializer.fromJson<String?>(json['redactedBy']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      forwardedFromRoom: serializer.fromJson<String?>(
        json['forwardedFromRoom'],
      ),
      forwardedFromEvent: serializer.fromJson<String?>(
        json['forwardedFromEvent'],
      ),
      forwardCount: serializer.fromJson<int>(json['forwardCount']),
      forwardRestricted: serializer.fromJson<bool>(json['forwardRestricted']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      starred: serializer.fromJson<bool>(json['starred']),
      starredAt: serializer.fromJson<int?>(json['starredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roomId': serializer.toJson<String>(roomId),
      'senderId': serializer.toJson<String>(senderId),
      'senderContactId': serializer.toJson<String?>(senderContactId),
      'type': serializer.toJson<int>(type),
      'content': serializer.toJson<String?>(content),
      'parentId': serializer.toJson<String?>(parentId),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<int?>(createdAt),
      'serverTs': serializer.toJson<int?>(serverTs),
      'localId': serializer.toJson<String?>(localId),
      'editedAt': serializer.toJson<int?>(editedAt),
      'originalContent': serializer.toJson<String?>(originalContent),
      'redacted': serializer.toJson<bool>(redacted),
      'redactedAt': serializer.toJson<int?>(redactedAt),
      'redactedBy': serializer.toJson<String?>(redactedBy),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'forwardedFromRoom': serializer.toJson<String?>(forwardedFromRoom),
      'forwardedFromEvent': serializer.toJson<String?>(forwardedFromEvent),
      'forwardCount': serializer.toJson<int>(forwardCount),
      'forwardRestricted': serializer.toJson<bool>(forwardRestricted),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'starred': serializer.toJson<bool>(starred),
      'starredAt': serializer.toJson<int?>(starredAt),
    };
  }

  RoomEvent copyWith({
    String? id,
    String? roomId,
    String? senderId,
    Value<String?> senderContactId = const Value.absent(),
    int? type,
    Value<String?> content = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    int? status,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> serverTs = const Value.absent(),
    Value<String?> localId = const Value.absent(),
    Value<int?> editedAt = const Value.absent(),
    Value<String?> originalContent = const Value.absent(),
    bool? redacted,
    Value<int?> redactedAt = const Value.absent(),
    Value<String?> redactedBy = const Value.absent(),
    int? retryCount,
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> forwardedFromRoom = const Value.absent(),
    Value<String?> forwardedFromEvent = const Value.absent(),
    int? forwardCount,
    bool? forwardRestricted,
    Value<int?> expiresAt = const Value.absent(),
    bool? starred,
    Value<int?> starredAt = const Value.absent(),
  }) => RoomEvent(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    senderId: senderId ?? this.senderId,
    senderContactId: senderContactId.present
        ? senderContactId.value
        : this.senderContactId,
    type: type ?? this.type,
    content: content.present ? content.value : this.content,
    parentId: parentId.present ? parentId.value : this.parentId,
    status: status ?? this.status,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    serverTs: serverTs.present ? serverTs.value : this.serverTs,
    localId: localId.present ? localId.value : this.localId,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    originalContent: originalContent.present
        ? originalContent.value
        : this.originalContent,
    redacted: redacted ?? this.redacted,
    redactedAt: redactedAt.present ? redactedAt.value : this.redactedAt,
    redactedBy: redactedBy.present ? redactedBy.value : this.redactedBy,
    retryCount: retryCount ?? this.retryCount,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    forwardedFromRoom: forwardedFromRoom.present
        ? forwardedFromRoom.value
        : this.forwardedFromRoom,
    forwardedFromEvent: forwardedFromEvent.present
        ? forwardedFromEvent.value
        : this.forwardedFromEvent,
    forwardCount: forwardCount ?? this.forwardCount,
    forwardRestricted: forwardRestricted ?? this.forwardRestricted,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    starred: starred ?? this.starred,
    starredAt: starredAt.present ? starredAt.value : this.starredAt,
  );
  RoomEvent copyWithCompanion(RoomEventsCompanion data) {
    return RoomEvent(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderContactId: data.senderContactId.present
          ? data.senderContactId.value
          : this.senderContactId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverTs: data.serverTs.present ? data.serverTs.value : this.serverTs,
      localId: data.localId.present ? data.localId.value : this.localId,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      originalContent: data.originalContent.present
          ? data.originalContent.value
          : this.originalContent,
      redacted: data.redacted.present ? data.redacted.value : this.redacted,
      redactedAt: data.redactedAt.present
          ? data.redactedAt.value
          : this.redactedAt,
      redactedBy: data.redactedBy.present
          ? data.redactedBy.value
          : this.redactedBy,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      forwardedFromRoom: data.forwardedFromRoom.present
          ? data.forwardedFromRoom.value
          : this.forwardedFromRoom,
      forwardedFromEvent: data.forwardedFromEvent.present
          ? data.forwardedFromEvent.value
          : this.forwardedFromEvent,
      forwardCount: data.forwardCount.present
          ? data.forwardCount.value
          : this.forwardCount,
      forwardRestricted: data.forwardRestricted.present
          ? data.forwardRestricted.value
          : this.forwardRestricted,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      starred: data.starred.present ? data.starred.value : this.starred,
      starredAt: data.starredAt.present ? data.starredAt.value : this.starredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoomEvent(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('senderContactId: $senderContactId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('parentId: $parentId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverTs: $serverTs, ')
          ..write('localId: $localId, ')
          ..write('editedAt: $editedAt, ')
          ..write('originalContent: $originalContent, ')
          ..write('redacted: $redacted, ')
          ..write('redactedAt: $redactedAt, ')
          ..write('redactedBy: $redactedBy, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('forwardedFromRoom: $forwardedFromRoom, ')
          ..write('forwardedFromEvent: $forwardedFromEvent, ')
          ..write('forwardCount: $forwardCount, ')
          ..write('forwardRestricted: $forwardRestricted, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('starred: $starred, ')
          ..write('starredAt: $starredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    roomId,
    senderId,
    senderContactId,
    type,
    content,
    parentId,
    status,
    createdAt,
    serverTs,
    localId,
    editedAt,
    originalContent,
    redacted,
    redactedAt,
    redactedBy,
    retryCount,
    errorMessage,
    forwardedFromRoom,
    forwardedFromEvent,
    forwardCount,
    forwardRestricted,
    expiresAt,
    starred,
    starredAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomEvent &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.senderId == this.senderId &&
          other.senderContactId == this.senderContactId &&
          other.type == this.type &&
          other.content == this.content &&
          other.parentId == this.parentId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.serverTs == this.serverTs &&
          other.localId == this.localId &&
          other.editedAt == this.editedAt &&
          other.originalContent == this.originalContent &&
          other.redacted == this.redacted &&
          other.redactedAt == this.redactedAt &&
          other.redactedBy == this.redactedBy &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.forwardedFromRoom == this.forwardedFromRoom &&
          other.forwardedFromEvent == this.forwardedFromEvent &&
          other.forwardCount == this.forwardCount &&
          other.forwardRestricted == this.forwardRestricted &&
          other.expiresAt == this.expiresAt &&
          other.starred == this.starred &&
          other.starredAt == this.starredAt);
}

class RoomEventsCompanion extends UpdateCompanion<RoomEvent> {
  final Value<String> id;
  final Value<String> roomId;
  final Value<String> senderId;
  final Value<String?> senderContactId;
  final Value<int> type;
  final Value<String?> content;
  final Value<String?> parentId;
  final Value<int> status;
  final Value<int?> createdAt;
  final Value<int?> serverTs;
  final Value<String?> localId;
  final Value<int?> editedAt;
  final Value<String?> originalContent;
  final Value<bool> redacted;
  final Value<int?> redactedAt;
  final Value<String?> redactedBy;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<String?> forwardedFromRoom;
  final Value<String?> forwardedFromEvent;
  final Value<int> forwardCount;
  final Value<bool> forwardRestricted;
  final Value<int?> expiresAt;
  final Value<bool> starred;
  final Value<int?> starredAt;
  final Value<int> rowid;
  const RoomEventsCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderContactId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.parentId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverTs = const Value.absent(),
    this.localId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.originalContent = const Value.absent(),
    this.redacted = const Value.absent(),
    this.redactedAt = const Value.absent(),
    this.redactedBy = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.forwardedFromRoom = const Value.absent(),
    this.forwardedFromEvent = const Value.absent(),
    this.forwardCount = const Value.absent(),
    this.forwardRestricted = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.starred = const Value.absent(),
    this.starredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomEventsCompanion.insert({
    required String id,
    required String roomId,
    required String senderId,
    this.senderContactId = const Value.absent(),
    required int type,
    this.content = const Value.absent(),
    this.parentId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverTs = const Value.absent(),
    this.localId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.originalContent = const Value.absent(),
    this.redacted = const Value.absent(),
    this.redactedAt = const Value.absent(),
    this.redactedBy = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.forwardedFromRoom = const Value.absent(),
    this.forwardedFromEvent = const Value.absent(),
    this.forwardCount = const Value.absent(),
    this.forwardRestricted = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.starred = const Value.absent(),
    this.starredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomId = Value(roomId),
       senderId = Value(senderId),
       type = Value(type);
  static Insertable<RoomEvent> custom({
    Expression<String>? id,
    Expression<String>? roomId,
    Expression<String>? senderId,
    Expression<String>? senderContactId,
    Expression<int>? type,
    Expression<String>? content,
    Expression<String>? parentId,
    Expression<int>? status,
    Expression<int>? createdAt,
    Expression<int>? serverTs,
    Expression<String>? localId,
    Expression<int>? editedAt,
    Expression<String>? originalContent,
    Expression<bool>? redacted,
    Expression<int>? redactedAt,
    Expression<String>? redactedBy,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<String>? forwardedFromRoom,
    Expression<String>? forwardedFromEvent,
    Expression<int>? forwardCount,
    Expression<bool>? forwardRestricted,
    Expression<int>? expiresAt,
    Expression<bool>? starred,
    Expression<int>? starredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (senderId != null) 'sender_id': senderId,
      if (senderContactId != null) 'sender_contact_id': senderContactId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (parentId != null) 'parent_id': parentId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (serverTs != null) 'server_ts': serverTs,
      if (localId != null) 'local_id': localId,
      if (editedAt != null) 'edited_at': editedAt,
      if (originalContent != null) 'original_content': originalContent,
      if (redacted != null) 'redacted': redacted,
      if (redactedAt != null) 'redacted_at': redactedAt,
      if (redactedBy != null) 'redacted_by': redactedBy,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (forwardedFromRoom != null) 'forwarded_from_room': forwardedFromRoom,
      if (forwardedFromEvent != null)
        'forwarded_from_event': forwardedFromEvent,
      if (forwardCount != null) 'forward_count': forwardCount,
      if (forwardRestricted != null) 'forward_restricted': forwardRestricted,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (starred != null) 'starred': starred,
      if (starredAt != null) 'starred_at': starredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? roomId,
    Value<String>? senderId,
    Value<String?>? senderContactId,
    Value<int>? type,
    Value<String?>? content,
    Value<String?>? parentId,
    Value<int>? status,
    Value<int?>? createdAt,
    Value<int?>? serverTs,
    Value<String?>? localId,
    Value<int?>? editedAt,
    Value<String?>? originalContent,
    Value<bool>? redacted,
    Value<int?>? redactedAt,
    Value<String?>? redactedBy,
    Value<int>? retryCount,
    Value<String?>? errorMessage,
    Value<String?>? forwardedFromRoom,
    Value<String?>? forwardedFromEvent,
    Value<int>? forwardCount,
    Value<bool>? forwardRestricted,
    Value<int?>? expiresAt,
    Value<bool>? starred,
    Value<int?>? starredAt,
    Value<int>? rowid,
  }) {
    return RoomEventsCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderContactId: senderContactId ?? this.senderContactId,
      type: type ?? this.type,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      serverTs: serverTs ?? this.serverTs,
      localId: localId ?? this.localId,
      editedAt: editedAt ?? this.editedAt,
      originalContent: originalContent ?? this.originalContent,
      redacted: redacted ?? this.redacted,
      redactedAt: redactedAt ?? this.redactedAt,
      redactedBy: redactedBy ?? this.redactedBy,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      forwardedFromRoom: forwardedFromRoom ?? this.forwardedFromRoom,
      forwardedFromEvent: forwardedFromEvent ?? this.forwardedFromEvent,
      forwardCount: forwardCount ?? this.forwardCount,
      forwardRestricted: forwardRestricted ?? this.forwardRestricted,
      expiresAt: expiresAt ?? this.expiresAt,
      starred: starred ?? this.starred,
      starredAt: starredAt ?? this.starredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderContactId.present) {
      map['sender_contact_id'] = Variable<String>(senderContactId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (serverTs.present) {
      map['server_ts'] = Variable<int>(serverTs.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (originalContent.present) {
      map['original_content'] = Variable<String>(originalContent.value);
    }
    if (redacted.present) {
      map['redacted'] = Variable<bool>(redacted.value);
    }
    if (redactedAt.present) {
      map['redacted_at'] = Variable<int>(redactedAt.value);
    }
    if (redactedBy.present) {
      map['redacted_by'] = Variable<String>(redactedBy.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (forwardedFromRoom.present) {
      map['forwarded_from_room'] = Variable<String>(forwardedFromRoom.value);
    }
    if (forwardedFromEvent.present) {
      map['forwarded_from_event'] = Variable<String>(forwardedFromEvent.value);
    }
    if (forwardCount.present) {
      map['forward_count'] = Variable<int>(forwardCount.value);
    }
    if (forwardRestricted.present) {
      map['forward_restricted'] = Variable<bool>(forwardRestricted.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (starred.present) {
      map['starred'] = Variable<bool>(starred.value);
    }
    if (starredAt.present) {
      map['starred_at'] = Variable<int>(starredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomEventsCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('senderContactId: $senderContactId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('parentId: $parentId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverTs: $serverTs, ')
          ..write('localId: $localId, ')
          ..write('editedAt: $editedAt, ')
          ..write('originalContent: $originalContent, ')
          ..write('redacted: $redacted, ')
          ..write('redactedAt: $redactedAt, ')
          ..write('redactedBy: $redactedBy, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('forwardedFromRoom: $forwardedFromRoom, ')
          ..write('forwardedFromEvent: $forwardedFromEvent, ')
          ..write('forwardCount: $forwardCount, ')
          ..write('forwardRestricted: $forwardRestricted, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('starred: $starred, ')
          ..write('starredAt: $starredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratchetStateMeta = const VerificationMeta(
    'ratchetState',
  );
  @override
  late final GeneratedColumn<Uint8List> ratchetState =
      GeneratedColumn<Uint8List>(
        'ratchet_state',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    profileId,
    deviceId,
    ratchetState,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ratchet_state')) {
      context.handle(
        _ratchetStateMeta,
        ratchetState.isAcceptableOrUnknown(
          data['ratchet_state']!,
          _ratchetStateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ratchetState: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ratchet_state'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  /// Unique session identifier
  final String sessionId;

  /// Profile ID of the session peer
  final String profileId;

  /// Device ID of the session peer
  final String deviceId;

  /// Serialized ratchet state for session continuity
  final Uint8List? ratchetState;

  /// Session creation timestamp
  final int? createdAt;
  const Session({
    required this.sessionId,
    required this.profileId,
    required this.deviceId,
    this.ratchetState,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['profile_id'] = Variable<String>(profileId);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || ratchetState != null) {
      map['ratchet_state'] = Variable<Uint8List>(ratchetState);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      sessionId: Value(sessionId),
      profileId: Value(profileId),
      deviceId: Value(deviceId),
      ratchetState: ratchetState == null && nullToAbsent
          ? const Value.absent()
          : Value(ratchetState),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      profileId: serializer.fromJson<String>(json['profileId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ratchetState: serializer.fromJson<Uint8List?>(json['ratchetState']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'profileId': serializer.toJson<String>(profileId),
      'deviceId': serializer.toJson<String>(deviceId),
      'ratchetState': serializer.toJson<Uint8List?>(ratchetState),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  Session copyWith({
    String? sessionId,
    String? profileId,
    String? deviceId,
    Value<Uint8List?> ratchetState = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
  }) => Session(
    sessionId: sessionId ?? this.sessionId,
    profileId: profileId ?? this.profileId,
    deviceId: deviceId ?? this.deviceId,
    ratchetState: ratchetState.present ? ratchetState.value : this.ratchetState,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ratchetState: data.ratchetState.present
          ? data.ratchetState.value
          : this.ratchetState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('sessionId: $sessionId, ')
          ..write('profileId: $profileId, ')
          ..write('deviceId: $deviceId, ')
          ..write('ratchetState: $ratchetState, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    profileId,
    deviceId,
    $driftBlobEquality.hash(ratchetState),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.sessionId == this.sessionId &&
          other.profileId == this.profileId &&
          other.deviceId == this.deviceId &&
          $driftBlobEquality.equals(other.ratchetState, this.ratchetState) &&
          other.createdAt == this.createdAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> sessionId;
  final Value<String> profileId;
  final Value<String> deviceId;
  final Value<Uint8List?> ratchetState;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.sessionId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.ratchetState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String sessionId,
    required String profileId,
    required String deviceId,
    this.ratchetState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       profileId = Value(profileId),
       deviceId = Value(deviceId);
  static Insertable<Session> custom({
    Expression<String>? sessionId,
    Expression<String>? profileId,
    Expression<String>? deviceId,
    Expression<Uint8List>? ratchetState,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (profileId != null) 'profile_id': profileId,
      if (deviceId != null) 'device_id': deviceId,
      if (ratchetState != null) 'ratchet_state': ratchetState,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? profileId,
    Value<String>? deviceId,
    Value<Uint8List?>? ratchetState,
    Value<int?>? createdAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      profileId: profileId ?? this.profileId,
      deviceId: deviceId ?? this.deviceId,
      ratchetState: ratchetState ?? this.ratchetState,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ratchetState.present) {
      map['ratchet_state'] = Variable<Uint8List>(ratchetState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('profileId: $profileId, ')
          ..write('deviceId: $deviceId, ')
          ..write('ratchetState: $ratchetState, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrekeysTable extends Prekeys with TableInfo<$PrekeysTable, Prekey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrekeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _privateKeyMeta = const VerificationMeta(
    'privateKey',
  );
  @override
  late final GeneratedColumn<String> privateKey = GeneratedColumn<String>(
    'private_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSignedMeta = const VerificationMeta(
    'isSigned',
  );
  @override
  late final GeneratedColumn<bool> isSigned = GeneratedColumn<bool>(
    'is_signed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_signed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, publicKey, privateKey, isSigned];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prekeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prekey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    }
    if (data.containsKey('private_key')) {
      context.handle(
        _privateKeyMeta,
        privateKey.isAcceptableOrUnknown(data['private_key']!, _privateKeyMeta),
      );
    }
    if (data.containsKey('is_signed')) {
      context.handle(
        _isSignedMeta,
        isSigned.isAcceptableOrUnknown(data['is_signed']!, _isSignedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prekey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prekey(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      ),
      privateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_key'],
      ),
      isSigned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_signed'],
      )!,
    );
  }

  @override
  $PrekeysTable createAlias(String alias) {
    return $PrekeysTable(attachedDatabase, alias);
  }
}

class Prekey extends DataClass implements Insertable<Prekey> {
  /// Auto-incrementing prekey identifier
  final int id;

  /// Base64-encoded public key for sharing
  final String? publicKey;

  /// Base64-encoded private key (securely stored)
  final String? privateKey;

  /// Whether this is a signed prekey (identity verification)
  final bool isSigned;
  const Prekey({
    required this.id,
    this.publicKey,
    this.privateKey,
    required this.isSigned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    if (!nullToAbsent || privateKey != null) {
      map['private_key'] = Variable<String>(privateKey);
    }
    map['is_signed'] = Variable<bool>(isSigned);
    return map;
  }

  PrekeysCompanion toCompanion(bool nullToAbsent) {
    return PrekeysCompanion(
      id: Value(id),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      privateKey: privateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(privateKey),
      isSigned: Value(isSigned),
    );
  }

  factory Prekey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prekey(
      id: serializer.fromJson<int>(json['id']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
      privateKey: serializer.fromJson<String?>(json['privateKey']),
      isSigned: serializer.fromJson<bool>(json['isSigned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'publicKey': serializer.toJson<String?>(publicKey),
      'privateKey': serializer.toJson<String?>(privateKey),
      'isSigned': serializer.toJson<bool>(isSigned),
    };
  }

  Prekey copyWith({
    int? id,
    Value<String?> publicKey = const Value.absent(),
    Value<String?> privateKey = const Value.absent(),
    bool? isSigned,
  }) => Prekey(
    id: id ?? this.id,
    publicKey: publicKey.present ? publicKey.value : this.publicKey,
    privateKey: privateKey.present ? privateKey.value : this.privateKey,
    isSigned: isSigned ?? this.isSigned,
  );
  Prekey copyWithCompanion(PrekeysCompanion data) {
    return Prekey(
      id: data.id.present ? data.id.value : this.id,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      privateKey: data.privateKey.present
          ? data.privateKey.value
          : this.privateKey,
      isSigned: data.isSigned.present ? data.isSigned.value : this.isSigned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prekey(')
          ..write('id: $id, ')
          ..write('publicKey: $publicKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('isSigned: $isSigned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, publicKey, privateKey, isSigned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prekey &&
          other.id == this.id &&
          other.publicKey == this.publicKey &&
          other.privateKey == this.privateKey &&
          other.isSigned == this.isSigned);
}

class PrekeysCompanion extends UpdateCompanion<Prekey> {
  final Value<int> id;
  final Value<String?> publicKey;
  final Value<String?> privateKey;
  final Value<bool> isSigned;
  const PrekeysCompanion({
    this.id = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.isSigned = const Value.absent(),
  });
  PrekeysCompanion.insert({
    this.id = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.isSigned = const Value.absent(),
  });
  static Insertable<Prekey> custom({
    Expression<int>? id,
    Expression<String>? publicKey,
    Expression<String>? privateKey,
    Expression<bool>? isSigned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (publicKey != null) 'public_key': publicKey,
      if (privateKey != null) 'private_key': privateKey,
      if (isSigned != null) 'is_signed': isSigned,
    });
  }

  PrekeysCompanion copyWith({
    Value<int>? id,
    Value<String?>? publicKey,
    Value<String?>? privateKey,
    Value<bool>? isSigned,
  }) {
    return PrekeysCompanion(
      id: id ?? this.id,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      isSigned: isSigned ?? this.isSigned,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (privateKey.present) {
      map['private_key'] = Variable<String>(privateKey.value);
    }
    if (isSigned.present) {
      map['is_signed'] = Variable<bool>(isSigned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrekeysCompanion(')
          ..write('id: $id, ')
          ..write('publicKey: $publicKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('isSigned: $isSigned')
          ..write(')'))
        .toString();
  }
}

class $PendingJobsTable extends PendingJobs
    with TableInfo<$PendingJobsTable, PendingJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<int> nextRetryAt = GeneratedColumn<int>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    payload,
    createdAt,
    retryCount,
    status,
    nextRetryAt,
    priority,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_retry_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingJobsTable createAlias(String alias) {
    return $PendingJobsTable(attachedDatabase, alias);
  }
}

class PendingJob extends DataClass implements Insertable<PendingJob> {
  /// Auto-incrementing job identifier
  final int id;

  /// Job type identifier (e.g., 'send_message', 'mark_read')
  final String type;

  /// JSON-encoded job payload with operation details
  final String? payload;

  /// Job creation timestamp
  final int? createdAt;

  /// Number of retry attempts made
  final int retryCount;

  /// Job status: 'pending', 'processing', 'completed', 'failed'
  final String status;

  /// Earliest time this job can be retried (for exponential backoff)
  /// Null means job can be processed immediately
  final int? nextRetryAt;

  /// Job priority level (0=critical, 1=high, 2=normal, 3=low)
  /// Lower values are processed first
  final int priority;

  /// JSON-encoded last error information for debugging
  /// Contains error message, code, and timestamp
  final String? lastError;
  const PendingJob({
    required this.id,
    required this.type,
    this.payload,
    this.createdAt,
    required this.retryCount,
    required this.status,
    this.nextRetryAt,
    required this.priority,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<int>(nextRetryAt);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingJobsCompanion toCompanion(bool nullToAbsent) {
    return PendingJobsCompanion(
      id: Value(id),
      type: Value(type),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      priority: Value(priority),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingJob(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      nextRetryAt: serializer.fromJson<int?>(json['nextRetryAt']),
      priority: serializer.fromJson<int>(json['priority']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<int?>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'nextRetryAt': serializer.toJson<int?>(nextRetryAt),
      'priority': serializer.toJson<int>(priority),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingJob copyWith({
    int? id,
    String? type,
    Value<String?> payload = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    int? retryCount,
    String? status,
    Value<int?> nextRetryAt = const Value.absent(),
    int? priority,
    Value<String?> lastError = const Value.absent(),
  }) => PendingJob(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload.present ? payload.value : this.payload,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    status: status ?? this.status,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    priority: priority ?? this.priority,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingJob copyWithCompanion(PendingJobsCompanion data) {
    return PendingJob(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingJob(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('priority: $priority, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    payload,
    createdAt,
    retryCount,
    status,
    nextRetryAt,
    priority,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingJob &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.nextRetryAt == this.nextRetryAt &&
          other.priority == this.priority &&
          other.lastError == this.lastError);
}

class PendingJobsCompanion extends UpdateCompanion<PendingJob> {
  final Value<int> id;
  final Value<String> type;
  final Value<String?> payload;
  final Value<int?> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<int?> nextRetryAt;
  final Value<int> priority;
  final Value<String?> lastError;
  const PendingJobsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  PendingJobsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : type = Value(type);
  static Insertable<PendingJob> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<int>? nextRetryAt,
    Expression<int>? priority,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (priority != null) 'priority': priority,
      if (lastError != null) 'last_error': lastError,
    });
  }

  PendingJobsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String?>? payload,
    Value<int?>? createdAt,
    Value<int>? retryCount,
    Value<String>? status,
    Value<int?>? nextRetryAt,
    Value<int>? priority,
    Value<String?>? lastError,
  }) {
    return PendingJobsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      priority: priority ?? this.priority,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<int>(nextRetryAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingJobsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('priority: $priority, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initiatorIdMeta = const VerificationMeta(
    'initiatorId',
  );
  @override
  late final GeneratedColumn<String> initiatorId = GeneratedColumn<String>(
    'initiator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomId,
    amount,
    currency,
    status,
    initiatorId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('initiator_id')) {
      context.handle(
        _initiatorIdMeta,
        initiatorId.isAcceptableOrUnknown(
          data['initiator_id']!,
          _initiatorIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      initiatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initiator_id'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  /// Unique transaction identifier
  final String id;

  /// Room this transaction belongs to (foreign key)
  final String roomId;

  /// Transaction amount as decimal string
  final String? amount;

  /// Currency code (e.g., 'KES', 'USD')
  final String? currency;

  /// Transaction status: 'pending', 'completed', 'cancelled'
  final String? status;

  /// Profile ID of the transaction initiator
  final String? initiatorId;
  const Transaction({
    required this.id,
    required this.roomId,
    this.amount,
    this.currency,
    this.status,
    this.initiatorId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room_id'] = Variable<String>(roomId);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<String>(amount);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || initiatorId != null) {
      map['initiator_id'] = Variable<String>(initiatorId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      roomId: Value(roomId),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      initiatorId: initiatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(initiatorId),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      amount: serializer.fromJson<String?>(json['amount']),
      currency: serializer.fromJson<String?>(json['currency']),
      status: serializer.fromJson<String?>(json['status']),
      initiatorId: serializer.fromJson<String?>(json['initiatorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roomId': serializer.toJson<String>(roomId),
      'amount': serializer.toJson<String?>(amount),
      'currency': serializer.toJson<String?>(currency),
      'status': serializer.toJson<String?>(status),
      'initiatorId': serializer.toJson<String?>(initiatorId),
    };
  }

  Transaction copyWith({
    String? id,
    String? roomId,
    Value<String?> amount = const Value.absent(),
    Value<String?> currency = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> initiatorId = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    amount: amount.present ? amount.value : this.amount,
    currency: currency.present ? currency.value : this.currency,
    status: status.present ? status.value : this.status,
    initiatorId: initiatorId.present ? initiatorId.value : this.initiatorId,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      status: data.status.present ? data.status.value : this.status,
      initiatorId: data.initiatorId.present
          ? data.initiatorId.value
          : this.initiatorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('initiatorId: $initiatorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, roomId, amount, currency, status, initiatorId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.status == this.status &&
          other.initiatorId == this.initiatorId);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> roomId;
  final Value<String?> amount;
  final Value<String?> currency;
  final Value<String?> status;
  final Value<String?> initiatorId;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.status = const Value.absent(),
    this.initiatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String roomId,
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.status = const Value.absent(),
    this.initiatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomId = Value(roomId);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? roomId,
    Expression<String>? amount,
    Expression<String>? currency,
    Expression<String>? status,
    Expression<String>? initiatorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (status != null) 'status': status,
      if (initiatorId != null) 'initiator_id': initiatorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? roomId,
    Value<String?>? amount,
    Value<String?>? currency,
    Value<String?>? status,
    Value<String?>? initiatorId,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      initiatorId: initiatorId ?? this.initiatorId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (initiatorId.present) {
      map['initiator_id'] = Variable<String>(initiatorId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('initiatorId: $initiatorId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  /// Unique key identifier
  final String key;

  /// Stored value (can be JSON for complex data)
  final String? value;

  /// Last update timestamp
  final int? updatedAt;
  const SyncMetadataData({required this.key, this.value, this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  SyncMetadataData copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
  }) => SyncMetadataData(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int?>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  /// Setting key (e.g., 'theme_mode', 'font_size')
  final String key;

  /// Setting value (stored as string, can be JSON for complex values)
  final String value;

  /// Last update timestamp (milliseconds since epoch)
  final int updatedAt;
  const UserSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  UserSetting copyWith({String? key, String? value, int? updatedAt}) =>
      UserSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const UserSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<UserSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, Draft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToIdMeta = const VerificationMeta(
    'replyToId',
  );
  @override
  late final GeneratedColumn<String> replyToId = GeneratedColumn<String>(
    'reply_to_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [roomId, content, replyToId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Draft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
        _replyToIdMeta,
        replyToId.isAcceptableOrUnknown(data['reply_to_id']!, _replyToIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {roomId};
  @override
  Draft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Draft(
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      replyToId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class Draft extends DataClass implements Insertable<Draft> {
  /// Room ID this draft belongs to (primary key)
  final String roomId;

  /// Draft message content
  final String content;

  /// Optional parent message ID for reply drafts
  final String? replyToId;

  /// Last update timestamp (milliseconds since epoch)
  final int updatedAt;
  const Draft({
    required this.roomId,
    required this.content,
    this.replyToId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['room_id'] = Variable<String>(roomId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || replyToId != null) {
      map['reply_to_id'] = Variable<String>(replyToId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      roomId: Value(roomId),
      content: Value(content),
      replyToId: replyToId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToId),
      updatedAt: Value(updatedAt),
    );
  }

  factory Draft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Draft(
      roomId: serializer.fromJson<String>(json['roomId']),
      content: serializer.fromJson<String>(json['content']),
      replyToId: serializer.fromJson<String?>(json['replyToId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roomId': serializer.toJson<String>(roomId),
      'content': serializer.toJson<String>(content),
      'replyToId': serializer.toJson<String?>(replyToId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Draft copyWith({
    String? roomId,
    String? content,
    Value<String?> replyToId = const Value.absent(),
    int? updatedAt,
  }) => Draft(
    roomId: roomId ?? this.roomId,
    content: content ?? this.content,
    replyToId: replyToId.present ? replyToId.value : this.replyToId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Draft copyWithCompanion(DraftsCompanion data) {
    return Draft(
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      content: data.content.present ? data.content.value : this.content,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Draft(')
          ..write('roomId: $roomId, ')
          ..write('content: $content, ')
          ..write('replyToId: $replyToId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roomId, content, replyToId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Draft &&
          other.roomId == this.roomId &&
          other.content == this.content &&
          other.replyToId == this.replyToId &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<Draft> {
  final Value<String> roomId;
  final Value<String> content;
  final Value<String?> replyToId;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DraftsCompanion({
    this.roomId = const Value.absent(),
    this.content = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftsCompanion.insert({
    required String roomId,
    required String content,
    this.replyToId = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : roomId = Value(roomId),
       content = Value(content),
       updatedAt = Value(updatedAt);
  static Insertable<Draft> custom({
    Expression<String>? roomId,
    Expression<String>? content,
    Expression<String>? replyToId,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roomId != null) 'room_id': roomId,
      if (content != null) 'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftsCompanion copyWith({
    Value<String>? roomId,
    Value<String>? content,
    Value<String?>? replyToId,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DraftsCompanion(
      roomId: roomId ?? this.roomId,
      content: content ?? this.content,
      replyToId: replyToId ?? this.replyToId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<String>(replyToId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('roomId: $roomId, ')
          ..write('content: $content, ')
          ..write('replyToId: $replyToId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadReceiptsTable extends ReadReceipts
    with TableInfo<$ReadReceiptsTable, ReadReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<int> readAt = GeneratedColumn<int>(
    'read_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    roomId,
    profileId,
    readAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    } else if (isInserting) {
      context.missing(_readAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadReceipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at'],
      )!,
    );
  }

  @override
  $ReadReceiptsTable createAlias(String alias) {
    return $ReadReceiptsTable(attachedDatabase, alias);
  }
}

class ReadReceipt extends DataClass implements Insertable<ReadReceipt> {
  /// Auto-incrementing primary key
  final int id;

  /// Event/message ID that was read
  final String eventId;

  /// Room ID for efficient querying
  final String roomId;

  /// Profile ID of the reader
  final String profileId;

  /// Timestamp when the message was read (milliseconds since epoch)
  final int readAt;
  const ReadReceipt({
    required this.id,
    required this.eventId,
    required this.roomId,
    required this.profileId,
    required this.readAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['room_id'] = Variable<String>(roomId);
    map['profile_id'] = Variable<String>(profileId);
    map['read_at'] = Variable<int>(readAt);
    return map;
  }

  ReadReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReadReceiptsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      roomId: Value(roomId),
      profileId: Value(profileId),
      readAt: Value(readAt),
    );
  }

  factory ReadReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadReceipt(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      profileId: serializer.fromJson<String>(json['profileId']),
      readAt: serializer.fromJson<int>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'roomId': serializer.toJson<String>(roomId),
      'profileId': serializer.toJson<String>(profileId),
      'readAt': serializer.toJson<int>(readAt),
    };
  }

  ReadReceipt copyWith({
    int? id,
    String? eventId,
    String? roomId,
    String? profileId,
    int? readAt,
  }) => ReadReceipt(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    roomId: roomId ?? this.roomId,
    profileId: profileId ?? this.profileId,
    readAt: readAt ?? this.readAt,
  );
  ReadReceipt copyWithCompanion(ReadReceiptsCompanion data) {
    return ReadReceipt(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadReceipt(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('roomId: $roomId, ')
          ..write('profileId: $profileId, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, roomId, profileId, readAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadReceipt &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.roomId == this.roomId &&
          other.profileId == this.profileId &&
          other.readAt == this.readAt);
}

class ReadReceiptsCompanion extends UpdateCompanion<ReadReceipt> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> roomId;
  final Value<String> profileId;
  final Value<int> readAt;
  const ReadReceiptsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.readAt = const Value.absent(),
  });
  ReadReceiptsCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String roomId,
    required String profileId,
    required int readAt,
  }) : eventId = Value(eventId),
       roomId = Value(roomId),
       profileId = Value(profileId),
       readAt = Value(readAt);
  static Insertable<ReadReceipt> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? roomId,
    Expression<String>? profileId,
    Expression<int>? readAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (roomId != null) 'room_id': roomId,
      if (profileId != null) 'profile_id': profileId,
      if (readAt != null) 'read_at': readAt,
    });
  }

  ReadReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String>? eventId,
    Value<String>? roomId,
    Value<String>? profileId,
    Value<int>? readAt,
  }) {
    return ReadReceiptsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      roomId: roomId ?? this.roomId,
      profileId: profileId ?? this.profileId,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<int>(readAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('roomId: $roomId, ')
          ..write('profileId: $profileId, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }
}

class $ReportsTable extends Reports with TableInfo<$ReportsTable, Report> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportedUserIdMeta = const VerificationMeta(
    'reportedUserId',
  );
  @override
  late final GeneratedColumn<String> reportedUserId = GeneratedColumn<String>(
    'reported_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evidenceEventIdsMeta = const VerificationMeta(
    'evidenceEventIds',
  );
  @override
  late final GeneratedColumn<String> evidenceEventIds = GeneratedColumn<String>(
    'evidence_event_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportedAtMeta = const VerificationMeta(
    'reportedAt',
  );
  @override
  late final GeneratedColumn<int> reportedAt = GeneratedColumn<int>(
    'reported_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reportedUserId,
    reason,
    details,
    evidenceEventIds,
    reportedAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Report> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reported_user_id')) {
      context.handle(
        _reportedUserIdMeta,
        reportedUserId.isAcceptableOrUnknown(
          data['reported_user_id']!,
          _reportedUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reportedUserIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('evidence_event_ids')) {
      context.handle(
        _evidenceEventIdsMeta,
        evidenceEventIds.isAcceptableOrUnknown(
          data['evidence_event_ids']!,
          _evidenceEventIdsMeta,
        ),
      );
    }
    if (data.containsKey('reported_at')) {
      context.handle(
        _reportedAtMeta,
        reportedAt.isAcceptableOrUnknown(data['reported_at']!, _reportedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reportedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Report map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Report(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reportedUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reported_user_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      evidenceEventIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_event_ids'],
      ),
      reportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reported_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ReportsTable createAlias(String alias) {
    return $ReportsTable(attachedDatabase, alias);
  }
}

class Report extends DataClass implements Insertable<Report> {
  /// Unique report identifier
  final String id;

  /// Profile ID of the user being reported
  final String reportedUserId;

  /// Report reason category (spam, harassment, inappropriate_content, other)
  final String reason;

  /// Additional details provided by the reporter
  final String? details;

  /// JSON array of event IDs used as evidence
  final String? evidenceEventIds;

  /// Timestamp when the report was created (milliseconds since epoch)
  final int reportedAt;

  /// Report status: pending, reviewed, resolved, dismissed
  final String status;
  const Report({
    required this.id,
    required this.reportedUserId,
    required this.reason,
    this.details,
    this.evidenceEventIds,
    required this.reportedAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reported_user_id'] = Variable<String>(reportedUserId);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || evidenceEventIds != null) {
      map['evidence_event_ids'] = Variable<String>(evidenceEventIds);
    }
    map['reported_at'] = Variable<int>(reportedAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  ReportsCompanion toCompanion(bool nullToAbsent) {
    return ReportsCompanion(
      id: Value(id),
      reportedUserId: Value(reportedUserId),
      reason: Value(reason),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      evidenceEventIds: evidenceEventIds == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceEventIds),
      reportedAt: Value(reportedAt),
      status: Value(status),
    );
  }

  factory Report.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Report(
      id: serializer.fromJson<String>(json['id']),
      reportedUserId: serializer.fromJson<String>(json['reportedUserId']),
      reason: serializer.fromJson<String>(json['reason']),
      details: serializer.fromJson<String?>(json['details']),
      evidenceEventIds: serializer.fromJson<String?>(json['evidenceEventIds']),
      reportedAt: serializer.fromJson<int>(json['reportedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reportedUserId': serializer.toJson<String>(reportedUserId),
      'reason': serializer.toJson<String>(reason),
      'details': serializer.toJson<String?>(details),
      'evidenceEventIds': serializer.toJson<String?>(evidenceEventIds),
      'reportedAt': serializer.toJson<int>(reportedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  Report copyWith({
    String? id,
    String? reportedUserId,
    String? reason,
    Value<String?> details = const Value.absent(),
    Value<String?> evidenceEventIds = const Value.absent(),
    int? reportedAt,
    String? status,
  }) => Report(
    id: id ?? this.id,
    reportedUserId: reportedUserId ?? this.reportedUserId,
    reason: reason ?? this.reason,
    details: details.present ? details.value : this.details,
    evidenceEventIds: evidenceEventIds.present
        ? evidenceEventIds.value
        : this.evidenceEventIds,
    reportedAt: reportedAt ?? this.reportedAt,
    status: status ?? this.status,
  );
  Report copyWithCompanion(ReportsCompanion data) {
    return Report(
      id: data.id.present ? data.id.value : this.id,
      reportedUserId: data.reportedUserId.present
          ? data.reportedUserId.value
          : this.reportedUserId,
      reason: data.reason.present ? data.reason.value : this.reason,
      details: data.details.present ? data.details.value : this.details,
      evidenceEventIds: data.evidenceEventIds.present
          ? data.evidenceEventIds.value
          : this.evidenceEventIds,
      reportedAt: data.reportedAt.present
          ? data.reportedAt.value
          : this.reportedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Report(')
          ..write('id: $id, ')
          ..write('reportedUserId: $reportedUserId, ')
          ..write('reason: $reason, ')
          ..write('details: $details, ')
          ..write('evidenceEventIds: $evidenceEventIds, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reportedUserId,
    reason,
    details,
    evidenceEventIds,
    reportedAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Report &&
          other.id == this.id &&
          other.reportedUserId == this.reportedUserId &&
          other.reason == this.reason &&
          other.details == this.details &&
          other.evidenceEventIds == this.evidenceEventIds &&
          other.reportedAt == this.reportedAt &&
          other.status == this.status);
}

class ReportsCompanion extends UpdateCompanion<Report> {
  final Value<String> id;
  final Value<String> reportedUserId;
  final Value<String> reason;
  final Value<String?> details;
  final Value<String?> evidenceEventIds;
  final Value<int> reportedAt;
  final Value<String> status;
  final Value<int> rowid;
  const ReportsCompanion({
    this.id = const Value.absent(),
    this.reportedUserId = const Value.absent(),
    this.reason = const Value.absent(),
    this.details = const Value.absent(),
    this.evidenceEventIds = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportsCompanion.insert({
    required String id,
    required String reportedUserId,
    required String reason,
    this.details = const Value.absent(),
    this.evidenceEventIds = const Value.absent(),
    required int reportedAt,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reportedUserId = Value(reportedUserId),
       reason = Value(reason),
       reportedAt = Value(reportedAt);
  static Insertable<Report> custom({
    Expression<String>? id,
    Expression<String>? reportedUserId,
    Expression<String>? reason,
    Expression<String>? details,
    Expression<String>? evidenceEventIds,
    Expression<int>? reportedAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportedUserId != null) 'reported_user_id': reportedUserId,
      if (reason != null) 'reason': reason,
      if (details != null) 'details': details,
      if (evidenceEventIds != null) 'evidence_event_ids': evidenceEventIds,
      if (reportedAt != null) 'reported_at': reportedAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? reportedUserId,
    Value<String>? reason,
    Value<String?>? details,
    Value<String?>? evidenceEventIds,
    Value<int>? reportedAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ReportsCompanion(
      id: id ?? this.id,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      evidenceEventIds: evidenceEventIds ?? this.evidenceEventIds,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reportedUserId.present) {
      map['reported_user_id'] = Variable<String>(reportedUserId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (evidenceEventIds.present) {
      map['evidence_event_ids'] = Variable<String>(evidenceEventIds.value);
    }
    if (reportedAt.present) {
      map['reported_at'] = Variable<int>(reportedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportsCompanion(')
          ..write('id: $id, ')
          ..write('reportedUserId: $reportedUserId, ')
          ..write('reason: $reason, ')
          ..write('details: $details, ')
          ..write('evidenceEventIds: $evidenceEventIds, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InviteLinksTable extends InviteLinks
    with TableInfo<$InviteLinksTable, InviteLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InviteLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxUsesMeta = const VerificationMeta(
    'maxUses',
  );
  @override
  late final GeneratedColumn<int> maxUses = GeneratedColumn<int>(
    'max_uses',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _revokedMeta = const VerificationMeta(
    'revoked',
  );
  @override
  late final GeneratedColumn<bool> revoked = GeneratedColumn<bool>(
    'revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("revoked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _requiresApprovalMeta = const VerificationMeta(
    'requiresApproval',
  );
  @override
  late final GeneratedColumn<bool> requiresApproval = GeneratedColumn<bool>(
    'requires_approval',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_approval" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomId,
    code,
    createdBy,
    createdAt,
    expiresAt,
    maxUses,
    useCount,
    revoked,
    requiresApproval,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invite_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<InviteLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('max_uses')) {
      context.handle(
        _maxUsesMeta,
        maxUses.isAcceptableOrUnknown(data['max_uses']!, _maxUsesMeta),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('revoked')) {
      context.handle(
        _revokedMeta,
        revoked.isAcceptableOrUnknown(data['revoked']!, _revokedMeta),
      );
    }
    if (data.containsKey('requires_approval')) {
      context.handle(
        _requiresApprovalMeta,
        requiresApproval.isAcceptableOrUnknown(
          data['requires_approval']!,
          _requiresApprovalMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InviteLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InviteLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      ),
      maxUses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_uses'],
      ),
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      revoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}revoked'],
      )!,
      requiresApproval: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_approval'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
    );
  }

  @override
  $InviteLinksTable createAlias(String alias) {
    return $InviteLinksTable(attachedDatabase, alias);
  }
}

class InviteLink extends DataClass implements Insertable<InviteLink> {
  /// Unique invite link identifier
  final String id;

  /// Room this invite links to (foreign key)
  final String roomId;

  /// Unique invite code for URL (e.g., chat.app/join/{code})
  final String code;

  /// Profile ID of the user who created this link
  final String createdBy;

  /// Creation timestamp (milliseconds since epoch)
  final int createdAt;

  /// Optional expiration timestamp (milliseconds since epoch, null = never expires)
  final int? expiresAt;

  /// Optional maximum number of uses (null = unlimited)
  final int? maxUses;

  /// Current number of times this link has been used
  final int useCount;

  /// Whether this link has been revoked by an admin
  final bool revoked;

  /// Whether joining via this link requires admin approval
  final bool requiresApproval;

  /// Optional custom name/label for the link
  final String? name;
  const InviteLink({
    required this.id,
    required this.roomId,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.maxUses,
    required this.useCount,
    required this.revoked,
    required this.requiresApproval,
    this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room_id'] = Variable<String>(roomId);
    map['code'] = Variable<String>(code);
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    if (!nullToAbsent || maxUses != null) {
      map['max_uses'] = Variable<int>(maxUses);
    }
    map['use_count'] = Variable<int>(useCount);
    map['revoked'] = Variable<bool>(revoked);
    map['requires_approval'] = Variable<bool>(requiresApproval);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  InviteLinksCompanion toCompanion(bool nullToAbsent) {
    return InviteLinksCompanion(
      id: Value(id),
      roomId: Value(roomId),
      code: Value(code),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      maxUses: maxUses == null && nullToAbsent
          ? const Value.absent()
          : Value(maxUses),
      useCount: Value(useCount),
      revoked: Value(revoked),
      requiresApproval: Value(requiresApproval),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory InviteLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InviteLink(
      id: serializer.fromJson<String>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      code: serializer.fromJson<String>(json['code']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      maxUses: serializer.fromJson<int?>(json['maxUses']),
      useCount: serializer.fromJson<int>(json['useCount']),
      revoked: serializer.fromJson<bool>(json['revoked']),
      requiresApproval: serializer.fromJson<bool>(json['requiresApproval']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roomId': serializer.toJson<String>(roomId),
      'code': serializer.toJson<String>(code),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'maxUses': serializer.toJson<int?>(maxUses),
      'useCount': serializer.toJson<int>(useCount),
      'revoked': serializer.toJson<bool>(revoked),
      'requiresApproval': serializer.toJson<bool>(requiresApproval),
      'name': serializer.toJson<String?>(name),
    };
  }

  InviteLink copyWith({
    String? id,
    String? roomId,
    String? code,
    String? createdBy,
    int? createdAt,
    Value<int?> expiresAt = const Value.absent(),
    Value<int?> maxUses = const Value.absent(),
    int? useCount,
    bool? revoked,
    bool? requiresApproval,
    Value<String?> name = const Value.absent(),
  }) => InviteLink(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    code: code ?? this.code,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    maxUses: maxUses.present ? maxUses.value : this.maxUses,
    useCount: useCount ?? this.useCount,
    revoked: revoked ?? this.revoked,
    requiresApproval: requiresApproval ?? this.requiresApproval,
    name: name.present ? name.value : this.name,
  );
  InviteLink copyWithCompanion(InviteLinksCompanion data) {
    return InviteLink(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      code: data.code.present ? data.code.value : this.code,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      maxUses: data.maxUses.present ? data.maxUses.value : this.maxUses,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      revoked: data.revoked.present ? data.revoked.value : this.revoked,
      requiresApproval: data.requiresApproval.present
          ? data.requiresApproval.value
          : this.requiresApproval,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InviteLink(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('code: $code, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('maxUses: $maxUses, ')
          ..write('useCount: $useCount, ')
          ..write('revoked: $revoked, ')
          ..write('requiresApproval: $requiresApproval, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roomId,
    code,
    createdBy,
    createdAt,
    expiresAt,
    maxUses,
    useCount,
    revoked,
    requiresApproval,
    name,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InviteLink &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.code == this.code &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.maxUses == this.maxUses &&
          other.useCount == this.useCount &&
          other.revoked == this.revoked &&
          other.requiresApproval == this.requiresApproval &&
          other.name == this.name);
}

class InviteLinksCompanion extends UpdateCompanion<InviteLink> {
  final Value<String> id;
  final Value<String> roomId;
  final Value<String> code;
  final Value<String> createdBy;
  final Value<int> createdAt;
  final Value<int?> expiresAt;
  final Value<int?> maxUses;
  final Value<int> useCount;
  final Value<bool> revoked;
  final Value<bool> requiresApproval;
  final Value<String?> name;
  final Value<int> rowid;
  const InviteLinksCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.code = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.maxUses = const Value.absent(),
    this.useCount = const Value.absent(),
    this.revoked = const Value.absent(),
    this.requiresApproval = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InviteLinksCompanion.insert({
    required String id,
    required String roomId,
    required String code,
    required String createdBy,
    required int createdAt,
    this.expiresAt = const Value.absent(),
    this.maxUses = const Value.absent(),
    this.useCount = const Value.absent(),
    this.revoked = const Value.absent(),
    this.requiresApproval = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomId = Value(roomId),
       code = Value(code),
       createdBy = Value(createdBy),
       createdAt = Value(createdAt);
  static Insertable<InviteLink> custom({
    Expression<String>? id,
    Expression<String>? roomId,
    Expression<String>? code,
    Expression<String>? createdBy,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
    Expression<int>? maxUses,
    Expression<int>? useCount,
    Expression<bool>? revoked,
    Expression<bool>? requiresApproval,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (code != null) 'code': code,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (maxUses != null) 'max_uses': maxUses,
      if (useCount != null) 'use_count': useCount,
      if (revoked != null) 'revoked': revoked,
      if (requiresApproval != null) 'requires_approval': requiresApproval,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InviteLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? roomId,
    Value<String>? code,
    Value<String>? createdBy,
    Value<int>? createdAt,
    Value<int?>? expiresAt,
    Value<int?>? maxUses,
    Value<int>? useCount,
    Value<bool>? revoked,
    Value<bool>? requiresApproval,
    Value<String?>? name,
    Value<int>? rowid,
  }) {
    return InviteLinksCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      useCount: useCount ?? this.useCount,
      revoked: revoked ?? this.revoked,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (maxUses.present) {
      map['max_uses'] = Variable<int>(maxUses.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (revoked.present) {
      map['revoked'] = Variable<bool>(revoked.value);
    }
    if (requiresApproval.present) {
      map['requires_approval'] = Variable<bool>(requiresApproval.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InviteLinksCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('code: $code, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('maxUses: $maxUses, ')
          ..write('useCount: $useCount, ')
          ..write('revoked: $revoked, ')
          ..write('requiresApproval: $requiresApproval, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InviteLinkJoinsTable extends InviteLinkJoins
    with TableInfo<$InviteLinkJoinsTable, InviteLinkJoin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InviteLinkJoinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _inviteLinkIdMeta = const VerificationMeta(
    'inviteLinkId',
  );
  @override
  late final GeneratedColumn<String> inviteLinkId = GeneratedColumn<String>(
    'invite_link_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invite_links (id)',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<int> joinedAt = GeneratedColumn<int>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inviteLinkId,
    profileId,
    joinedAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invite_link_joins';
  @override
  VerificationContext validateIntegrity(
    Insertable<InviteLinkJoin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invite_link_id')) {
      context.handle(
        _inviteLinkIdMeta,
        inviteLinkId.isAcceptableOrUnknown(
          data['invite_link_id']!,
          _inviteLinkIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inviteLinkIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InviteLinkJoin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InviteLinkJoin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      inviteLinkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_link_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}joined_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $InviteLinkJoinsTable createAlias(String alias) {
    return $InviteLinkJoinsTable(attachedDatabase, alias);
  }
}

class InviteLinkJoin extends DataClass implements Insertable<InviteLinkJoin> {
  /// Auto-incrementing primary key
  final int id;

  /// The invite link that was used
  final String inviteLinkId;

  /// Profile ID of the user who joined
  final String profileId;

  /// Timestamp when the user joined (milliseconds since epoch)
  final int joinedAt;

  /// Approval status: 'approved', 'pending', 'rejected'
  final String status;
  const InviteLinkJoin({
    required this.id,
    required this.inviteLinkId,
    required this.profileId,
    required this.joinedAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invite_link_id'] = Variable<String>(inviteLinkId);
    map['profile_id'] = Variable<String>(profileId);
    map['joined_at'] = Variable<int>(joinedAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  InviteLinkJoinsCompanion toCompanion(bool nullToAbsent) {
    return InviteLinkJoinsCompanion(
      id: Value(id),
      inviteLinkId: Value(inviteLinkId),
      profileId: Value(profileId),
      joinedAt: Value(joinedAt),
      status: Value(status),
    );
  }

  factory InviteLinkJoin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InviteLinkJoin(
      id: serializer.fromJson<int>(json['id']),
      inviteLinkId: serializer.fromJson<String>(json['inviteLinkId']),
      profileId: serializer.fromJson<String>(json['profileId']),
      joinedAt: serializer.fromJson<int>(json['joinedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'inviteLinkId': serializer.toJson<String>(inviteLinkId),
      'profileId': serializer.toJson<String>(profileId),
      'joinedAt': serializer.toJson<int>(joinedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  InviteLinkJoin copyWith({
    int? id,
    String? inviteLinkId,
    String? profileId,
    int? joinedAt,
    String? status,
  }) => InviteLinkJoin(
    id: id ?? this.id,
    inviteLinkId: inviteLinkId ?? this.inviteLinkId,
    profileId: profileId ?? this.profileId,
    joinedAt: joinedAt ?? this.joinedAt,
    status: status ?? this.status,
  );
  InviteLinkJoin copyWithCompanion(InviteLinkJoinsCompanion data) {
    return InviteLinkJoin(
      id: data.id.present ? data.id.value : this.id,
      inviteLinkId: data.inviteLinkId.present
          ? data.inviteLinkId.value
          : this.inviteLinkId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InviteLinkJoin(')
          ..write('id: $id, ')
          ..write('inviteLinkId: $inviteLinkId, ')
          ..write('profileId: $profileId, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, inviteLinkId, profileId, joinedAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InviteLinkJoin &&
          other.id == this.id &&
          other.inviteLinkId == this.inviteLinkId &&
          other.profileId == this.profileId &&
          other.joinedAt == this.joinedAt &&
          other.status == this.status);
}

class InviteLinkJoinsCompanion extends UpdateCompanion<InviteLinkJoin> {
  final Value<int> id;
  final Value<String> inviteLinkId;
  final Value<String> profileId;
  final Value<int> joinedAt;
  final Value<String> status;
  const InviteLinkJoinsCompanion({
    this.id = const Value.absent(),
    this.inviteLinkId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  InviteLinkJoinsCompanion.insert({
    this.id = const Value.absent(),
    required String inviteLinkId,
    required String profileId,
    required int joinedAt,
    this.status = const Value.absent(),
  }) : inviteLinkId = Value(inviteLinkId),
       profileId = Value(profileId),
       joinedAt = Value(joinedAt);
  static Insertable<InviteLinkJoin> custom({
    Expression<int>? id,
    Expression<String>? inviteLinkId,
    Expression<String>? profileId,
    Expression<int>? joinedAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inviteLinkId != null) 'invite_link_id': inviteLinkId,
      if (profileId != null) 'profile_id': profileId,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (status != null) 'status': status,
    });
  }

  InviteLinkJoinsCompanion copyWith({
    Value<int>? id,
    Value<String>? inviteLinkId,
    Value<String>? profileId,
    Value<int>? joinedAt,
    Value<String>? status,
  }) {
    return InviteLinkJoinsCompanion(
      id: id ?? this.id,
      inviteLinkId: inviteLinkId ?? this.inviteLinkId,
      profileId: profileId ?? this.profileId,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (inviteLinkId.present) {
      map['invite_link_id'] = Variable<String>(inviteLinkId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<int>(joinedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InviteLinkJoinsCompanion(')
          ..write('id: $id, ')
          ..write('inviteLinkId: $inviteLinkId, ')
          ..write('profileId: $profileId, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $UploadChunksTable extends UploadChunks
    with TableInfo<$UploadChunksTable, UploadChunk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadIdMeta = const VerificationMeta(
    'uploadId',
  );
  @override
  late final GeneratedColumn<String> uploadId = GeneratedColumn<String>(
    'upload_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _chunkSizeMeta = const VerificationMeta(
    'chunkSize',
  );
  @override
  late final GeneratedColumn<int> chunkSize = GeneratedColumn<int>(
    'chunk_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    uploadId,
    chunkIndex,
    chunkSize,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadChunk> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('upload_id')) {
      context.handle(
        _uploadIdMeta,
        uploadId.isAcceptableOrUnknown(data['upload_id']!, _uploadIdMeta),
      );
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    }
    if (data.containsKey('chunk_size')) {
      context.handle(
        _chunkSizeMeta,
        chunkSize.isAcceptableOrUnknown(data['chunk_size']!, _chunkSizeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadChunk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadChunk(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      uploadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_id'],
      ),
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      chunkSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_size'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UploadChunksTable createAlias(String alias) {
    return $UploadChunksTable(attachedDatabase, alias);
  }
}

class UploadChunk extends DataClass implements Insertable<UploadChunk> {
  /// Auto-incrementing primary key
  final int id;

  /// Local message ID this upload is associated with
  final String localId;

  /// Server-assigned upload ID for resumable uploads
  final String? uploadId;

  /// Index of this chunk (0-based, -1 for metadata row)
  final int chunkIndex;

  /// Size of this chunk in bytes
  final int chunkSize;

  /// Timestamp when this chunk was uploaded (milliseconds since epoch)
  final int createdAt;
  const UploadChunk({
    required this.id,
    required this.localId,
    this.uploadId,
    required this.chunkIndex,
    required this.chunkSize,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || uploadId != null) {
      map['upload_id'] = Variable<String>(uploadId);
    }
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['chunk_size'] = Variable<int>(chunkSize);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UploadChunksCompanion toCompanion(bool nullToAbsent) {
    return UploadChunksCompanion(
      id: Value(id),
      localId: Value(localId),
      uploadId: uploadId == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadId),
      chunkIndex: Value(chunkIndex),
      chunkSize: Value(chunkSize),
      createdAt: Value(createdAt),
    );
  }

  factory UploadChunk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadChunk(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      uploadId: serializer.fromJson<String?>(json['uploadId']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      chunkSize: serializer.fromJson<int>(json['chunkSize']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'uploadId': serializer.toJson<String?>(uploadId),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'chunkSize': serializer.toJson<int>(chunkSize),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UploadChunk copyWith({
    int? id,
    String? localId,
    Value<String?> uploadId = const Value.absent(),
    int? chunkIndex,
    int? chunkSize,
    int? createdAt,
  }) => UploadChunk(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    uploadId: uploadId.present ? uploadId.value : this.uploadId,
    chunkIndex: chunkIndex ?? this.chunkIndex,
    chunkSize: chunkSize ?? this.chunkSize,
    createdAt: createdAt ?? this.createdAt,
  );
  UploadChunk copyWithCompanion(UploadChunksCompanion data) {
    return UploadChunk(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      uploadId: data.uploadId.present ? data.uploadId.value : this.uploadId,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      chunkSize: data.chunkSize.present ? data.chunkSize.value : this.chunkSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadChunk(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('uploadId: $uploadId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('chunkSize: $chunkSize, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, localId, uploadId, chunkIndex, chunkSize, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadChunk &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.uploadId == this.uploadId &&
          other.chunkIndex == this.chunkIndex &&
          other.chunkSize == this.chunkSize &&
          other.createdAt == this.createdAt);
}

class UploadChunksCompanion extends UpdateCompanion<UploadChunk> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String?> uploadId;
  final Value<int> chunkIndex;
  final Value<int> chunkSize;
  final Value<int> createdAt;
  const UploadChunksCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.uploadId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.chunkSize = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UploadChunksCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    this.uploadId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.chunkSize = const Value.absent(),
    required int createdAt,
  }) : localId = Value(localId),
       createdAt = Value(createdAt);
  static Insertable<UploadChunk> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? uploadId,
    Expression<int>? chunkIndex,
    Expression<int>? chunkSize,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (uploadId != null) 'upload_id': uploadId,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (chunkSize != null) 'chunk_size': chunkSize,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UploadChunksCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String?>? uploadId,
    Value<int>? chunkIndex,
    Value<int>? chunkSize,
    Value<int>? createdAt,
  }) {
    return UploadChunksCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      uploadId: uploadId ?? this.uploadId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkSize: chunkSize ?? this.chunkSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (uploadId.present) {
      map['upload_id'] = Variable<String>(uploadId.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (chunkSize.present) {
      map['chunk_size'] = Variable<int>(chunkSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadChunksCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('uploadId: $uploadId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('chunkSize: $chunkSize, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadChunksTable extends DownloadChunks
    with TableInfo<$DownloadChunksTable, DownloadChunk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _downloadIdMeta = const VerificationMeta(
    'downloadId',
  );
  @override
  late final GeneratedColumn<String> downloadId = GeneratedColumn<String>(
    'download_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileUrlMeta = const VerificationMeta(
    'fileUrl',
  );
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
    'file_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSizeMeta = const VerificationMeta(
    'totalSize',
  );
  @override
  late final GeneratedColumn<int> totalSize = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _chunkSizeMeta = const VerificationMeta(
    'chunkSize',
  );
  @override
  late final GeneratedColumn<int> chunkSize = GeneratedColumn<int>(
    'chunk_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesDownloadedMeta = const VerificationMeta(
    'bytesDownloaded',
  );
  @override
  late final GeneratedColumn<int> bytesDownloaded = GeneratedColumn<int>(
    'bytes_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    downloadId,
    fileUrl,
    localPath,
    totalSize,
    chunkIndex,
    chunkSize,
    bytesDownloaded,
    etag,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadChunk> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('download_id')) {
      context.handle(
        _downloadIdMeta,
        downloadId.isAcceptableOrUnknown(data['download_id']!, _downloadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_downloadIdMeta);
    }
    if (data.containsKey('file_url')) {
      context.handle(
        _fileUrlMeta,
        fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_fileUrlMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _totalSizeMeta,
        totalSize.isAcceptableOrUnknown(data['total_size']!, _totalSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSizeMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    }
    if (data.containsKey('chunk_size')) {
      context.handle(
        _chunkSizeMeta,
        chunkSize.isAcceptableOrUnknown(data['chunk_size']!, _chunkSizeMeta),
      );
    }
    if (data.containsKey('bytes_downloaded')) {
      context.handle(
        _bytesDownloadedMeta,
        bytesDownloaded.isAcceptableOrUnknown(
          data['bytes_downloaded']!,
          _bytesDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadChunk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadChunk(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      downloadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_id'],
      )!,
      fileUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_url'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      totalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      )!,
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      chunkSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_size'],
      )!,
      bytesDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_downloaded'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $DownloadChunksTable createAlias(String alias) {
    return $DownloadChunksTable(attachedDatabase, alias);
  }
}

class DownloadChunk extends DataClass implements Insertable<DownloadChunk> {
  /// Auto-incrementing primary key
  final int id;

  /// Unique download identifier for tracking
  final String downloadId;

  /// Remote file URL being downloaded
  final String fileUrl;

  /// Local file path where download is being saved
  final String localPath;

  /// Total file size in bytes
  final int totalSize;

  /// Index of this chunk (0-based, -1 for metadata row)
  final int chunkIndex;

  /// Size of this chunk in bytes
  final int chunkSize;

  /// Bytes downloaded for this chunk
  final int bytesDownloaded;

  /// ETag for HTTP caching and resume validation
  final String? etag;

  /// Timestamp when this chunk was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when this chunk was last updated
  final int? updatedAt;
  const DownloadChunk({
    required this.id,
    required this.downloadId,
    required this.fileUrl,
    required this.localPath,
    required this.totalSize,
    required this.chunkIndex,
    required this.chunkSize,
    required this.bytesDownloaded,
    this.etag,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['download_id'] = Variable<String>(downloadId);
    map['file_url'] = Variable<String>(fileUrl);
    map['local_path'] = Variable<String>(localPath);
    map['total_size'] = Variable<int>(totalSize);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['chunk_size'] = Variable<int>(chunkSize);
    map['bytes_downloaded'] = Variable<int>(bytesDownloaded);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  DownloadChunksCompanion toCompanion(bool nullToAbsent) {
    return DownloadChunksCompanion(
      id: Value(id),
      downloadId: Value(downloadId),
      fileUrl: Value(fileUrl),
      localPath: Value(localPath),
      totalSize: Value(totalSize),
      chunkIndex: Value(chunkIndex),
      chunkSize: Value(chunkSize),
      bytesDownloaded: Value(bytesDownloaded),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DownloadChunk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadChunk(
      id: serializer.fromJson<int>(json['id']),
      downloadId: serializer.fromJson<String>(json['downloadId']),
      fileUrl: serializer.fromJson<String>(json['fileUrl']),
      localPath: serializer.fromJson<String>(json['localPath']),
      totalSize: serializer.fromJson<int>(json['totalSize']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      chunkSize: serializer.fromJson<int>(json['chunkSize']),
      bytesDownloaded: serializer.fromJson<int>(json['bytesDownloaded']),
      etag: serializer.fromJson<String?>(json['etag']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'downloadId': serializer.toJson<String>(downloadId),
      'fileUrl': serializer.toJson<String>(fileUrl),
      'localPath': serializer.toJson<String>(localPath),
      'totalSize': serializer.toJson<int>(totalSize),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'chunkSize': serializer.toJson<int>(chunkSize),
      'bytesDownloaded': serializer.toJson<int>(bytesDownloaded),
      'etag': serializer.toJson<String?>(etag),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  DownloadChunk copyWith({
    int? id,
    String? downloadId,
    String? fileUrl,
    String? localPath,
    int? totalSize,
    int? chunkIndex,
    int? chunkSize,
    int? bytesDownloaded,
    Value<String?> etag = const Value.absent(),
    int? createdAt,
    Value<int?> updatedAt = const Value.absent(),
  }) => DownloadChunk(
    id: id ?? this.id,
    downloadId: downloadId ?? this.downloadId,
    fileUrl: fileUrl ?? this.fileUrl,
    localPath: localPath ?? this.localPath,
    totalSize: totalSize ?? this.totalSize,
    chunkIndex: chunkIndex ?? this.chunkIndex,
    chunkSize: chunkSize ?? this.chunkSize,
    bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
    etag: etag.present ? etag.value : this.etag,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  DownloadChunk copyWithCompanion(DownloadChunksCompanion data) {
    return DownloadChunk(
      id: data.id.present ? data.id.value : this.id,
      downloadId: data.downloadId.present
          ? data.downloadId.value
          : this.downloadId,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      totalSize: data.totalSize.present ? data.totalSize.value : this.totalSize,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      chunkSize: data.chunkSize.present ? data.chunkSize.value : this.chunkSize,
      bytesDownloaded: data.bytesDownloaded.present
          ? data.bytesDownloaded.value
          : this.bytesDownloaded,
      etag: data.etag.present ? data.etag.value : this.etag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadChunk(')
          ..write('id: $id, ')
          ..write('downloadId: $downloadId, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('localPath: $localPath, ')
          ..write('totalSize: $totalSize, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('chunkSize: $chunkSize, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    downloadId,
    fileUrl,
    localPath,
    totalSize,
    chunkIndex,
    chunkSize,
    bytesDownloaded,
    etag,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadChunk &&
          other.id == this.id &&
          other.downloadId == this.downloadId &&
          other.fileUrl == this.fileUrl &&
          other.localPath == this.localPath &&
          other.totalSize == this.totalSize &&
          other.chunkIndex == this.chunkIndex &&
          other.chunkSize == this.chunkSize &&
          other.bytesDownloaded == this.bytesDownloaded &&
          other.etag == this.etag &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DownloadChunksCompanion extends UpdateCompanion<DownloadChunk> {
  final Value<int> id;
  final Value<String> downloadId;
  final Value<String> fileUrl;
  final Value<String> localPath;
  final Value<int> totalSize;
  final Value<int> chunkIndex;
  final Value<int> chunkSize;
  final Value<int> bytesDownloaded;
  final Value<String?> etag;
  final Value<int> createdAt;
  final Value<int?> updatedAt;
  const DownloadChunksCompanion({
    this.id = const Value.absent(),
    this.downloadId = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.chunkSize = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.etag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DownloadChunksCompanion.insert({
    this.id = const Value.absent(),
    required String downloadId,
    required String fileUrl,
    required String localPath,
    required int totalSize,
    this.chunkIndex = const Value.absent(),
    this.chunkSize = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.etag = const Value.absent(),
    required int createdAt,
    this.updatedAt = const Value.absent(),
  }) : downloadId = Value(downloadId),
       fileUrl = Value(fileUrl),
       localPath = Value(localPath),
       totalSize = Value(totalSize),
       createdAt = Value(createdAt);
  static Insertable<DownloadChunk> custom({
    Expression<int>? id,
    Expression<String>? downloadId,
    Expression<String>? fileUrl,
    Expression<String>? localPath,
    Expression<int>? totalSize,
    Expression<int>? chunkIndex,
    Expression<int>? chunkSize,
    Expression<int>? bytesDownloaded,
    Expression<String>? etag,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (downloadId != null) 'download_id': downloadId,
      if (fileUrl != null) 'file_url': fileUrl,
      if (localPath != null) 'local_path': localPath,
      if (totalSize != null) 'total_size': totalSize,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (chunkSize != null) 'chunk_size': chunkSize,
      if (bytesDownloaded != null) 'bytes_downloaded': bytesDownloaded,
      if (etag != null) 'etag': etag,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DownloadChunksCompanion copyWith({
    Value<int>? id,
    Value<String>? downloadId,
    Value<String>? fileUrl,
    Value<String>? localPath,
    Value<int>? totalSize,
    Value<int>? chunkIndex,
    Value<int>? chunkSize,
    Value<int>? bytesDownloaded,
    Value<String?>? etag,
    Value<int>? createdAt,
    Value<int?>? updatedAt,
  }) {
    return DownloadChunksCompanion(
      id: id ?? this.id,
      downloadId: downloadId ?? this.downloadId,
      fileUrl: fileUrl ?? this.fileUrl,
      localPath: localPath ?? this.localPath,
      totalSize: totalSize ?? this.totalSize,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkSize: chunkSize ?? this.chunkSize,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      etag: etag ?? this.etag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (downloadId.present) {
      map['download_id'] = Variable<String>(downloadId.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (totalSize.present) {
      map['total_size'] = Variable<int>(totalSize.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (chunkSize.present) {
      map['chunk_size'] = Variable<int>(chunkSize.value);
    }
    if (bytesDownloaded.present) {
      map['bytes_downloaded'] = Variable<int>(bytesDownloaded.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadChunksCompanion(')
          ..write('id: $id, ')
          ..write('downloadId: $downloadId, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('localPath: $localPath, ')
          ..write('totalSize: $totalSize, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('chunkSize: $chunkSize, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransferJobsTable extends TransferJobs
    with TableInfo<$TransferJobsTable, TransferJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transferTypeMeta = const VerificationMeta(
    'transferType',
  );
  @override
  late final GeneratedColumn<String> transferType = GeneratedColumn<String>(
    'transfer_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileUrlMeta = const VerificationMeta(
    'fileUrl',
  );
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
    'file_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSizeMeta = const VerificationMeta(
    'totalSize',
  );
  @override
  late final GeneratedColumn<int> totalSize = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferredSizeMeta = const VerificationMeta(
    'transferredSize',
  );
  @override
  late final GeneratedColumn<int> transferredSize = GeneratedColumn<int>(
    'transferred_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<int> nextRetryAt = GeneratedColumn<int>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transferType,
    referenceId,
    roomId,
    fileUrl,
    localPath,
    fileName,
    totalSize,
    transferredSize,
    mimeType,
    priority,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
    nextRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transfer_type')) {
      context.handle(
        _transferTypeMeta,
        transferType.isAcceptableOrUnknown(
          data['transfer_type']!,
          _transferTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferTypeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('file_url')) {
      context.handle(
        _fileUrlMeta,
        fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_fileUrlMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _totalSizeMeta,
        totalSize.isAcceptableOrUnknown(data['total_size']!, _totalSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSizeMeta);
    }
    if (data.containsKey('transferred_size')) {
      context.handle(
        _transferredSizeMeta,
        transferredSize.isAcceptableOrUnknown(
          data['transferred_size']!,
          _transferredSizeMeta,
        ),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transferType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_type'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      fileUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_url'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      totalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      )!,
      transferredSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transferred_size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_retry_at'],
      ),
    );
  }

  @override
  $TransferJobsTable createAlias(String alias) {
    return $TransferJobsTable(attachedDatabase, alias);
  }
}

class TransferJob extends DataClass implements Insertable<TransferJob> {
  /// Auto-incrementing primary key
  final int id;

  /// Transfer type: 'upload' or 'download'
  final String transferType;

  /// Reference ID (localId for uploads, downloadId for downloads)
  final String referenceId;

  /// Room ID associated with this transfer
  final String roomId;

  /// File URL (destination for uploads, source for downloads)
  final String fileUrl;

  /// Local file path (source for uploads, destination for downloads)
  final String localPath;

  /// File name for display purposes
  final String fileName;

  /// Total file size in bytes
  final int totalSize;

  /// Bytes transferred so far
  final int transferredSize;

  /// MIME type of the file
  final String? mimeType;

  /// Priority level (0=critical, 1=high, 2=normal, 3=low)
  /// Uploads default to priority 1, downloads to priority 2
  final int priority;

  /// Job status: 'pending', 'active', 'paused', 'completed', 'failed'
  final String status;

  /// Number of retry attempts
  final int retryCount;

  /// Last error message if failed
  final String? lastError;

  /// Timestamp when job was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when job was last updated
  final int? updatedAt;

  /// Earliest time this job can be retried (for exponential backoff)
  final int? nextRetryAt;
  const TransferJob({
    required this.id,
    required this.transferType,
    required this.referenceId,
    required this.roomId,
    required this.fileUrl,
    required this.localPath,
    required this.fileName,
    required this.totalSize,
    required this.transferredSize,
    this.mimeType,
    required this.priority,
    required this.status,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    this.updatedAt,
    this.nextRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transfer_type'] = Variable<String>(transferType);
    map['reference_id'] = Variable<String>(referenceId);
    map['room_id'] = Variable<String>(roomId);
    map['file_url'] = Variable<String>(fileUrl);
    map['local_path'] = Variable<String>(localPath);
    map['file_name'] = Variable<String>(fileName);
    map['total_size'] = Variable<int>(totalSize);
    map['transferred_size'] = Variable<int>(transferredSize);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<int>(nextRetryAt);
    }
    return map;
  }

  TransferJobsCompanion toCompanion(bool nullToAbsent) {
    return TransferJobsCompanion(
      id: Value(id),
      transferType: Value(transferType),
      referenceId: Value(referenceId),
      roomId: Value(roomId),
      fileUrl: Value(fileUrl),
      localPath: Value(localPath),
      fileName: Value(fileName),
      totalSize: Value(totalSize),
      transferredSize: Value(transferredSize),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      priority: Value(priority),
      status: Value(status),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
    );
  }

  factory TransferJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferJob(
      id: serializer.fromJson<int>(json['id']),
      transferType: serializer.fromJson<String>(json['transferType']),
      referenceId: serializer.fromJson<String>(json['referenceId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      fileUrl: serializer.fromJson<String>(json['fileUrl']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      totalSize: serializer.fromJson<int>(json['totalSize']),
      transferredSize: serializer.fromJson<int>(json['transferredSize']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      nextRetryAt: serializer.fromJson<int?>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transferType': serializer.toJson<String>(transferType),
      'referenceId': serializer.toJson<String>(referenceId),
      'roomId': serializer.toJson<String>(roomId),
      'fileUrl': serializer.toJson<String>(fileUrl),
      'localPath': serializer.toJson<String>(localPath),
      'fileName': serializer.toJson<String>(fileName),
      'totalSize': serializer.toJson<int>(totalSize),
      'transferredSize': serializer.toJson<int>(transferredSize),
      'mimeType': serializer.toJson<String?>(mimeType),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'nextRetryAt': serializer.toJson<int?>(nextRetryAt),
    };
  }

  TransferJob copyWith({
    int? id,
    String? transferType,
    String? referenceId,
    String? roomId,
    String? fileUrl,
    String? localPath,
    String? fileName,
    int? totalSize,
    int? transferredSize,
    Value<String?> mimeType = const Value.absent(),
    int? priority,
    String? status,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> nextRetryAt = const Value.absent(),
  }) => TransferJob(
    id: id ?? this.id,
    transferType: transferType ?? this.transferType,
    referenceId: referenceId ?? this.referenceId,
    roomId: roomId ?? this.roomId,
    fileUrl: fileUrl ?? this.fileUrl,
    localPath: localPath ?? this.localPath,
    fileName: fileName ?? this.fileName,
    totalSize: totalSize ?? this.totalSize,
    transferredSize: transferredSize ?? this.transferredSize,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
  );
  TransferJob copyWithCompanion(TransferJobsCompanion data) {
    return TransferJob(
      id: data.id.present ? data.id.value : this.id,
      transferType: data.transferType.present
          ? data.transferType.value
          : this.transferType,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      totalSize: data.totalSize.present ? data.totalSize.value : this.totalSize,
      transferredSize: data.transferredSize.present
          ? data.transferredSize.value
          : this.transferredSize,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferJob(')
          ..write('id: $id, ')
          ..write('transferType: $transferType, ')
          ..write('referenceId: $referenceId, ')
          ..write('roomId: $roomId, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fileName: $fileName, ')
          ..write('totalSize: $totalSize, ')
          ..write('transferredSize: $transferredSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transferType,
    referenceId,
    roomId,
    fileUrl,
    localPath,
    fileName,
    totalSize,
    transferredSize,
    mimeType,
    priority,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
    nextRetryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferJob &&
          other.id == this.id &&
          other.transferType == this.transferType &&
          other.referenceId == this.referenceId &&
          other.roomId == this.roomId &&
          other.fileUrl == this.fileUrl &&
          other.localPath == this.localPath &&
          other.fileName == this.fileName &&
          other.totalSize == this.totalSize &&
          other.transferredSize == this.transferredSize &&
          other.mimeType == this.mimeType &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.nextRetryAt == this.nextRetryAt);
}

class TransferJobsCompanion extends UpdateCompanion<TransferJob> {
  final Value<int> id;
  final Value<String> transferType;
  final Value<String> referenceId;
  final Value<String> roomId;
  final Value<String> fileUrl;
  final Value<String> localPath;
  final Value<String> fileName;
  final Value<int> totalSize;
  final Value<int> transferredSize;
  final Value<String?> mimeType;
  final Value<int> priority;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> nextRetryAt;
  const TransferJobsCompanion({
    this.id = const Value.absent(),
    this.transferType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.transferredSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  });
  TransferJobsCompanion.insert({
    this.id = const Value.absent(),
    required String transferType,
    required String referenceId,
    required String roomId,
    required String fileUrl,
    required String localPath,
    required String fileName,
    required int totalSize,
    this.transferredSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAt,
    this.updatedAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  }) : transferType = Value(transferType),
       referenceId = Value(referenceId),
       roomId = Value(roomId),
       fileUrl = Value(fileUrl),
       localPath = Value(localPath),
       fileName = Value(fileName),
       totalSize = Value(totalSize),
       createdAt = Value(createdAt);
  static Insertable<TransferJob> custom({
    Expression<int>? id,
    Expression<String>? transferType,
    Expression<String>? referenceId,
    Expression<String>? roomId,
    Expression<String>? fileUrl,
    Expression<String>? localPath,
    Expression<String>? fileName,
    Expression<int>? totalSize,
    Expression<int>? transferredSize,
    Expression<String>? mimeType,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? nextRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferType != null) 'transfer_type': transferType,
      if (referenceId != null) 'reference_id': referenceId,
      if (roomId != null) 'room_id': roomId,
      if (fileUrl != null) 'file_url': fileUrl,
      if (localPath != null) 'local_path': localPath,
      if (fileName != null) 'file_name': fileName,
      if (totalSize != null) 'total_size': totalSize,
      if (transferredSize != null) 'transferred_size': transferredSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
    });
  }

  TransferJobsCompanion copyWith({
    Value<int>? id,
    Value<String>? transferType,
    Value<String>? referenceId,
    Value<String>? roomId,
    Value<String>? fileUrl,
    Value<String>? localPath,
    Value<String>? fileName,
    Value<int>? totalSize,
    Value<int>? transferredSize,
    Value<String?>? mimeType,
    Value<int>? priority,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? nextRetryAt,
  }) {
    return TransferJobsCompanion(
      id: id ?? this.id,
      transferType: transferType ?? this.transferType,
      referenceId: referenceId ?? this.referenceId,
      roomId: roomId ?? this.roomId,
      fileUrl: fileUrl ?? this.fileUrl,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      totalSize: totalSize ?? this.totalSize,
      transferredSize: transferredSize ?? this.transferredSize,
      mimeType: mimeType ?? this.mimeType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transferType.present) {
      map['transfer_type'] = Variable<String>(transferType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (totalSize.present) {
      map['total_size'] = Variable<int>(totalSize.value);
    }
    if (transferredSize.present) {
      map['transferred_size'] = Variable<int>(transferredSize.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<int>(nextRetryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferJobsCompanion(')
          ..write('id: $id, ')
          ..write('transferType: $transferType, ')
          ..write('referenceId: $referenceId, ')
          ..write('roomId: $roomId, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fileName: $fileName, ')
          ..write('totalSize: $totalSize, ')
          ..write('transferredSize: $transferredSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }
}

class $CallHistoryTable extends CallHistory
    with TableInfo<$CallHistoryTable, CallHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _callerIdMeta = const VerificationMeta(
    'callerId',
  );
  @override
  late final GeneratedColumn<String> callerId = GeneratedColumn<String>(
    'caller_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _callTypeMeta = const VerificationMeta(
    'callType',
  );
  @override
  late final GeneratedColumn<int> callType = GeneratedColumn<int>(
    'call_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<int> answeredAt = GeneratedColumn<int>(
    'answered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomId,
    callerId,
    recipientId,
    callType,
    direction,
    status,
    startedAt,
    answeredAt,
    endedAt,
    duration,
    isRead,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('caller_id')) {
      context.handle(
        _callerIdMeta,
        callerId.isAcceptableOrUnknown(data['caller_id']!, _callerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_callerIdMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    }
    if (data.containsKey('call_type')) {
      context.handle(
        _callTypeMeta,
        callType.isAcceptableOrUnknown(data['call_type']!, _callTypeMeta),
      );
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      callerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caller_id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      ),
      callType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}call_type'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answered_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CallHistoryTable createAlias(String alias) {
    return $CallHistoryTable(attachedDatabase, alias);
  }
}

class CallHistoryData extends DataClass implements Insertable<CallHistoryData> {
  /// Auto-incrementing primary key
  final int id;

  /// Room ID where the call occurred
  final String roomId;

  /// Profile ID of the caller (who initiated the call)
  final String callerId;

  /// Profile ID of the recipient (who received the call)
  final String? recipientId;

  /// Call type: 0=audio, 1=video
  final int callType;

  /// Call direction: 0=outgoing, 1=incoming
  final int direction;

  /// Call status: 0=missed, 1=answered, 2=declined, 3=busy, 4=failed
  final int status;

  /// Timestamp when call started (milliseconds since epoch)
  final int startedAt;

  /// Timestamp when call was answered (milliseconds since epoch)
  final int? answeredAt;

  /// Timestamp when call ended (milliseconds since epoch)
  final int? endedAt;

  /// Duration of the call in seconds (0 if not answered)
  final int duration;

  /// Whether this entry has been read/seen by the user
  final bool isRead;

  /// Whether the call has been deleted by the user
  final bool isDeleted;
  const CallHistoryData({
    required this.id,
    required this.roomId,
    required this.callerId,
    this.recipientId,
    required this.callType,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    required this.duration,
    required this.isRead,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['room_id'] = Variable<String>(roomId);
    map['caller_id'] = Variable<String>(callerId);
    if (!nullToAbsent || recipientId != null) {
      map['recipient_id'] = Variable<String>(recipientId);
    }
    map['call_type'] = Variable<int>(callType);
    map['direction'] = Variable<int>(direction);
    map['status'] = Variable<int>(status);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || answeredAt != null) {
      map['answered_at'] = Variable<int>(answeredAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['duration'] = Variable<int>(duration);
    map['is_read'] = Variable<bool>(isRead);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CallHistoryCompanion toCompanion(bool nullToAbsent) {
    return CallHistoryCompanion(
      id: Value(id),
      roomId: Value(roomId),
      callerId: Value(callerId),
      recipientId: recipientId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipientId),
      callType: Value(callType),
      direction: Value(direction),
      status: Value(status),
      startedAt: Value(startedAt),
      answeredAt: answeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      duration: Value(duration),
      isRead: Value(isRead),
      isDeleted: Value(isDeleted),
    );
  }

  factory CallHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallHistoryData(
      id: serializer.fromJson<int>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      callerId: serializer.fromJson<String>(json['callerId']),
      recipientId: serializer.fromJson<String?>(json['recipientId']),
      callType: serializer.fromJson<int>(json['callType']),
      direction: serializer.fromJson<int>(json['direction']),
      status: serializer.fromJson<int>(json['status']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      answeredAt: serializer.fromJson<int?>(json['answeredAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      duration: serializer.fromJson<int>(json['duration']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'roomId': serializer.toJson<String>(roomId),
      'callerId': serializer.toJson<String>(callerId),
      'recipientId': serializer.toJson<String?>(recipientId),
      'callType': serializer.toJson<int>(callType),
      'direction': serializer.toJson<int>(direction),
      'status': serializer.toJson<int>(status),
      'startedAt': serializer.toJson<int>(startedAt),
      'answeredAt': serializer.toJson<int?>(answeredAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'duration': serializer.toJson<int>(duration),
      'isRead': serializer.toJson<bool>(isRead),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CallHistoryData copyWith({
    int? id,
    String? roomId,
    String? callerId,
    Value<String?> recipientId = const Value.absent(),
    int? callType,
    int? direction,
    int? status,
    int? startedAt,
    Value<int?> answeredAt = const Value.absent(),
    Value<int?> endedAt = const Value.absent(),
    int? duration,
    bool? isRead,
    bool? isDeleted,
  }) => CallHistoryData(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    callerId: callerId ?? this.callerId,
    recipientId: recipientId.present ? recipientId.value : this.recipientId,
    callType: callType ?? this.callType,
    direction: direction ?? this.direction,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    answeredAt: answeredAt.present ? answeredAt.value : this.answeredAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    duration: duration ?? this.duration,
    isRead: isRead ?? this.isRead,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CallHistoryData copyWithCompanion(CallHistoryCompanion data) {
    return CallHistoryData(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      callerId: data.callerId.present ? data.callerId.value : this.callerId,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      callType: data.callType.present ? data.callType.value : this.callType,
      direction: data.direction.present ? data.direction.value : this.direction,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      duration: data.duration.present ? data.duration.value : this.duration,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallHistoryData(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('callerId: $callerId, ')
          ..write('recipientId: $recipientId, ')
          ..write('callType: $callType, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('duration: $duration, ')
          ..write('isRead: $isRead, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roomId,
    callerId,
    recipientId,
    callType,
    direction,
    status,
    startedAt,
    answeredAt,
    endedAt,
    duration,
    isRead,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallHistoryData &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.callerId == this.callerId &&
          other.recipientId == this.recipientId &&
          other.callType == this.callType &&
          other.direction == this.direction &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.answeredAt == this.answeredAt &&
          other.endedAt == this.endedAt &&
          other.duration == this.duration &&
          other.isRead == this.isRead &&
          other.isDeleted == this.isDeleted);
}

class CallHistoryCompanion extends UpdateCompanion<CallHistoryData> {
  final Value<int> id;
  final Value<String> roomId;
  final Value<String> callerId;
  final Value<String?> recipientId;
  final Value<int> callType;
  final Value<int> direction;
  final Value<int> status;
  final Value<int> startedAt;
  final Value<int?> answeredAt;
  final Value<int?> endedAt;
  final Value<int> duration;
  final Value<bool> isRead;
  final Value<bool> isDeleted;
  const CallHistoryCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.callerId = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.callType = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.duration = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  CallHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String roomId,
    required String callerId,
    this.recipientId = const Value.absent(),
    this.callType = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    required int startedAt,
    this.answeredAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.duration = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : roomId = Value(roomId),
       callerId = Value(callerId),
       startedAt = Value(startedAt);
  static Insertable<CallHistoryData> custom({
    Expression<int>? id,
    Expression<String>? roomId,
    Expression<String>? callerId,
    Expression<String>? recipientId,
    Expression<int>? callType,
    Expression<int>? direction,
    Expression<int>? status,
    Expression<int>? startedAt,
    Expression<int>? answeredAt,
    Expression<int>? endedAt,
    Expression<int>? duration,
    Expression<bool>? isRead,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (callerId != null) 'caller_id': callerId,
      if (recipientId != null) 'recipient_id': recipientId,
      if (callType != null) 'call_type': callType,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (duration != null) 'duration': duration,
      if (isRead != null) 'is_read': isRead,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  CallHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? roomId,
    Value<String>? callerId,
    Value<String?>? recipientId,
    Value<int>? callType,
    Value<int>? direction,
    Value<int>? status,
    Value<int>? startedAt,
    Value<int?>? answeredAt,
    Value<int?>? endedAt,
    Value<int>? duration,
    Value<bool>? isRead,
    Value<bool>? isDeleted,
  }) {
    return CallHistoryCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      callerId: callerId ?? this.callerId,
      recipientId: recipientId ?? this.recipientId,
      callType: callType ?? this.callType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (callerId.present) {
      map['caller_id'] = Variable<String>(callerId.value);
    }
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (callType.present) {
      map['call_type'] = Variable<int>(callType.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<int>(answeredAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallHistoryCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('callerId: $callerId, ')
          ..write('recipientId: $recipientId, ')
          ..write('callType: $callType, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('duration: $duration, ')
          ..write('isRead: $isRead, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $AnalyticsEventsTable extends AnalyticsEvents
    with TableInfo<$AnalyticsEventsTable, AnalyticsEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalyticsEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventNameMeta = const VerificationMeta(
    'eventName',
  );
  @override
  late final GeneratedColumn<String> eventName = GeneratedColumn<String>(
    'event_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _screenNameMeta = const VerificationMeta(
    'screenName',
  );
  @override
  late final GeneratedColumn<String> screenName = GeneratedColumn<String>(
    'screen_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _propertiesMeta = const VerificationMeta(
    'properties',
  );
  @override
  late final GeneratedColumn<String> properties = GeneratedColumn<String>(
    'properties',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    eventType,
    eventName,
    userId,
    sessionId,
    screenName,
    properties,
    timestamp,
    isSynced,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analytics_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalyticsEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_name')) {
      context.handle(
        _eventNameMeta,
        eventName.isAcceptableOrUnknown(data['event_name']!, _eventNameMeta),
      );
    } else if (isInserting) {
      context.missing(_eventNameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('screen_name')) {
      context.handle(
        _screenNameMeta,
        screenName.isAcceptableOrUnknown(data['screen_name']!, _screenNameMeta),
      );
    }
    if (data.containsKey('properties')) {
      context.handle(
        _propertiesMeta,
        properties.isAcceptableOrUnknown(data['properties']!, _propertiesMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalyticsEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalyticsEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      eventName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      screenName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screen_name'],
      ),
      properties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}properties'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $AnalyticsEventsTable createAlias(String alias) {
    return $AnalyticsEventsTable(attachedDatabase, alias);
  }
}

class AnalyticsEvent extends DataClass implements Insertable<AnalyticsEvent> {
  /// Auto-incrementing primary key
  final int id;

  /// Unique event identifier (UUID)
  final String eventId;

  /// Event type (e.g., 'screen_view', 'message_sent')
  final String eventType;

  /// Event name for custom events
  final String eventName;

  /// User ID associated with the event (nullable for anonymous)
  final String? userId;

  /// Session ID for grouping events
  final String? sessionId;

  /// Screen name where event occurred
  final String? screenName;

  /// JSON-encoded event properties
  final String? properties;

  /// Timestamp when event occurred (milliseconds since epoch)
  final int timestamp;

  /// Whether the event has been synced to backend
  final bool isSynced;

  /// Timestamp when event was synced
  final int? syncedAt;
  const AnalyticsEvent({
    required this.id,
    required this.eventId,
    required this.eventType,
    required this.eventName,
    this.userId,
    this.sessionId,
    this.screenName,
    this.properties,
    required this.timestamp,
    required this.isSynced,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['event_type'] = Variable<String>(eventType);
    map['event_name'] = Variable<String>(eventName);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || screenName != null) {
      map['screen_name'] = Variable<String>(screenName);
    }
    if (!nullToAbsent || properties != null) {
      map['properties'] = Variable<String>(properties);
    }
    map['timestamp'] = Variable<int>(timestamp);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    return map;
  }

  AnalyticsEventsCompanion toCompanion(bool nullToAbsent) {
    return AnalyticsEventsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      eventType: Value(eventType),
      eventName: Value(eventName),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      screenName: screenName == null && nullToAbsent
          ? const Value.absent()
          : Value(screenName),
      properties: properties == null && nullToAbsent
          ? const Value.absent()
          : Value(properties),
      timestamp: Value(timestamp),
      isSynced: Value(isSynced),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory AnalyticsEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalyticsEvent(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventName: serializer.fromJson<String>(json['eventName']),
      userId: serializer.fromJson<String?>(json['userId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      screenName: serializer.fromJson<String?>(json['screenName']),
      properties: serializer.fromJson<String?>(json['properties']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'eventType': serializer.toJson<String>(eventType),
      'eventName': serializer.toJson<String>(eventName),
      'userId': serializer.toJson<String?>(userId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'screenName': serializer.toJson<String?>(screenName),
      'properties': serializer.toJson<String?>(properties),
      'timestamp': serializer.toJson<int>(timestamp),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedAt': serializer.toJson<int?>(syncedAt),
    };
  }

  AnalyticsEvent copyWith({
    int? id,
    String? eventId,
    String? eventType,
    String? eventName,
    Value<String?> userId = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    Value<String?> screenName = const Value.absent(),
    Value<String?> properties = const Value.absent(),
    int? timestamp,
    bool? isSynced,
    Value<int?> syncedAt = const Value.absent(),
  }) => AnalyticsEvent(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    eventType: eventType ?? this.eventType,
    eventName: eventName ?? this.eventName,
    userId: userId.present ? userId.value : this.userId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    screenName: screenName.present ? screenName.value : this.screenName,
    properties: properties.present ? properties.value : this.properties,
    timestamp: timestamp ?? this.timestamp,
    isSynced: isSynced ?? this.isSynced,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  AnalyticsEvent copyWithCompanion(AnalyticsEventsCompanion data) {
    return AnalyticsEvent(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventName: data.eventName.present ? data.eventName.value : this.eventName,
      userId: data.userId.present ? data.userId.value : this.userId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      screenName: data.screenName.present
          ? data.screenName.value
          : this.screenName,
      properties: data.properties.present
          ? data.properties.value
          : this.properties,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsEvent(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('eventName: $eventName, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('screenName: $screenName, ')
          ..write('properties: $properties, ')
          ..write('timestamp: $timestamp, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    eventType,
    eventName,
    userId,
    sessionId,
    screenName,
    properties,
    timestamp,
    isSynced,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalyticsEvent &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.eventType == this.eventType &&
          other.eventName == this.eventName &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.screenName == this.screenName &&
          other.properties == this.properties &&
          other.timestamp == this.timestamp &&
          other.isSynced == this.isSynced &&
          other.syncedAt == this.syncedAt);
}

class AnalyticsEventsCompanion extends UpdateCompanion<AnalyticsEvent> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> eventType;
  final Value<String> eventName;
  final Value<String?> userId;
  final Value<String?> sessionId;
  final Value<String?> screenName;
  final Value<String?> properties;
  final Value<int> timestamp;
  final Value<bool> isSynced;
  final Value<int?> syncedAt;
  const AnalyticsEventsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventName = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.screenName = const Value.absent(),
    this.properties = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  AnalyticsEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String eventType,
    required String eventName,
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.screenName = const Value.absent(),
    this.properties = const Value.absent(),
    required int timestamp,
    this.isSynced = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : eventId = Value(eventId),
       eventType = Value(eventType),
       eventName = Value(eventName),
       timestamp = Value(timestamp);
  static Insertable<AnalyticsEvent> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? eventType,
    Expression<String>? eventName,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<String>? screenName,
    Expression<String>? properties,
    Expression<int>? timestamp,
    Expression<bool>? isSynced,
    Expression<int>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (eventType != null) 'event_type': eventType,
      if (eventName != null) 'event_name': eventName,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (screenName != null) 'screen_name': screenName,
      if (properties != null) 'properties': properties,
      if (timestamp != null) 'timestamp': timestamp,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  AnalyticsEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? eventId,
    Value<String>? eventType,
    Value<String>? eventName,
    Value<String?>? userId,
    Value<String?>? sessionId,
    Value<String?>? screenName,
    Value<String?>? properties,
    Value<int>? timestamp,
    Value<bool>? isSynced,
    Value<int?>? syncedAt,
  }) {
    return AnalyticsEventsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      eventName: eventName ?? this.eventName,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      screenName: screenName ?? this.screenName,
      properties: properties ?? this.properties,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventName.present) {
      map['event_name'] = Variable<String>(eventName.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (screenName.present) {
      map['screen_name'] = Variable<String>(screenName.value);
    }
    if (properties.present) {
      map['properties'] = Variable<String>(properties.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('eventName: $eventName, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('screenName: $screenName, ')
          ..write('properties: $properties, ')
          ..write('timestamp: $timestamp, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $RosterTable roster = $RosterTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $RoomSubscriptionsTable roomSubscriptions =
      $RoomSubscriptionsTable(this);
  late final $RoomEventsTable roomEvents = $RoomEventsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $PrekeysTable prekeys = $PrekeysTable(this);
  late final $PendingJobsTable pendingJobs = $PendingJobsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $ReadReceiptsTable readReceipts = $ReadReceiptsTable(this);
  late final $ReportsTable reports = $ReportsTable(this);
  late final $InviteLinksTable inviteLinks = $InviteLinksTable(this);
  late final $InviteLinkJoinsTable inviteLinkJoins = $InviteLinkJoinsTable(
    this,
  );
  late final $UploadChunksTable uploadChunks = $UploadChunksTable(this);
  late final $DownloadChunksTable downloadChunks = $DownloadChunksTable(this);
  late final $TransferJobsTable transferJobs = $TransferJobsTable(this);
  late final $CallHistoryTable callHistory = $CallHistoryTable(this);
  late final $AnalyticsEventsTable analyticsEvents = $AnalyticsEventsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    roster,
    rooms,
    roomSubscriptions,
    roomEvents,
    sessions,
    prekeys,
    pendingJobs,
    transactions,
    syncMetadata,
    userSettings,
    drafts,
    readReceipts,
    reports,
    inviteLinks,
    inviteLinkJoins,
    uploadChunks,
    downloadChunks,
    transferJobs,
    callHistory,
    analyticsEvents,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> avatarUrl,
      Value<int?> updatedAt,
      Value<String?> metadata,
      Value<int> status,
      Value<String?> statusMessage,
      Value<int?> statusUpdatedAt,
      Value<String?> bio,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> avatarUrl,
      Value<int?> updatedAt,
      Value<String?> metadata,
      Value<int> status,
      Value<String?> statusMessage,
      Value<int?> statusUpdatedAt,
      Value<String?> bio,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusMessage => $composableBuilder(
    column: $table.statusMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusUpdatedAt => $composableBuilder(
    column: $table.statusUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusMessage => $composableBuilder(
    column: $table.statusMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusUpdatedAt => $composableBuilder(
    column: $table.statusUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get statusMessage => $composableBuilder(
    column: $table.statusMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statusUpdatedAt => $composableBuilder(
    column: $table.statusUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> statusMessage = const Value.absent(),
                Value<int?> statusUpdatedAt = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                avatarUrl: avatarUrl,
                updatedAt: updatedAt,
                metadata: metadata,
                status: status,
                statusMessage: statusMessage,
                statusUpdatedAt: statusUpdatedAt,
                bio: bio,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> statusMessage = const Value.absent(),
                Value<int?> statusUpdatedAt = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                avatarUrl: avatarUrl,
                updatedAt: updatedAt,
                metadata: metadata,
                status: status,
                statusMessage: statusMessage,
                statusUpdatedAt: statusUpdatedAt,
                bio: bio,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$RosterTableCreateCompanionBuilder =
    RosterCompanion Function({
      required String id,
      Value<String?> rosterId,
      Value<String?> profileId,
      Value<String?> contactId,
      Value<int> contactType,
      required String contactDetail,
      Value<bool> isVerified,
      Value<String?> displayName,
      Value<bool> isBlocked,
      Value<int?> syncedAt,
      Value<int?> createdAt,
      Value<int> rowid,
    });
typedef $$RosterTableUpdateCompanionBuilder =
    RosterCompanion Function({
      Value<String> id,
      Value<String?> rosterId,
      Value<String?> profileId,
      Value<String?> contactId,
      Value<int> contactType,
      Value<String> contactDetail,
      Value<bool> isVerified,
      Value<String?> displayName,
      Value<bool> isBlocked,
      Value<int?> syncedAt,
      Value<int?> createdAt,
      Value<int> rowid,
    });

class $$RosterTableFilterComposer
    extends Composer<_$AppDatabase, $RosterTable> {
  $$RosterTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rosterId => $composableBuilder(
    column: $table.rosterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contactType => $composableBuilder(
    column: $table.contactType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactDetail => $composableBuilder(
    column: $table.contactDetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBlocked => $composableBuilder(
    column: $table.isBlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RosterTableOrderingComposer
    extends Composer<_$AppDatabase, $RosterTable> {
  $$RosterTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rosterId => $composableBuilder(
    column: $table.rosterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contactType => $composableBuilder(
    column: $table.contactType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactDetail => $composableBuilder(
    column: $table.contactDetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBlocked => $composableBuilder(
    column: $table.isBlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RosterTableAnnotationComposer
    extends Composer<_$AppDatabase, $RosterTable> {
  $$RosterTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rosterId =>
      $composableBuilder(column: $table.rosterId, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<int> get contactType => $composableBuilder(
    column: $table.contactType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactDetail => $composableBuilder(
    column: $table.contactDetail,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBlocked =>
      $composableBuilder(column: $table.isBlocked, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RosterTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RosterTable,
          RosterData,
          $$RosterTableFilterComposer,
          $$RosterTableOrderingComposer,
          $$RosterTableAnnotationComposer,
          $$RosterTableCreateCompanionBuilder,
          $$RosterTableUpdateCompanionBuilder,
          (RosterData, BaseReferences<_$AppDatabase, $RosterTable, RosterData>),
          RosterData,
          PrefetchHooks Function()
        > {
  $$RosterTableTableManager(_$AppDatabase db, $RosterTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RosterTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RosterTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RosterTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> rosterId = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<int> contactType = const Value.absent(),
                Value<String> contactDetail = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool> isBlocked = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RosterCompanion(
                id: id,
                rosterId: rosterId,
                profileId: profileId,
                contactId: contactId,
                contactType: contactType,
                contactDetail: contactDetail,
                isVerified: isVerified,
                displayName: displayName,
                isBlocked: isBlocked,
                syncedAt: syncedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> rosterId = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<int> contactType = const Value.absent(),
                required String contactDetail,
                Value<bool> isVerified = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool> isBlocked = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RosterCompanion.insert(
                id: id,
                rosterId: rosterId,
                profileId: profileId,
                contactId: contactId,
                contactType: contactType,
                contactDetail: contactDetail,
                isVerified: isVerified,
                displayName: displayName,
                isBlocked: isBlocked,
                syncedAt: syncedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RosterTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RosterTable,
      RosterData,
      $$RosterTableFilterComposer,
      $$RosterTableOrderingComposer,
      $$RosterTableAnnotationComposer,
      $$RosterTableCreateCompanionBuilder,
      $$RosterTableUpdateCompanionBuilder,
      (RosterData, BaseReferences<_$AppDatabase, $RosterTable, RosterData>),
      RosterData,
      PrefetchHooks Function()
    >;
typedef $$RoomsTableCreateCompanionBuilder =
    RoomsCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> type,
      Value<String?> lastEventId,
      Value<int?> lastEventIndex,
      Value<int> unreadCount,
      Value<String?> metadata,
      Value<int?> disappearingTimeout,
      Value<int?> mutedUntil,
      Value<int?> memberLimit,
      Value<bool> memberLimitEnabled,
      Value<int> rowid,
    });
typedef $$RoomsTableUpdateCompanionBuilder =
    RoomsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> type,
      Value<String?> lastEventId,
      Value<int?> lastEventIndex,
      Value<int> unreadCount,
      Value<String?> metadata,
      Value<int?> disappearingTimeout,
      Value<int?> mutedUntil,
      Value<int?> memberLimit,
      Value<bool> memberLimitEnabled,
      Value<int> rowid,
    });

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, Room> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoomSubscriptionsTable, List<RoomSubscription>>
  _roomSubscriptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.roomSubscriptions,
        aliasName: $_aliasNameGenerator(
          db.rooms.id,
          db.roomSubscriptions.roomId,
        ),
      );

  $$RoomSubscriptionsTableProcessedTableManager get roomSubscriptionsRefs {
    final manager = $$RoomSubscriptionsTableTableManager(
      $_db,
      $_db.roomSubscriptions,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _roomSubscriptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RoomEventsTable, List<RoomEvent>>
  _roomEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.roomEvents,
    aliasName: $_aliasNameGenerator(db.rooms.id, db.roomEvents.roomId),
  );

  $$RoomEventsTableProcessedTableManager get roomEventsRefs {
    final manager = $$RoomEventsTableTableManager(
      $_db,
      $_db.roomEvents,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_roomEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.rooms.id, db.transactions.roomId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InviteLinksTable, List<InviteLink>>
  _inviteLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inviteLinks,
    aliasName: $_aliasNameGenerator(db.rooms.id, db.inviteLinks.roomId),
  );

  $$InviteLinksTableProcessedTableManager get inviteLinksRefs {
    final manager = $$InviteLinksTableTableManager(
      $_db,
      $_db.inviteLinks,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inviteLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastEventId => $composableBuilder(
    column: $table.lastEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastEventIndex => $composableBuilder(
    column: $table.lastEventIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disappearingTimeout => $composableBuilder(
    column: $table.disappearingTimeout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mutedUntil => $composableBuilder(
    column: $table.mutedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberLimit => $composableBuilder(
    column: $table.memberLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get memberLimitEnabled => $composableBuilder(
    column: $table.memberLimitEnabled,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> roomSubscriptionsRefs(
    Expression<bool> Function($$RoomSubscriptionsTableFilterComposer f) f,
  ) {
    final $$RoomSubscriptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roomSubscriptions,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomSubscriptionsTableFilterComposer(
            $db: $db,
            $table: $db.roomSubscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> roomEventsRefs(
    Expression<bool> Function($$RoomEventsTableFilterComposer f) f,
  ) {
    final $$RoomEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roomEvents,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomEventsTableFilterComposer(
            $db: $db,
            $table: $db.roomEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inviteLinksRefs(
    Expression<bool> Function($$InviteLinksTableFilterComposer f) f,
  ) {
    final $$InviteLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inviteLinks,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinksTableFilterComposer(
            $db: $db,
            $table: $db.inviteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastEventId => $composableBuilder(
    column: $table.lastEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastEventIndex => $composableBuilder(
    column: $table.lastEventIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disappearingTimeout => $composableBuilder(
    column: $table.disappearingTimeout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mutedUntil => $composableBuilder(
    column: $table.mutedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberLimit => $composableBuilder(
    column: $table.memberLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get memberLimitEnabled => $composableBuilder(
    column: $table.memberLimitEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get lastEventId => $composableBuilder(
    column: $table.lastEventId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastEventIndex => $composableBuilder(
    column: $table.lastEventIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<int> get disappearingTimeout => $composableBuilder(
    column: $table.disappearingTimeout,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mutedUntil => $composableBuilder(
    column: $table.mutedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberLimit => $composableBuilder(
    column: $table.memberLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get memberLimitEnabled => $composableBuilder(
    column: $table.memberLimitEnabled,
    builder: (column) => column,
  );

  Expression<T> roomSubscriptionsRefs<T extends Object>(
    Expression<T> Function($$RoomSubscriptionsTableAnnotationComposer a) f,
  ) {
    final $$RoomSubscriptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.roomSubscriptions,
          getReferencedColumn: (t) => t.roomId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RoomSubscriptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.roomSubscriptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> roomEventsRefs<T extends Object>(
    Expression<T> Function($$RoomEventsTableAnnotationComposer a) f,
  ) {
    final $$RoomEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roomEvents,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.roomEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inviteLinksRefs<T extends Object>(
    Expression<T> Function($$InviteLinksTableAnnotationComposer a) f,
  ) {
    final $$InviteLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inviteLinks,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.inviteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomsTable,
          Room,
          $$RoomsTableFilterComposer,
          $$RoomsTableOrderingComposer,
          $$RoomsTableAnnotationComposer,
          $$RoomsTableCreateCompanionBuilder,
          $$RoomsTableUpdateCompanionBuilder,
          (Room, $$RoomsTableReferences),
          Room,
          PrefetchHooks Function({
            bool roomSubscriptionsRefs,
            bool roomEventsRefs,
            bool transactionsRefs,
            bool inviteLinksRefs,
          })
        > {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> lastEventId = const Value.absent(),
                Value<int?> lastEventIndex = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int?> disappearingTimeout = const Value.absent(),
                Value<int?> mutedUntil = const Value.absent(),
                Value<int?> memberLimit = const Value.absent(),
                Value<bool> memberLimitEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion(
                id: id,
                name: name,
                type: type,
                lastEventId: lastEventId,
                lastEventIndex: lastEventIndex,
                unreadCount: unreadCount,
                metadata: metadata,
                disappearingTimeout: disappearingTimeout,
                mutedUntil: mutedUntil,
                memberLimit: memberLimit,
                memberLimitEnabled: memberLimitEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> lastEventId = const Value.absent(),
                Value<int?> lastEventIndex = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int?> disappearingTimeout = const Value.absent(),
                Value<int?> mutedUntil = const Value.absent(),
                Value<int?> memberLimit = const Value.absent(),
                Value<bool> memberLimitEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion.insert(
                id: id,
                name: name,
                type: type,
                lastEventId: lastEventId,
                lastEventIndex: lastEventIndex,
                unreadCount: unreadCount,
                metadata: metadata,
                disappearingTimeout: disappearingTimeout,
                mutedUntil: mutedUntil,
                memberLimit: memberLimit,
                memberLimitEnabled: memberLimitEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoomsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                roomSubscriptionsRefs = false,
                roomEventsRefs = false,
                transactionsRefs = false,
                inviteLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (roomSubscriptionsRefs) db.roomSubscriptions,
                    if (roomEventsRefs) db.roomEvents,
                    if (transactionsRefs) db.transactions,
                    if (inviteLinksRefs) db.inviteLinks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (roomSubscriptionsRefs)
                        await $_getPrefetchedData<
                          Room,
                          $RoomsTable,
                          RoomSubscription
                        >(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._roomSubscriptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(
                                db,
                                table,
                                p0,
                              ).roomSubscriptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (roomEventsRefs)
                        await $_getPrefetchedData<Room, $RoomsTable, RoomEvent>(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._roomEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(
                                db,
                                table,
                                p0,
                              ).roomEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Room,
                          $RoomsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inviteLinksRefs)
                        await $_getPrefetchedData<
                          Room,
                          $RoomsTable,
                          InviteLink
                        >(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._inviteLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(
                                db,
                                table,
                                p0,
                              ).inviteLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomsTable,
      Room,
      $$RoomsTableFilterComposer,
      $$RoomsTableOrderingComposer,
      $$RoomsTableAnnotationComposer,
      $$RoomsTableCreateCompanionBuilder,
      $$RoomsTableUpdateCompanionBuilder,
      (Room, $$RoomsTableReferences),
      Room,
      PrefetchHooks Function({
        bool roomSubscriptionsRefs,
        bool roomEventsRefs,
        bool transactionsRefs,
        bool inviteLinksRefs,
      })
    >;
typedef $$RoomSubscriptionsTableCreateCompanionBuilder =
    RoomSubscriptionsCompanion Function({
      required String id,
      required String roomId,
      Value<String?> profileId,
      Value<String?> contactId,
      Value<String?> role,
      Value<int?> joinedAt,
      Value<int> rowid,
    });
typedef $$RoomSubscriptionsTableUpdateCompanionBuilder =
    RoomSubscriptionsCompanion Function({
      Value<String> id,
      Value<String> roomId,
      Value<String?> profileId,
      Value<String?> contactId,
      Value<String?> role,
      Value<int?> joinedAt,
      Value<int> rowid,
    });

final class $$RoomSubscriptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RoomSubscriptionsTable,
          RoomSubscription
        > {
  $$RoomSubscriptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.roomSubscriptions.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoomSubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $RoomSubscriptionsTable> {
  $$RoomSubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomSubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomSubscriptionsTable> {
  $$RoomSubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomSubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomSubscriptionsTable> {
  $$RoomSubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomSubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomSubscriptionsTable,
          RoomSubscription,
          $$RoomSubscriptionsTableFilterComposer,
          $$RoomSubscriptionsTableOrderingComposer,
          $$RoomSubscriptionsTableAnnotationComposer,
          $$RoomSubscriptionsTableCreateCompanionBuilder,
          $$RoomSubscriptionsTableUpdateCompanionBuilder,
          (RoomSubscription, $$RoomSubscriptionsTableReferences),
          RoomSubscription,
          PrefetchHooks Function({bool roomId})
        > {
  $$RoomSubscriptionsTableTableManager(
    _$AppDatabase db,
    $RoomSubscriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomSubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomSubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomSubscriptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<int?> joinedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomSubscriptionsCompanion(
                id: id,
                roomId: roomId,
                profileId: profileId,
                contactId: contactId,
                role: role,
                joinedAt: joinedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roomId,
                Value<String?> profileId = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<int?> joinedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomSubscriptionsCompanion.insert(
                id: id,
                roomId: roomId,
                profileId: profileId,
                contactId: contactId,
                role: role,
                joinedAt: joinedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoomSubscriptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roomId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (roomId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.roomId,
                                referencedTable:
                                    $$RoomSubscriptionsTableReferences
                                        ._roomIdTable(db),
                                referencedColumn:
                                    $$RoomSubscriptionsTableReferences
                                        ._roomIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RoomSubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomSubscriptionsTable,
      RoomSubscription,
      $$RoomSubscriptionsTableFilterComposer,
      $$RoomSubscriptionsTableOrderingComposer,
      $$RoomSubscriptionsTableAnnotationComposer,
      $$RoomSubscriptionsTableCreateCompanionBuilder,
      $$RoomSubscriptionsTableUpdateCompanionBuilder,
      (RoomSubscription, $$RoomSubscriptionsTableReferences),
      RoomSubscription,
      PrefetchHooks Function({bool roomId})
    >;
typedef $$RoomEventsTableCreateCompanionBuilder =
    RoomEventsCompanion Function({
      required String id,
      required String roomId,
      required String senderId,
      Value<String?> senderContactId,
      required int type,
      Value<String?> content,
      Value<String?> parentId,
      Value<int> status,
      Value<int?> createdAt,
      Value<int?> serverTs,
      Value<String?> localId,
      Value<int?> editedAt,
      Value<String?> originalContent,
      Value<bool> redacted,
      Value<int?> redactedAt,
      Value<String?> redactedBy,
      Value<int> retryCount,
      Value<String?> errorMessage,
      Value<String?> forwardedFromRoom,
      Value<String?> forwardedFromEvent,
      Value<int> forwardCount,
      Value<bool> forwardRestricted,
      Value<int?> expiresAt,
      Value<bool> starred,
      Value<int?> starredAt,
      Value<int> rowid,
    });
typedef $$RoomEventsTableUpdateCompanionBuilder =
    RoomEventsCompanion Function({
      Value<String> id,
      Value<String> roomId,
      Value<String> senderId,
      Value<String?> senderContactId,
      Value<int> type,
      Value<String?> content,
      Value<String?> parentId,
      Value<int> status,
      Value<int?> createdAt,
      Value<int?> serverTs,
      Value<String?> localId,
      Value<int?> editedAt,
      Value<String?> originalContent,
      Value<bool> redacted,
      Value<int?> redactedAt,
      Value<String?> redactedBy,
      Value<int> retryCount,
      Value<String?> errorMessage,
      Value<String?> forwardedFromRoom,
      Value<String?> forwardedFromEvent,
      Value<int> forwardCount,
      Value<bool> forwardRestricted,
      Value<int?> expiresAt,
      Value<bool> starred,
      Value<int?> starredAt,
      Value<int> rowid,
    });

final class $$RoomEventsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomEventsTable, RoomEvent> {
  $$RoomEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.roomEvents.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoomEventsTableFilterComposer
    extends Composer<_$AppDatabase, $RoomEventsTable> {
  $$RoomEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderContactId => $composableBuilder(
    column: $table.senderContactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverTs => $composableBuilder(
    column: $table.serverTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalContent => $composableBuilder(
    column: $table.originalContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get redacted => $composableBuilder(
    column: $table.redacted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get redactedAt => $composableBuilder(
    column: $table.redactedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redactedBy => $composableBuilder(
    column: $table.redactedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forwardedFromRoom => $composableBuilder(
    column: $table.forwardedFromRoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forwardedFromEvent => $composableBuilder(
    column: $table.forwardedFromEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get forwardCount => $composableBuilder(
    column: $table.forwardCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get forwardRestricted => $composableBuilder(
    column: $table.forwardRestricted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get starredAt => $composableBuilder(
    column: $table.starredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomEventsTable> {
  $$RoomEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderContactId => $composableBuilder(
    column: $table.senderContactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverTs => $composableBuilder(
    column: $table.serverTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalContent => $composableBuilder(
    column: $table.originalContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get redacted => $composableBuilder(
    column: $table.redacted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get redactedAt => $composableBuilder(
    column: $table.redactedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redactedBy => $composableBuilder(
    column: $table.redactedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forwardedFromRoom => $composableBuilder(
    column: $table.forwardedFromRoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forwardedFromEvent => $composableBuilder(
    column: $table.forwardedFromEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get forwardCount => $composableBuilder(
    column: $table.forwardCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get forwardRestricted => $composableBuilder(
    column: $table.forwardRestricted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get starredAt => $composableBuilder(
    column: $table.starredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomEventsTable> {
  $$RoomEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderContactId => $composableBuilder(
    column: $table.senderContactId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get serverTs =>
      $composableBuilder(column: $table.serverTs, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get originalContent => $composableBuilder(
    column: $table.originalContent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get redacted =>
      $composableBuilder(column: $table.redacted, builder: (column) => column);

  GeneratedColumn<int> get redactedAt => $composableBuilder(
    column: $table.redactedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redactedBy => $composableBuilder(
    column: $table.redactedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forwardedFromRoom => $composableBuilder(
    column: $table.forwardedFromRoom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forwardedFromEvent => $composableBuilder(
    column: $table.forwardedFromEvent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get forwardCount => $composableBuilder(
    column: $table.forwardCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get forwardRestricted => $composableBuilder(
    column: $table.forwardRestricted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get starred =>
      $composableBuilder(column: $table.starred, builder: (column) => column);

  GeneratedColumn<int> get starredAt =>
      $composableBuilder(column: $table.starredAt, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomEventsTable,
          RoomEvent,
          $$RoomEventsTableFilterComposer,
          $$RoomEventsTableOrderingComposer,
          $$RoomEventsTableAnnotationComposer,
          $$RoomEventsTableCreateCompanionBuilder,
          $$RoomEventsTableUpdateCompanionBuilder,
          (RoomEvent, $$RoomEventsTableReferences),
          RoomEvent,
          PrefetchHooks Function({bool roomId})
        > {
  $$RoomEventsTableTableManager(_$AppDatabase db, $RoomEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String?> senderContactId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> serverTs = const Value.absent(),
                Value<String?> localId = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<String?> originalContent = const Value.absent(),
                Value<bool> redacted = const Value.absent(),
                Value<int?> redactedAt = const Value.absent(),
                Value<String?> redactedBy = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> forwardedFromRoom = const Value.absent(),
                Value<String?> forwardedFromEvent = const Value.absent(),
                Value<int> forwardCount = const Value.absent(),
                Value<bool> forwardRestricted = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<int?> starredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomEventsCompanion(
                id: id,
                roomId: roomId,
                senderId: senderId,
                senderContactId: senderContactId,
                type: type,
                content: content,
                parentId: parentId,
                status: status,
                createdAt: createdAt,
                serverTs: serverTs,
                localId: localId,
                editedAt: editedAt,
                originalContent: originalContent,
                redacted: redacted,
                redactedAt: redactedAt,
                redactedBy: redactedBy,
                retryCount: retryCount,
                errorMessage: errorMessage,
                forwardedFromRoom: forwardedFromRoom,
                forwardedFromEvent: forwardedFromEvent,
                forwardCount: forwardCount,
                forwardRestricted: forwardRestricted,
                expiresAt: expiresAt,
                starred: starred,
                starredAt: starredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roomId,
                required String senderId,
                Value<String?> senderContactId = const Value.absent(),
                required int type,
                Value<String?> content = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> serverTs = const Value.absent(),
                Value<String?> localId = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<String?> originalContent = const Value.absent(),
                Value<bool> redacted = const Value.absent(),
                Value<int?> redactedAt = const Value.absent(),
                Value<String?> redactedBy = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> forwardedFromRoom = const Value.absent(),
                Value<String?> forwardedFromEvent = const Value.absent(),
                Value<int> forwardCount = const Value.absent(),
                Value<bool> forwardRestricted = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<int?> starredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomEventsCompanion.insert(
                id: id,
                roomId: roomId,
                senderId: senderId,
                senderContactId: senderContactId,
                type: type,
                content: content,
                parentId: parentId,
                status: status,
                createdAt: createdAt,
                serverTs: serverTs,
                localId: localId,
                editedAt: editedAt,
                originalContent: originalContent,
                redacted: redacted,
                redactedAt: redactedAt,
                redactedBy: redactedBy,
                retryCount: retryCount,
                errorMessage: errorMessage,
                forwardedFromRoom: forwardedFromRoom,
                forwardedFromEvent: forwardedFromEvent,
                forwardCount: forwardCount,
                forwardRestricted: forwardRestricted,
                expiresAt: expiresAt,
                starred: starred,
                starredAt: starredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoomEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roomId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (roomId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.roomId,
                                referencedTable: $$RoomEventsTableReferences
                                    ._roomIdTable(db),
                                referencedColumn: $$RoomEventsTableReferences
                                    ._roomIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RoomEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomEventsTable,
      RoomEvent,
      $$RoomEventsTableFilterComposer,
      $$RoomEventsTableOrderingComposer,
      $$RoomEventsTableAnnotationComposer,
      $$RoomEventsTableCreateCompanionBuilder,
      $$RoomEventsTableUpdateCompanionBuilder,
      (RoomEvent, $$RoomEventsTableReferences),
      RoomEvent,
      PrefetchHooks Function({bool roomId})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String sessionId,
      required String profileId,
      required String deviceId,
      Value<Uint8List?> ratchetState,
      Value<int?> createdAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> sessionId,
      Value<String> profileId,
      Value<String> deviceId,
      Value<Uint8List?> ratchetState,
      Value<int?> createdAt,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ratchetState => $composableBuilder(
    column: $table.ratchetState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ratchetState => $composableBuilder(
    column: $table.ratchetState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<Uint8List> get ratchetState => $composableBuilder(
    column: $table.ratchetState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<Uint8List?> ratchetState = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                sessionId: sessionId,
                profileId: profileId,
                deviceId: deviceId,
                ratchetState: ratchetState,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String profileId,
                required String deviceId,
                Value<Uint8List?> ratchetState = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                sessionId: sessionId,
                profileId: profileId,
                deviceId: deviceId,
                ratchetState: ratchetState,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$PrekeysTableCreateCompanionBuilder =
    PrekeysCompanion Function({
      Value<int> id,
      Value<String?> publicKey,
      Value<String?> privateKey,
      Value<bool> isSigned,
    });
typedef $$PrekeysTableUpdateCompanionBuilder =
    PrekeysCompanion Function({
      Value<int> id,
      Value<String?> publicKey,
      Value<String?> privateKey,
      Value<bool> isSigned,
    });

class $$PrekeysTableFilterComposer
    extends Composer<_$AppDatabase, $PrekeysTable> {
  $$PrekeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSigned => $composableBuilder(
    column: $table.isSigned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrekeysTableOrderingComposer
    extends Composer<_$AppDatabase, $PrekeysTable> {
  $$PrekeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSigned => $composableBuilder(
    column: $table.isSigned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrekeysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrekeysTable> {
  $$PrekeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSigned =>
      $composableBuilder(column: $table.isSigned, builder: (column) => column);
}

class $$PrekeysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrekeysTable,
          Prekey,
          $$PrekeysTableFilterComposer,
          $$PrekeysTableOrderingComposer,
          $$PrekeysTableAnnotationComposer,
          $$PrekeysTableCreateCompanionBuilder,
          $$PrekeysTableUpdateCompanionBuilder,
          (Prekey, BaseReferences<_$AppDatabase, $PrekeysTable, Prekey>),
          Prekey,
          PrefetchHooks Function()
        > {
  $$PrekeysTableTableManager(_$AppDatabase db, $PrekeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrekeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrekeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrekeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<String?> privateKey = const Value.absent(),
                Value<bool> isSigned = const Value.absent(),
              }) => PrekeysCompanion(
                id: id,
                publicKey: publicKey,
                privateKey: privateKey,
                isSigned: isSigned,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<String?> privateKey = const Value.absent(),
                Value<bool> isSigned = const Value.absent(),
              }) => PrekeysCompanion.insert(
                id: id,
                publicKey: publicKey,
                privateKey: privateKey,
                isSigned: isSigned,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrekeysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrekeysTable,
      Prekey,
      $$PrekeysTableFilterComposer,
      $$PrekeysTableOrderingComposer,
      $$PrekeysTableAnnotationComposer,
      $$PrekeysTableCreateCompanionBuilder,
      $$PrekeysTableUpdateCompanionBuilder,
      (Prekey, BaseReferences<_$AppDatabase, $PrekeysTable, Prekey>),
      Prekey,
      PrefetchHooks Function()
    >;
typedef $$PendingJobsTableCreateCompanionBuilder =
    PendingJobsCompanion Function({
      Value<int> id,
      required String type,
      Value<String?> payload,
      Value<int?> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<int?> nextRetryAt,
      Value<int> priority,
      Value<String?> lastError,
    });
typedef $$PendingJobsTableUpdateCompanionBuilder =
    PendingJobsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String?> payload,
      Value<int?> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<int?> nextRetryAt,
      Value<int> priority,
      Value<String?> lastError,
    });

class $$PendingJobsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingJobsTable> {
  $$PendingJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingJobsTable> {
  $$PendingJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingJobsTable> {
  $$PendingJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingJobsTable,
          PendingJob,
          $$PendingJobsTableFilterComposer,
          $$PendingJobsTableOrderingComposer,
          $$PendingJobsTableAnnotationComposer,
          $$PendingJobsTableCreateCompanionBuilder,
          $$PendingJobsTableUpdateCompanionBuilder,
          (
            PendingJob,
            BaseReferences<_$AppDatabase, $PendingJobsTable, PendingJob>,
          ),
          PendingJob,
          PrefetchHooks Function()
        > {
  $$PendingJobsTableTableManager(_$AppDatabase db, $PendingJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> nextRetryAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingJobsCompanion(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                nextRetryAt: nextRetryAt,
                priority: priority,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                Value<String?> payload = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> nextRetryAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingJobsCompanion.insert(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                nextRetryAt: nextRetryAt,
                priority: priority,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingJobsTable,
      PendingJob,
      $$PendingJobsTableFilterComposer,
      $$PendingJobsTableOrderingComposer,
      $$PendingJobsTableAnnotationComposer,
      $$PendingJobsTableCreateCompanionBuilder,
      $$PendingJobsTableUpdateCompanionBuilder,
      (
        PendingJob,
        BaseReferences<_$AppDatabase, $PendingJobsTable, PendingJob>,
      ),
      PendingJob,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String roomId,
      Value<String?> amount,
      Value<String?> currency,
      Value<String?> status,
      Value<String?> initiatorId,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> roomId,
      Value<String?> amount,
      Value<String?> currency,
      Value<String?> status,
      Value<String?> initiatorId,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.transactions.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initiatorId => $composableBuilder(
    column: $table.initiatorId,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initiatorId => $composableBuilder(
    column: $table.initiatorId,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get initiatorId => $composableBuilder(
    column: $table.initiatorId,
    builder: (column) => column,
  );

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool roomId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String?> amount = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> initiatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                roomId: roomId,
                amount: amount,
                currency: currency,
                status: status,
                initiatorId: initiatorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roomId,
                Value<String?> amount = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> initiatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                roomId: roomId,
                amount: amount,
                currency: currency,
                status: status,
                initiatorId: initiatorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roomId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (roomId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.roomId,
                                referencedTable: $$TransactionsTableReferences
                                    ._roomIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._roomIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool roomId})
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String key,
      Value<String?> value,
      Value<int?> updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int?> updatedAt,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataData,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataData,
            BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
          ),
          SyncMetadataData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataData,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataData,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
      ),
      SyncMetadataData,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      required String key,
      required String value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSetting,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
      ),
      UserSetting,
      PrefetchHooks Function()
    >;
typedef $$DraftsTableCreateCompanionBuilder =
    DraftsCompanion Function({
      required String roomId,
      required String content,
      Value<String?> replyToId,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DraftsTableUpdateCompanionBuilder =
    DraftsCompanion Function({
      Value<String> roomId,
      Value<String> content,
      Value<String?> replyToId,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftsTable,
          Draft,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
          Draft,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> roomId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion(
                roomId: roomId,
                content: content,
                replyToId: replyToId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String roomId,
                required String content,
                Value<String?> replyToId = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion.insert(
                roomId: roomId,
                content: content,
                replyToId: replyToId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftsTable,
      Draft,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
      Draft,
      PrefetchHooks Function()
    >;
typedef $$ReadReceiptsTableCreateCompanionBuilder =
    ReadReceiptsCompanion Function({
      Value<int> id,
      required String eventId,
      required String roomId,
      required String profileId,
      required int readAt,
    });
typedef $$ReadReceiptsTableUpdateCompanionBuilder =
    ReadReceiptsCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> roomId,
      Value<String> profileId,
      Value<int> readAt,
    });

class $$ReadReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadReceiptsTable> {
  $$ReadReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadReceiptsTable> {
  $$ReadReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadReceiptsTable> {
  $$ReadReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);
}

class $$ReadReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadReceiptsTable,
          ReadReceipt,
          $$ReadReceiptsTableFilterComposer,
          $$ReadReceiptsTableOrderingComposer,
          $$ReadReceiptsTableAnnotationComposer,
          $$ReadReceiptsTableCreateCompanionBuilder,
          $$ReadReceiptsTableUpdateCompanionBuilder,
          (
            ReadReceipt,
            BaseReferences<_$AppDatabase, $ReadReceiptsTable, ReadReceipt>,
          ),
          ReadReceipt,
          PrefetchHooks Function()
        > {
  $$ReadReceiptsTableTableManager(_$AppDatabase db, $ReadReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<int> readAt = const Value.absent(),
              }) => ReadReceiptsCompanion(
                id: id,
                eventId: eventId,
                roomId: roomId,
                profileId: profileId,
                readAt: readAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventId,
                required String roomId,
                required String profileId,
                required int readAt,
              }) => ReadReceiptsCompanion.insert(
                id: id,
                eventId: eventId,
                roomId: roomId,
                profileId: profileId,
                readAt: readAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadReceiptsTable,
      ReadReceipt,
      $$ReadReceiptsTableFilterComposer,
      $$ReadReceiptsTableOrderingComposer,
      $$ReadReceiptsTableAnnotationComposer,
      $$ReadReceiptsTableCreateCompanionBuilder,
      $$ReadReceiptsTableUpdateCompanionBuilder,
      (
        ReadReceipt,
        BaseReferences<_$AppDatabase, $ReadReceiptsTable, ReadReceipt>,
      ),
      ReadReceipt,
      PrefetchHooks Function()
    >;
typedef $$ReportsTableCreateCompanionBuilder =
    ReportsCompanion Function({
      required String id,
      required String reportedUserId,
      required String reason,
      Value<String?> details,
      Value<String?> evidenceEventIds,
      required int reportedAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$ReportsTableUpdateCompanionBuilder =
    ReportsCompanion Function({
      Value<String> id,
      Value<String> reportedUserId,
      Value<String> reason,
      Value<String?> details,
      Value<String?> evidenceEventIds,
      Value<int> reportedAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$ReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportedUserId => $composableBuilder(
    column: $table.reportedUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceEventIds => $composableBuilder(
    column: $table.evidenceEventIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportedUserId => $composableBuilder(
    column: $table.reportedUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceEventIds => $composableBuilder(
    column: $table.evidenceEventIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportedUserId => $composableBuilder(
    column: $table.reportedUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get evidenceEventIds => $composableBuilder(
    column: $table.evidenceEventIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReportsTable,
          Report,
          $$ReportsTableFilterComposer,
          $$ReportsTableOrderingComposer,
          $$ReportsTableAnnotationComposer,
          $$ReportsTableCreateCompanionBuilder,
          $$ReportsTableUpdateCompanionBuilder,
          (Report, BaseReferences<_$AppDatabase, $ReportsTable, Report>),
          Report,
          PrefetchHooks Function()
        > {
  $$ReportsTableTableManager(_$AppDatabase db, $ReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reportedUserId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String?> evidenceEventIds = const Value.absent(),
                Value<int> reportedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion(
                id: id,
                reportedUserId: reportedUserId,
                reason: reason,
                details: details,
                evidenceEventIds: evidenceEventIds,
                reportedAt: reportedAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reportedUserId,
                required String reason,
                Value<String?> details = const Value.absent(),
                Value<String?> evidenceEventIds = const Value.absent(),
                required int reportedAt,
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion.insert(
                id: id,
                reportedUserId: reportedUserId,
                reason: reason,
                details: details,
                evidenceEventIds: evidenceEventIds,
                reportedAt: reportedAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReportsTable,
      Report,
      $$ReportsTableFilterComposer,
      $$ReportsTableOrderingComposer,
      $$ReportsTableAnnotationComposer,
      $$ReportsTableCreateCompanionBuilder,
      $$ReportsTableUpdateCompanionBuilder,
      (Report, BaseReferences<_$AppDatabase, $ReportsTable, Report>),
      Report,
      PrefetchHooks Function()
    >;
typedef $$InviteLinksTableCreateCompanionBuilder =
    InviteLinksCompanion Function({
      required String id,
      required String roomId,
      required String code,
      required String createdBy,
      required int createdAt,
      Value<int?> expiresAt,
      Value<int?> maxUses,
      Value<int> useCount,
      Value<bool> revoked,
      Value<bool> requiresApproval,
      Value<String?> name,
      Value<int> rowid,
    });
typedef $$InviteLinksTableUpdateCompanionBuilder =
    InviteLinksCompanion Function({
      Value<String> id,
      Value<String> roomId,
      Value<String> code,
      Value<String> createdBy,
      Value<int> createdAt,
      Value<int?> expiresAt,
      Value<int?> maxUses,
      Value<int> useCount,
      Value<bool> revoked,
      Value<bool> requiresApproval,
      Value<String?> name,
      Value<int> rowid,
    });

final class $$InviteLinksTableReferences
    extends BaseReferences<_$AppDatabase, $InviteLinksTable, InviteLink> {
  $$InviteLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.inviteLinks.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InviteLinkJoinsTable, List<InviteLinkJoin>>
  _inviteLinkJoinsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inviteLinkJoins,
    aliasName: $_aliasNameGenerator(
      db.inviteLinks.id,
      db.inviteLinkJoins.inviteLinkId,
    ),
  );

  $$InviteLinkJoinsTableProcessedTableManager get inviteLinkJoinsRefs {
    final manager = $$InviteLinkJoinsTableTableManager(
      $_db,
      $_db.inviteLinkJoins,
    ).filter((f) => f.inviteLinkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inviteLinkJoinsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InviteLinksTableFilterComposer
    extends Composer<_$AppDatabase, $InviteLinksTable> {
  $$InviteLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxUses => $composableBuilder(
    column: $table.maxUses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get revoked => $composableBuilder(
    column: $table.revoked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresApproval => $composableBuilder(
    column: $table.requiresApproval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> inviteLinkJoinsRefs(
    Expression<bool> Function($$InviteLinkJoinsTableFilterComposer f) f,
  ) {
    final $$InviteLinkJoinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inviteLinkJoins,
      getReferencedColumn: (t) => t.inviteLinkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinkJoinsTableFilterComposer(
            $db: $db,
            $table: $db.inviteLinkJoins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InviteLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $InviteLinksTable> {
  $$InviteLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxUses => $composableBuilder(
    column: $table.maxUses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get revoked => $composableBuilder(
    column: $table.revoked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresApproval => $composableBuilder(
    column: $table.requiresApproval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $InviteLinksTable> {
  $$InviteLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get maxUses =>
      $composableBuilder(column: $table.maxUses, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<bool> get revoked =>
      $composableBuilder(column: $table.revoked, builder: (column) => column);

  GeneratedColumn<bool> get requiresApproval => $composableBuilder(
    column: $table.requiresApproval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> inviteLinkJoinsRefs<T extends Object>(
    Expression<T> Function($$InviteLinkJoinsTableAnnotationComposer a) f,
  ) {
    final $$InviteLinkJoinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inviteLinkJoins,
      getReferencedColumn: (t) => t.inviteLinkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinkJoinsTableAnnotationComposer(
            $db: $db,
            $table: $db.inviteLinkJoins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InviteLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InviteLinksTable,
          InviteLink,
          $$InviteLinksTableFilterComposer,
          $$InviteLinksTableOrderingComposer,
          $$InviteLinksTableAnnotationComposer,
          $$InviteLinksTableCreateCompanionBuilder,
          $$InviteLinksTableUpdateCompanionBuilder,
          (InviteLink, $$InviteLinksTableReferences),
          InviteLink,
          PrefetchHooks Function({bool roomId, bool inviteLinkJoinsRefs})
        > {
  $$InviteLinksTableTableManager(_$AppDatabase db, $InviteLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InviteLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InviteLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InviteLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<int?> maxUses = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<bool> revoked = const Value.absent(),
                Value<bool> requiresApproval = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InviteLinksCompanion(
                id: id,
                roomId: roomId,
                code: code,
                createdBy: createdBy,
                createdAt: createdAt,
                expiresAt: expiresAt,
                maxUses: maxUses,
                useCount: useCount,
                revoked: revoked,
                requiresApproval: requiresApproval,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roomId,
                required String code,
                required String createdBy,
                required int createdAt,
                Value<int?> expiresAt = const Value.absent(),
                Value<int?> maxUses = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<bool> revoked = const Value.absent(),
                Value<bool> requiresApproval = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InviteLinksCompanion.insert(
                id: id,
                roomId: roomId,
                code: code,
                createdBy: createdBy,
                createdAt: createdAt,
                expiresAt: expiresAt,
                maxUses: maxUses,
                useCount: useCount,
                revoked: revoked,
                requiresApproval: requiresApproval,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InviteLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({roomId = false, inviteLinkJoinsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (inviteLinkJoinsRefs) db.inviteLinkJoins,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (roomId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.roomId,
                                    referencedTable:
                                        $$InviteLinksTableReferences
                                            ._roomIdTable(db),
                                    referencedColumn:
                                        $$InviteLinksTableReferences
                                            ._roomIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (inviteLinkJoinsRefs)
                        await $_getPrefetchedData<
                          InviteLink,
                          $InviteLinksTable,
                          InviteLinkJoin
                        >(
                          currentTable: table,
                          referencedTable: $$InviteLinksTableReferences
                              ._inviteLinkJoinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InviteLinksTableReferences(
                                db,
                                table,
                                p0,
                              ).inviteLinkJoinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.inviteLinkId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InviteLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InviteLinksTable,
      InviteLink,
      $$InviteLinksTableFilterComposer,
      $$InviteLinksTableOrderingComposer,
      $$InviteLinksTableAnnotationComposer,
      $$InviteLinksTableCreateCompanionBuilder,
      $$InviteLinksTableUpdateCompanionBuilder,
      (InviteLink, $$InviteLinksTableReferences),
      InviteLink,
      PrefetchHooks Function({bool roomId, bool inviteLinkJoinsRefs})
    >;
typedef $$InviteLinkJoinsTableCreateCompanionBuilder =
    InviteLinkJoinsCompanion Function({
      Value<int> id,
      required String inviteLinkId,
      required String profileId,
      required int joinedAt,
      Value<String> status,
    });
typedef $$InviteLinkJoinsTableUpdateCompanionBuilder =
    InviteLinkJoinsCompanion Function({
      Value<int> id,
      Value<String> inviteLinkId,
      Value<String> profileId,
      Value<int> joinedAt,
      Value<String> status,
    });

final class $$InviteLinkJoinsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InviteLinkJoinsTable, InviteLinkJoin> {
  $$InviteLinkJoinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InviteLinksTable _inviteLinkIdTable(_$AppDatabase db) =>
      db.inviteLinks.createAlias(
        $_aliasNameGenerator(
          db.inviteLinkJoins.inviteLinkId,
          db.inviteLinks.id,
        ),
      );

  $$InviteLinksTableProcessedTableManager get inviteLinkId {
    final $_column = $_itemColumn<String>('invite_link_id')!;

    final manager = $$InviteLinksTableTableManager(
      $_db,
      $_db.inviteLinks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inviteLinkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InviteLinkJoinsTableFilterComposer
    extends Composer<_$AppDatabase, $InviteLinkJoinsTable> {
  $$InviteLinkJoinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$InviteLinksTableFilterComposer get inviteLinkId {
    final $$InviteLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inviteLinkId,
      referencedTable: $db.inviteLinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinksTableFilterComposer(
            $db: $db,
            $table: $db.inviteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteLinkJoinsTableOrderingComposer
    extends Composer<_$AppDatabase, $InviteLinkJoinsTable> {
  $$InviteLinkJoinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$InviteLinksTableOrderingComposer get inviteLinkId {
    final $$InviteLinksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inviteLinkId,
      referencedTable: $db.inviteLinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinksTableOrderingComposer(
            $db: $db,
            $table: $db.inviteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteLinkJoinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InviteLinkJoinsTable> {
  $$InviteLinkJoinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$InviteLinksTableAnnotationComposer get inviteLinkId {
    final $$InviteLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inviteLinkId,
      referencedTable: $db.inviteLinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InviteLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.inviteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteLinkJoinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InviteLinkJoinsTable,
          InviteLinkJoin,
          $$InviteLinkJoinsTableFilterComposer,
          $$InviteLinkJoinsTableOrderingComposer,
          $$InviteLinkJoinsTableAnnotationComposer,
          $$InviteLinkJoinsTableCreateCompanionBuilder,
          $$InviteLinkJoinsTableUpdateCompanionBuilder,
          (InviteLinkJoin, $$InviteLinkJoinsTableReferences),
          InviteLinkJoin,
          PrefetchHooks Function({bool inviteLinkId})
        > {
  $$InviteLinkJoinsTableTableManager(
    _$AppDatabase db,
    $InviteLinkJoinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InviteLinkJoinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InviteLinkJoinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InviteLinkJoinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> inviteLinkId = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<int> joinedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => InviteLinkJoinsCompanion(
                id: id,
                inviteLinkId: inviteLinkId,
                profileId: profileId,
                joinedAt: joinedAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String inviteLinkId,
                required String profileId,
                required int joinedAt,
                Value<String> status = const Value.absent(),
              }) => InviteLinkJoinsCompanion.insert(
                id: id,
                inviteLinkId: inviteLinkId,
                profileId: profileId,
                joinedAt: joinedAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InviteLinkJoinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inviteLinkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inviteLinkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inviteLinkId,
                                referencedTable:
                                    $$InviteLinkJoinsTableReferences
                                        ._inviteLinkIdTable(db),
                                referencedColumn:
                                    $$InviteLinkJoinsTableReferences
                                        ._inviteLinkIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InviteLinkJoinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InviteLinkJoinsTable,
      InviteLinkJoin,
      $$InviteLinkJoinsTableFilterComposer,
      $$InviteLinkJoinsTableOrderingComposer,
      $$InviteLinkJoinsTableAnnotationComposer,
      $$InviteLinkJoinsTableCreateCompanionBuilder,
      $$InviteLinkJoinsTableUpdateCompanionBuilder,
      (InviteLinkJoin, $$InviteLinkJoinsTableReferences),
      InviteLinkJoin,
      PrefetchHooks Function({bool inviteLinkId})
    >;
typedef $$UploadChunksTableCreateCompanionBuilder =
    UploadChunksCompanion Function({
      Value<int> id,
      required String localId,
      Value<String?> uploadId,
      Value<int> chunkIndex,
      Value<int> chunkSize,
      required int createdAt,
    });
typedef $$UploadChunksTableUpdateCompanionBuilder =
    UploadChunksCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String?> uploadId,
      Value<int> chunkIndex,
      Value<int> chunkSize,
      Value<int> createdAt,
    });

class $$UploadChunksTableFilterComposer
    extends Composer<_$AppDatabase, $UploadChunksTable> {
  $$UploadChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkSize => $composableBuilder(
    column: $table.chunkSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UploadChunksTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadChunksTable> {
  $$UploadChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkSize => $composableBuilder(
    column: $table.chunkSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadChunksTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadChunksTable> {
  $$UploadChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get uploadId =>
      $composableBuilder(column: $table.uploadId, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chunkSize =>
      $composableBuilder(column: $table.chunkSize, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UploadChunksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UploadChunksTable,
          UploadChunk,
          $$UploadChunksTableFilterComposer,
          $$UploadChunksTableOrderingComposer,
          $$UploadChunksTableAnnotationComposer,
          $$UploadChunksTableCreateCompanionBuilder,
          $$UploadChunksTableUpdateCompanionBuilder,
          (
            UploadChunk,
            BaseReferences<_$AppDatabase, $UploadChunksTable, UploadChunk>,
          ),
          UploadChunk,
          PrefetchHooks Function()
        > {
  $$UploadChunksTableTableManager(_$AppDatabase db, $UploadChunksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String?> uploadId = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<int> chunkSize = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => UploadChunksCompanion(
                id: id,
                localId: localId,
                uploadId: uploadId,
                chunkIndex: chunkIndex,
                chunkSize: chunkSize,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                Value<String?> uploadId = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<int> chunkSize = const Value.absent(),
                required int createdAt,
              }) => UploadChunksCompanion.insert(
                id: id,
                localId: localId,
                uploadId: uploadId,
                chunkIndex: chunkIndex,
                chunkSize: chunkSize,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UploadChunksTable,
      UploadChunk,
      $$UploadChunksTableFilterComposer,
      $$UploadChunksTableOrderingComposer,
      $$UploadChunksTableAnnotationComposer,
      $$UploadChunksTableCreateCompanionBuilder,
      $$UploadChunksTableUpdateCompanionBuilder,
      (
        UploadChunk,
        BaseReferences<_$AppDatabase, $UploadChunksTable, UploadChunk>,
      ),
      UploadChunk,
      PrefetchHooks Function()
    >;
typedef $$DownloadChunksTableCreateCompanionBuilder =
    DownloadChunksCompanion Function({
      Value<int> id,
      required String downloadId,
      required String fileUrl,
      required String localPath,
      required int totalSize,
      Value<int> chunkIndex,
      Value<int> chunkSize,
      Value<int> bytesDownloaded,
      Value<String?> etag,
      required int createdAt,
      Value<int?> updatedAt,
    });
typedef $$DownloadChunksTableUpdateCompanionBuilder =
    DownloadChunksCompanion Function({
      Value<int> id,
      Value<String> downloadId,
      Value<String> fileUrl,
      Value<String> localPath,
      Value<int> totalSize,
      Value<int> chunkIndex,
      Value<int> chunkSize,
      Value<int> bytesDownloaded,
      Value<String?> etag,
      Value<int> createdAt,
      Value<int?> updatedAt,
    });

class $$DownloadChunksTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadChunksTable> {
  $$DownloadChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadId => $composableBuilder(
    column: $table.downloadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkSize => $composableBuilder(
    column: $table.chunkSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesDownloaded => $composableBuilder(
    column: $table.bytesDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadChunksTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadChunksTable> {
  $$DownloadChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadId => $composableBuilder(
    column: $table.downloadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkSize => $composableBuilder(
    column: $table.chunkSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesDownloaded => $composableBuilder(
    column: $table.bytesDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadChunksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadChunksTable> {
  $$DownloadChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get downloadId => $composableBuilder(
    column: $table.downloadId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get totalSize =>
      $composableBuilder(column: $table.totalSize, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chunkSize =>
      $composableBuilder(column: $table.chunkSize, builder: (column) => column);

  GeneratedColumn<int> get bytesDownloaded => $composableBuilder(
    column: $table.bytesDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DownloadChunksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadChunksTable,
          DownloadChunk,
          $$DownloadChunksTableFilterComposer,
          $$DownloadChunksTableOrderingComposer,
          $$DownloadChunksTableAnnotationComposer,
          $$DownloadChunksTableCreateCompanionBuilder,
          $$DownloadChunksTableUpdateCompanionBuilder,
          (
            DownloadChunk,
            BaseReferences<_$AppDatabase, $DownloadChunksTable, DownloadChunk>,
          ),
          DownloadChunk,
          PrefetchHooks Function()
        > {
  $$DownloadChunksTableTableManager(
    _$AppDatabase db,
    $DownloadChunksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> downloadId = const Value.absent(),
                Value<String> fileUrl = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<int> chunkSize = const Value.absent(),
                Value<int> bytesDownloaded = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
              }) => DownloadChunksCompanion(
                id: id,
                downloadId: downloadId,
                fileUrl: fileUrl,
                localPath: localPath,
                totalSize: totalSize,
                chunkIndex: chunkIndex,
                chunkSize: chunkSize,
                bytesDownloaded: bytesDownloaded,
                etag: etag,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String downloadId,
                required String fileUrl,
                required String localPath,
                required int totalSize,
                Value<int> chunkIndex = const Value.absent(),
                Value<int> chunkSize = const Value.absent(),
                Value<int> bytesDownloaded = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                required int createdAt,
                Value<int?> updatedAt = const Value.absent(),
              }) => DownloadChunksCompanion.insert(
                id: id,
                downloadId: downloadId,
                fileUrl: fileUrl,
                localPath: localPath,
                totalSize: totalSize,
                chunkIndex: chunkIndex,
                chunkSize: chunkSize,
                bytesDownloaded: bytesDownloaded,
                etag: etag,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadChunksTable,
      DownloadChunk,
      $$DownloadChunksTableFilterComposer,
      $$DownloadChunksTableOrderingComposer,
      $$DownloadChunksTableAnnotationComposer,
      $$DownloadChunksTableCreateCompanionBuilder,
      $$DownloadChunksTableUpdateCompanionBuilder,
      (
        DownloadChunk,
        BaseReferences<_$AppDatabase, $DownloadChunksTable, DownloadChunk>,
      ),
      DownloadChunk,
      PrefetchHooks Function()
    >;
typedef $$TransferJobsTableCreateCompanionBuilder =
    TransferJobsCompanion Function({
      Value<int> id,
      required String transferType,
      required String referenceId,
      required String roomId,
      required String fileUrl,
      required String localPath,
      required String fileName,
      required int totalSize,
      Value<int> transferredSize,
      Value<String?> mimeType,
      Value<int> priority,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      required int createdAt,
      Value<int?> updatedAt,
      Value<int?> nextRetryAt,
    });
typedef $$TransferJobsTableUpdateCompanionBuilder =
    TransferJobsCompanion Function({
      Value<int> id,
      Value<String> transferType,
      Value<String> referenceId,
      Value<String> roomId,
      Value<String> fileUrl,
      Value<String> localPath,
      Value<String> fileName,
      Value<int> totalSize,
      Value<int> transferredSize,
      Value<String?> mimeType,
      Value<int> priority,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<int?> updatedAt,
      Value<int?> nextRetryAt,
    });

class $$TransferJobsTableFilterComposer
    extends Composer<_$AppDatabase, $TransferJobsTable> {
  $$TransferJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferType => $composableBuilder(
    column: $table.transferType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transferredSize => $composableBuilder(
    column: $table.transferredSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransferJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferJobsTable> {
  $$TransferJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferType => $composableBuilder(
    column: $table.transferType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transferredSize => $composableBuilder(
    column: $table.transferredSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferJobsTable> {
  $$TransferJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transferType => $composableBuilder(
    column: $table.transferType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get totalSize =>
      $composableBuilder(column: $table.totalSize, builder: (column) => column);

  GeneratedColumn<int> get transferredSize => $composableBuilder(
    column: $table.transferredSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );
}

class $$TransferJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferJobsTable,
          TransferJob,
          $$TransferJobsTableFilterComposer,
          $$TransferJobsTableOrderingComposer,
          $$TransferJobsTableAnnotationComposer,
          $$TransferJobsTableCreateCompanionBuilder,
          $$TransferJobsTableUpdateCompanionBuilder,
          (
            TransferJob,
            BaseReferences<_$AppDatabase, $TransferJobsTable, TransferJob>,
          ),
          TransferJob,
          PrefetchHooks Function()
        > {
  $$TransferJobsTableTableManager(_$AppDatabase db, $TransferJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> transferType = const Value.absent(),
                Value<String> referenceId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> fileUrl = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<int> transferredSize = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> nextRetryAt = const Value.absent(),
              }) => TransferJobsCompanion(
                id: id,
                transferType: transferType,
                referenceId: referenceId,
                roomId: roomId,
                fileUrl: fileUrl,
                localPath: localPath,
                fileName: fileName,
                totalSize: totalSize,
                transferredSize: transferredSize,
                mimeType: mimeType,
                priority: priority,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                nextRetryAt: nextRetryAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String transferType,
                required String referenceId,
                required String roomId,
                required String fileUrl,
                required String localPath,
                required String fileName,
                required int totalSize,
                Value<int> transferredSize = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> nextRetryAt = const Value.absent(),
              }) => TransferJobsCompanion.insert(
                id: id,
                transferType: transferType,
                referenceId: referenceId,
                roomId: roomId,
                fileUrl: fileUrl,
                localPath: localPath,
                fileName: fileName,
                totalSize: totalSize,
                transferredSize: transferredSize,
                mimeType: mimeType,
                priority: priority,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                nextRetryAt: nextRetryAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransferJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferJobsTable,
      TransferJob,
      $$TransferJobsTableFilterComposer,
      $$TransferJobsTableOrderingComposer,
      $$TransferJobsTableAnnotationComposer,
      $$TransferJobsTableCreateCompanionBuilder,
      $$TransferJobsTableUpdateCompanionBuilder,
      (
        TransferJob,
        BaseReferences<_$AppDatabase, $TransferJobsTable, TransferJob>,
      ),
      TransferJob,
      PrefetchHooks Function()
    >;
typedef $$CallHistoryTableCreateCompanionBuilder =
    CallHistoryCompanion Function({
      Value<int> id,
      required String roomId,
      required String callerId,
      Value<String?> recipientId,
      Value<int> callType,
      Value<int> direction,
      Value<int> status,
      required int startedAt,
      Value<int?> answeredAt,
      Value<int?> endedAt,
      Value<int> duration,
      Value<bool> isRead,
      Value<bool> isDeleted,
    });
typedef $$CallHistoryTableUpdateCompanionBuilder =
    CallHistoryCompanion Function({
      Value<int> id,
      Value<String> roomId,
      Value<String> callerId,
      Value<String?> recipientId,
      Value<int> callType,
      Value<int> direction,
      Value<int> status,
      Value<int> startedAt,
      Value<int?> answeredAt,
      Value<int?> endedAt,
      Value<int> duration,
      Value<bool> isRead,
      Value<bool> isDeleted,
    });

class $$CallHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $CallHistoryTable> {
  $$CallHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get callerId => $composableBuilder(
    column: $table.callerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get callType => $composableBuilder(
    column: $table.callType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CallHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $CallHistoryTable> {
  $$CallHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get callerId => $composableBuilder(
    column: $table.callerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get callType => $composableBuilder(
    column: $table.callType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CallHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallHistoryTable> {
  $$CallHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get callerId =>
      $composableBuilder(column: $table.callerId, builder: (column) => column);

  GeneratedColumn<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get callType =>
      $composableBuilder(column: $table.callType, builder: (column) => column);

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CallHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallHistoryTable,
          CallHistoryData,
          $$CallHistoryTableFilterComposer,
          $$CallHistoryTableOrderingComposer,
          $$CallHistoryTableAnnotationComposer,
          $$CallHistoryTableCreateCompanionBuilder,
          $$CallHistoryTableUpdateCompanionBuilder,
          (
            CallHistoryData,
            BaseReferences<_$AppDatabase, $CallHistoryTable, CallHistoryData>,
          ),
          CallHistoryData,
          PrefetchHooks Function()
        > {
  $$CallHistoryTableTableManager(_$AppDatabase db, $CallHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> callerId = const Value.absent(),
                Value<String?> recipientId = const Value.absent(),
                Value<int> callType = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> answeredAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => CallHistoryCompanion(
                id: id,
                roomId: roomId,
                callerId: callerId,
                recipientId: recipientId,
                callType: callType,
                direction: direction,
                status: status,
                startedAt: startedAt,
                answeredAt: answeredAt,
                endedAt: endedAt,
                duration: duration,
                isRead: isRead,
                isDeleted: isDeleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String roomId,
                required String callerId,
                Value<String?> recipientId = const Value.absent(),
                Value<int> callType = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> status = const Value.absent(),
                required int startedAt,
                Value<int?> answeredAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => CallHistoryCompanion.insert(
                id: id,
                roomId: roomId,
                callerId: callerId,
                recipientId: recipientId,
                callType: callType,
                direction: direction,
                status: status,
                startedAt: startedAt,
                answeredAt: answeredAt,
                endedAt: endedAt,
                duration: duration,
                isRead: isRead,
                isDeleted: isDeleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CallHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallHistoryTable,
      CallHistoryData,
      $$CallHistoryTableFilterComposer,
      $$CallHistoryTableOrderingComposer,
      $$CallHistoryTableAnnotationComposer,
      $$CallHistoryTableCreateCompanionBuilder,
      $$CallHistoryTableUpdateCompanionBuilder,
      (
        CallHistoryData,
        BaseReferences<_$AppDatabase, $CallHistoryTable, CallHistoryData>,
      ),
      CallHistoryData,
      PrefetchHooks Function()
    >;
typedef $$AnalyticsEventsTableCreateCompanionBuilder =
    AnalyticsEventsCompanion Function({
      Value<int> id,
      required String eventId,
      required String eventType,
      required String eventName,
      Value<String?> userId,
      Value<String?> sessionId,
      Value<String?> screenName,
      Value<String?> properties,
      required int timestamp,
      Value<bool> isSynced,
      Value<int?> syncedAt,
    });
typedef $$AnalyticsEventsTableUpdateCompanionBuilder =
    AnalyticsEventsCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> eventType,
      Value<String> eventName,
      Value<String?> userId,
      Value<String?> sessionId,
      Value<String?> screenName,
      Value<String?> properties,
      Value<int> timestamp,
      Value<bool> isSynced,
      Value<int?> syncedAt,
    });

class $$AnalyticsEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AnalyticsEventsTable> {
  $$AnalyticsEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalyticsEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalyticsEventsTable> {
  $$AnalyticsEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalyticsEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalyticsEventsTable> {
  $$AnalyticsEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get eventName =>
      $composableBuilder(column: $table.eventName, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$AnalyticsEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnalyticsEventsTable,
          AnalyticsEvent,
          $$AnalyticsEventsTableFilterComposer,
          $$AnalyticsEventsTableOrderingComposer,
          $$AnalyticsEventsTableAnnotationComposer,
          $$AnalyticsEventsTableCreateCompanionBuilder,
          $$AnalyticsEventsTableUpdateCompanionBuilder,
          (
            AnalyticsEvent,
            BaseReferences<
              _$AppDatabase,
              $AnalyticsEventsTable,
              AnalyticsEvent
            >,
          ),
          AnalyticsEvent,
          PrefetchHooks Function()
        > {
  $$AnalyticsEventsTableTableManager(
    _$AppDatabase db,
    $AnalyticsEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalyticsEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalyticsEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalyticsEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> eventName = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> screenName = const Value.absent(),
                Value<String?> properties = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
              }) => AnalyticsEventsCompanion(
                id: id,
                eventId: eventId,
                eventType: eventType,
                eventName: eventName,
                userId: userId,
                sessionId: sessionId,
                screenName: screenName,
                properties: properties,
                timestamp: timestamp,
                isSynced: isSynced,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventId,
                required String eventType,
                required String eventName,
                Value<String?> userId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> screenName = const Value.absent(),
                Value<String?> properties = const Value.absent(),
                required int timestamp,
                Value<bool> isSynced = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
              }) => AnalyticsEventsCompanion.insert(
                id: id,
                eventId: eventId,
                eventType: eventType,
                eventName: eventName,
                userId: userId,
                sessionId: sessionId,
                screenName: screenName,
                properties: properties,
                timestamp: timestamp,
                isSynced: isSynced,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalyticsEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnalyticsEventsTable,
      AnalyticsEvent,
      $$AnalyticsEventsTableFilterComposer,
      $$AnalyticsEventsTableOrderingComposer,
      $$AnalyticsEventsTableAnnotationComposer,
      $$AnalyticsEventsTableCreateCompanionBuilder,
      $$AnalyticsEventsTableUpdateCompanionBuilder,
      (
        AnalyticsEvent,
        BaseReferences<_$AppDatabase, $AnalyticsEventsTable, AnalyticsEvent>,
      ),
      AnalyticsEvent,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$RosterTableTableManager get roster =>
      $$RosterTableTableManager(_db, _db.roster);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$RoomSubscriptionsTableTableManager get roomSubscriptions =>
      $$RoomSubscriptionsTableTableManager(_db, _db.roomSubscriptions);
  $$RoomEventsTableTableManager get roomEvents =>
      $$RoomEventsTableTableManager(_db, _db.roomEvents);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$PrekeysTableTableManager get prekeys =>
      $$PrekeysTableTableManager(_db, _db.prekeys);
  $$PendingJobsTableTableManager get pendingJobs =>
      $$PendingJobsTableTableManager(_db, _db.pendingJobs);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$ReadReceiptsTableTableManager get readReceipts =>
      $$ReadReceiptsTableTableManager(_db, _db.readReceipts);
  $$ReportsTableTableManager get reports =>
      $$ReportsTableTableManager(_db, _db.reports);
  $$InviteLinksTableTableManager get inviteLinks =>
      $$InviteLinksTableTableManager(_db, _db.inviteLinks);
  $$InviteLinkJoinsTableTableManager get inviteLinkJoins =>
      $$InviteLinkJoinsTableTableManager(_db, _db.inviteLinkJoins);
  $$UploadChunksTableTableManager get uploadChunks =>
      $$UploadChunksTableTableManager(_db, _db.uploadChunks);
  $$DownloadChunksTableTableManager get downloadChunks =>
      $$DownloadChunksTableTableManager(_db, _db.downloadChunks);
  $$TransferJobsTableTableManager get transferJobs =>
      $$TransferJobsTableTableManager(_db, _db.transferJobs);
  $$CallHistoryTableTableManager get callHistory =>
      $$CallHistoryTableTableManager(_db, _db.callHistory);
  $$AnalyticsEventsTableTableManager get analyticsEvents =>
      $$AnalyticsEventsTableTableManager(_db, _db.analyticsEvents);
}
