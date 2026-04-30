package authz_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/stawilabs/chat/apps/default/service/authz"
)

func TestRoleToRelation(t *testing.T) {
	tests := []struct {
		role     string
		expected string
	}{
		{authz.RoleOwner, authz.RelationOwner},
		{authz.RoleAdmin, authz.RelationAdmin},
		{authz.RoleMember, authz.RelationMember},
		{authz.RoleGuest, authz.RelationViewer},
		{"unknown", authz.RelationMember}, // Default to member
		{"", authz.RelationMember},        // Empty defaults to member
	}

	for _, tt := range tests {
		t.Run(tt.role, func(t *testing.T) {
			result := authz.RoleToRelation(tt.role)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestRelationToRole(t *testing.T) {
	tests := []struct {
		relation string
		expected string
	}{
		{authz.RelationOwner, authz.RoleOwner},
		{authz.RelationAdmin, authz.RoleAdmin},
		{authz.RelationMember, authz.RoleMember},
		{authz.RelationViewer, authz.RoleGuest},
		{"unknown", authz.RoleMember}, // Default to member
		{"", authz.RoleMember},        // Empty defaults to member
	}

	for _, tt := range tests {
		t.Run(tt.relation, func(t *testing.T) {
			result := authz.RelationToRole(tt.relation)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestValidRoles(t *testing.T) {
	roles := authz.ValidRoles()
	assert.ElementsMatch(t, []string{authz.RoleOwner, authz.RoleAdmin, authz.RoleMember, authz.RoleGuest}, roles)
}

func TestValidRelations(t *testing.T) {
	relations := authz.ValidRelations()
	assert.ElementsMatch(t,
		[]string{authz.RelationOwner, authz.RelationAdmin, authz.RelationMember, authz.RelationViewer},
		relations)
}

func TestIsValidRole(t *testing.T) {
	tests := []struct {
		role     string
		expected bool
	}{
		{authz.RoleOwner, true},
		{authz.RoleAdmin, true},
		{authz.RoleMember, true},
		{authz.RoleGuest, true},
		{"invalid", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(tt.role, func(t *testing.T) {
			assert.Equal(t, tt.expected, authz.IsValidRole(tt.role))
		})
	}
}

func TestConstants(t *testing.T) {
	testCases := []struct {
		name     string
		actual   string
		expected string
	}{
		{"NamespaceRoom", authz.NamespaceRoom, "chat_room"},
		{"NamespaceMessage", authz.NamespaceMessage, "chat_message"},
		{"NamespaceProfile", authz.NamespaceProfile, "chat_profile"},
		{"NamespaceSubscription", authz.NamespaceSubscription, "chat_subscription"},
		{"RelationOwner", authz.RelationOwner, "granted_owner"},
		{"RelationAdmin", authz.RelationAdmin, "granted_admin"},
		{"RelationMember", authz.RelationMember, "granted_member"},
		{"RelationViewer", authz.RelationViewer, "granted_viewer"},
		{"RelationSender", authz.RelationSender, "granted_sender"},
		{"RelationRoom", authz.RelationRoom, "room"},
		{"PermissionView", authz.PermissionView, "view"},
		{"PermissionMessageSend", authz.PermissionMessageSend, "message_send"},
		{"PermissionMessageDeleteAny", authz.PermissionMessageDeleteAny, "message_delete_any"},
		{"PermissionUpdate", authz.PermissionUpdate, "update"},
		{"PermissionDelete", authz.PermissionDelete, "delete"},
		{"PermissionMembersManage", authz.PermissionMembersManage, "members_manage"},
		{"PermissionRolesManage", authz.PermissionRolesManage, "roles_manage"},
		{"PermissionEdit", authz.PermissionEdit, "edit"},
		{"PermissionReact", authz.PermissionReact, "react"},
		{"RoleOwner", authz.RoleOwner, "owner"},
		{"RoleAdmin", authz.RoleAdmin, "admin"},
		{"RoleMember", authz.RoleMember, "member"},
		{"RoleGuest", authz.RoleGuest, "guest"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			assert.Equal(t, tc.expected, tc.actual)
		})
	}
}
