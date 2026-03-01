package authz

import "slices"

// Namespace constants define the object types in the authorization system.
const (
	NamespaceRoom         = "chat_room"
	NamespaceMessage      = "chat_message"
	NamespaceProfile      = "chat_profile"
	NamespaceSubscription = "chat_subscription"

	// NamespaceTenancyAccess is the cross-service data access namespace (Layer 1).
	NamespaceTenancyAccess = "tenancy_access"
	// NamespaceProfileUser is the platform-wide user identity namespace used as
	// subject in tenancy access tuples.
	NamespaceProfileUser = "profile_user"
)

// Relation constants define the relationships between objects and subjects.
// Direct-grant relations are prefixed with "granted_" to avoid name conflicts
// with permit functions. Keto skips permit evaluation when a relation shares
// the same name as a permit function.
const (
	RelationOwner  = "granted_owner"
	RelationAdmin  = "granted_admin"
	RelationMember = "granted_member"
	RelationViewer = "granted_viewer"
	RelationSender = "granted_sender"
	RelationRoom   = "room"
)

// Permission constants define the actions that can be performed on objects.
const (
	PermissionView             = "view"
	PermissionMessageSend      = "message_send"
	PermissionMessageDeleteAny = "message_delete_any"
	PermissionUpdate           = "update"
	PermissionDelete           = "delete"
	PermissionMembersManage    = "members_manage"
	PermissionRolesManage      = "roles_manage"
	PermissionEdit             = "edit"
	PermissionReact            = "react"
)

// Role constants define the member roles in a room.
const (
	RoleOwner  = "owner"
	RoleAdmin  = "admin"
	RoleMember = "member"
	RoleGuest  = "guest"
)

// RoleToRelation converts a role string to a Keto relation.
func RoleToRelation(role string) string {
	switch role {
	case RoleOwner:
		return RelationOwner
	case RoleAdmin:
		return RelationAdmin
	case RoleMember:
		return RelationMember
	case RoleGuest:
		return RelationViewer
	default:
		return RelationMember
	}
}

// RelationToRole converts a Keto relation to a role string.
func RelationToRole(relation string) string {
	switch relation {
	case RelationOwner:
		return RoleOwner
	case RelationAdmin:
		return RoleAdmin
	case RelationMember:
		return RoleMember
	case RelationViewer:
		return RoleGuest
	default:
		return RoleMember
	}
}

// ValidRoles returns a list of valid role strings.
func ValidRoles() []string {
	return []string{RoleOwner, RoleAdmin, RoleMember, RoleGuest}
}

// ValidRelations returns a list of valid relation strings for rooms.
func ValidRelations() []string {
	return []string{RelationOwner, RelationAdmin, RelationMember, RelationViewer}
}

// IsValidRole checks if a role string is valid.
func IsValidRole(role string) bool {
	return slices.Contains(ValidRoles(), role)
}
