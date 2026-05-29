package business

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"buf.build/gen/go/antinvestor/profile/connectrpc/go/profile/v1/profilev1connect"
	profilev1 "buf.build/gen/go/antinvestor/profile/protocolbuffers/go/profile/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/data"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// proposalExpiryHours is the number of hours before a proposal expires.
const proposalExpiryHours = 72
const defaultGroupType = models.RoomTypeGroup
const defaultSearchLimit = 50
const maxSearchLimit = 100

type roomBusiness struct {
	service          *frame.Service
	roomRepo         repository.RoomRepository
	eventRepo        repository.RoomEventRepository
	eventsManager    frevents.Manager
	subscriptionRepo repository.RoomSubscriptionRepository
	proposalRepo     repository.ProposalRepository
	subscriptionSvc  SubscriptionService
	messageBusiness  MessageBusiness
	profileCli       profilev1connect.ProfileServiceClient
	authzMiddleware  authz.Middleware
}

// NewRoomBusiness creates a new instance of RoomBusiness.
func NewRoomBusiness(
	service *frame.Service,
	roomRepo repository.RoomRepository,
	eventRepo repository.RoomEventRepository,
	subRepo repository.RoomSubscriptionRepository,
	proposalRepo repository.ProposalRepository,
	subscriptionSvc SubscriptionService,
	eventsManager frevents.Manager,
	messageBusiness MessageBusiness,
	profileCli profilev1connect.ProfileServiceClient,
	authzMiddleware authz.Middleware,
) RoomBusiness {
	return &roomBusiness{
		service:          service,
		roomRepo:         roomRepo,
		eventRepo:        eventRepo,
		subscriptionRepo: subRepo,
		proposalRepo:     proposalRepo,
		eventsManager:    eventsManager,
		subscriptionSvc:  subscriptionSvc,
		messageBusiness:  messageBusiness,
		profileCli:       profileCli,
		authzMiddleware:  authzMiddleware,
	}
}

// CreateRoom named return required for deferred tracing.
func (rb *roomBusiness) CreateRoom(
	ctx context.Context,
	req *chatv1.CreateRoomRequest,
	createdBy *commonv1.ContactLink,
) (*chatv1.Room, error) {
	var err error
	ctx, span := chattel.RoomTracer.Start(ctx, "CreateRoom")
	defer func() { chattel.RoomTracer.End(ctx, span, err) }()

	err = chatutil.IsValidContactLink(createdBy)
	if err != nil {
		return nil, err
	}

	// Validate request
	if req.GetName() == "" {
		return nil, service.ErrRoomNameRequired
	}

	// Create the room
	createdRoom := &models.Room{
		RoomType:         defaultGroupType,
		Name:             req.GetName(),
		Description:      req.GetDescription(),
		IsPublic:         !req.GetIsPrivate(),
		RequiresApproval: req.GetRequiresApproval(),
	}
	if req.GetId() != "" {
		createdRoom.ID = req.GetId()
	}

	// Save the room
	err = rb.roomRepo.Create(ctx, createdRoom)
	if err != nil {
		if data.ErrorIsDuplicateKey(err) {
			existingRoom, getErr := rb.roomRepo.GetByID(ctx, createdRoom.GetID())
			if getErr != nil {
				return nil, fmt.Errorf("failed to load existing room after duplicate create: %w", getErr)
			}

			return existingRoom.ToAPI(), nil
		}
		return nil, fmt.Errorf("failed to save room: %w", err)
	}

	// Owner subscription
	ownerSubscription := &chatv1.RoomSubscription{
		Id:     util.IDString(),
		RoomId: createdRoom.GetID(),
		Member: &commonv1.ContactLink{
			ProfileId: createdBy.GetProfileId(),
			ContactId: createdBy.GetContactId(),
		},
		Roles: []string{roleOwner},
	}

	subscriptionList := []*chatv1.RoomSubscription{ownerSubscription}
	for _, member := range req.GetMembers() {
		if member != nil {
			subscriptionList = append(subscriptionList, &chatv1.RoomSubscription{
				Id:     util.IDString(),
				RoomId: createdRoom.GetID(),
				Member: member,
			})
		}
	}

	// Add creator as owner
	err = rb.addRoomMembersWithRoles(
		ctx,
		createdRoom.GetID(),
		subscriptionList, ownerSubscription.GetId(),
		createdBy,
	)
	if err != nil {
		partErr, ok := service.IsPartialBatchError(err)
		if !ok || partErr.Succeeded == 0 {
			// Full failure: delete the room (subscriptions are created asynchronously
			// via events, so none exist yet at this point)
			_ = rb.roomRepo.Delete(ctx, createdRoom.GetID())
			return nil, fmt.Errorf("failed to create room: %w", err)
		}

		// Partial failure: some members succeeded (including at least the owner).
		// Return the room with a warning about the failed members.
		util.Log(ctx).WithFields(map[string]any{
			chatutil.KeyRoomID: createdRoom.GetID(),
			"failed":           partErr.Failed,
			"succeeded":        partErr.Succeeded,
		}).Warn("partial failure adding members during room creation")
	}

	util.Log(ctx).WithField(chatutil.KeyRoomID, createdRoom.GetID()).
		Debug("room created")

	chattel.RoomsCreatedCounter.Add(ctx, 1)

	// Return the created room as a proto
	return createdRoom.ToAPI(), nil
}

func (rb *roomBusiness) GetRoom(
	ctx context.Context,
	roomID string,
	searchedBy *commonv1.ContactLink,
) (*chatv1.Room, error) {
	if err := chatutil.IsValidContactLink(searchedBy); err != nil {
		return nil, err
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID:    roomID,
		chatutil.KeyProfileID: searchedBy.GetProfileId(),
	}).Debug("GetRoom request")

	// Look up subscription, then check authz with subscriptionID
	sub, subErr := rb.subscriptionSvc.GetSubscription(ctx, searchedBy, roomID)
	if subErr != nil {
		return nil, service.ErrRoomAccessDenied
	}

	util.Log(ctx).WithField(chatutil.KeySubscriptionID, sub.GetID()).Debug("GetRoom subscription found")

	if err := rb.authzMiddleware.CanRoomView(ctx, sub.GetID(), roomID); err != nil {
		return nil, service.ErrRoomAccessDenied
	}

	room, err := rb.roomRepo.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil, service.ErrRoomNotFound
		}
		return nil, fmt.Errorf("failed to get room: %w", err)
	}

	return room.ToAPI(), nil
}

func (rb *roomBusiness) UpdateRoom(
	ctx context.Context,
	req *chatv1.UpdateRoomRequest,
	updatedBy *commonv1.ContactLink,
) (*chatv1.Room, error) {
	if req.GetRoomId() == "" {
		return nil, service.ErrRoomIDRequired
	}

	if err := chatutil.IsValidContactLink(updatedBy); err != nil {
		return nil, err
	}

	// Check if the user is an admin of the room
	admin, err := rb.subscriptionSvc.HasRole(ctx, updatedBy, req.GetRoomId(), roleAdminLevel)
	if err != nil {
		return nil, fmt.Errorf("failed to check admin status: %w", err)
	}

	if admin == nil {
		return nil, service.ErrRoomUpdateDenied
	}

	// Check if room requires approval for changes
	if needsApproval, approvalErr := rb.requiresApproval(ctx, req.GetRoomId()); approvalErr == nil && needsApproval {
		util.Log(ctx).WithField(chatutil.KeyRoomID, req.GetRoomId()).Debug("UpdateRoom requires approval")
		if crErr := rb.createProposal(ctx, req.GetRoomId(), models.ProposalTypeUpdateRoom,
			updatedBy.GetProfileId(), req); crErr != nil {
			return nil, fmt.Errorf("failed to create proposal: %w", crErr)
		}
		return nil, service.ErrProposalRequired
	}

	// Get the existing room
	room, err := rb.roomRepo.GetByID(ctx, req.GetRoomId())
	if err != nil {
		return nil, fmt.Errorf("failed to get room: %w", err)
	}

	// Update fields if provided
	if req.GetName() != "" {
		room.Name = req.GetName()
	}
	if req.GetDescription() != "" {
		room.Description = req.GetDescription()
	}

	// Save the updated room
	_, err = rb.roomRepo.Update(ctx, room)
	if err != nil {
		return nil, fmt.Errorf("failed to update room: %w", err)
	}

	// Send room updated event
	if err = rb.sendRoomChangeEvent(ctx, req.GetRoomId(), updatedBy,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UPDATED,
		admin.GetID(), "Room details updated"); err != nil {
		util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, req.GetRoomId()).
			Warn("failed to emit room update event")
	}

	return room.ToAPI(), nil
}

//nolint:nonamedreturns // named return required for deferred tracing
func (rb *roomBusiness) DeleteRoom(
	ctx context.Context,
	req *chatv1.DeleteRoomRequest,
	deletedBy *commonv1.ContactLink,
) (err error) {
	ctx, span := chattel.RoomTracer.Start(ctx, "DeleteRoom")
	defer func() { chattel.RoomTracer.End(ctx, span, err) }()

	if req.GetRoomId() == "" {
		return service.ErrRoomIDRequired
	}

	if validErr := chatutil.IsValidContactLink(deletedBy); validErr != nil {
		return validErr
	}

	roomID := req.GetRoomId()

	// Check if the user is an owner of the room
	admin, err := rb.subscriptionSvc.HasRole(ctx, deletedBy, roomID, roleOwnerLevel)
	if err != nil {
		return fmt.Errorf("failed to check admin status: %w", err)
	}

	if admin == nil {
		return service.ErrRoomDeleteDenied
	}

	// Check if room requires approval for changes
	if needsApproval, approvalErr := rb.requiresApproval(ctx, roomID); approvalErr == nil && needsApproval {
		if crErr := rb.createProposal(ctx, roomID, models.ProposalTypeDeleteRoom,
			deletedBy.GetProfileId(), req); crErr != nil {
			return fmt.Errorf("failed to create proposal: %w", crErr)
		}
		return service.ErrProposalRequired
	}

	util.Log(ctx).WithField(chatutil.KeyRoomID, roomID).Debug("DeleteRoom deactivating subscriptions")

	// Deactivate all subscriptions and clean up authz
	if cleanupErr := rb.deactivateAllRoomSubscriptions(ctx, roomID); cleanupErr != nil {
		return cleanupErr
	}

	// Soft delete the room
	if deleteErr := rb.roomRepo.Delete(ctx, roomID); deleteErr != nil {
		return fmt.Errorf("failed to delete room: %w", deleteErr)
	}

	chattel.RoomsDeletedCounter.Add(ctx, 1)

	// Send room deleted event
	if err = rb.sendRoomChangeEvent(ctx, req.GetRoomId(), deletedBy,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_DELETED,
		admin.GetID(), "Room deleted"); err != nil {
		util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, req.GetRoomId()).
			Warn("failed to emit room deleted event")
	}

	return nil
}

func (rb *roomBusiness) SearchRooms(
	ctx context.Context,
	req *chatv1.SearchRoomsRequest,
	searchedBy *commonv1.ContactLink,
) ([]*chatv1.Room, error) {
	if err := chatutil.IsValidContactLink(searchedBy); err != nil {
		return nil, err
	}

	// Get all room IDs the user is subscribed to
	roomIDs, err := rb.subscriptionSvc.GetSubscribedRoomIDs(ctx, searchedBy)
	if err != nil {
		return nil, fmt.Errorf("failed to get user subscriptions: %w", err)
	}

	var resultList []*chatv1.Room

	if len(roomIDs) == 0 {
		return resultList, nil
	}

	// Build the search query
	searchOpts := []data.SearchOption{
		data.WithSearchFiltersAndByValue(
			map[string]any{"id": roomIDs},
		),
	}

	// Only add text search filters when a query is provided
	if query := req.GetQuery(); query != "" {
		likePattern := "%" + query + "%"
		searchOpts = append(searchOpts, data.WithSearchFiltersOrByValue(
			map[string]any{
				"name ILIKE ?":        likePattern,
				"description ILIKE ?": likePattern,
			},
		))
	}

	page := 0
	limit := defaultSearchLimit
	cursor := req.GetCursor()
	if cursor != nil {
		if cursor.GetPage() != "" {
			page, _ = strconv.Atoi(cursor.GetPage())
		}
		if cursor.GetLimit() > 0 {
			limit = int(cursor.GetLimit())
		}
	}
	if limit > maxSearchLimit {
		limit = maxSearchLimit
	}
	searchOpts = append(searchOpts, data.WithSearchOffset(page), data.WithSearchLimit(limit))

	query := data.NewSearchQuery(searchOpts...)

	// Get rooms - need to convert JobResultPipe to slice
	roomsPipe, err := rb.roomRepo.Search(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to search rooms: %w", err)
	}

	for res := range roomsPipe.ResultChan() {
		if res.IsError() {
			return resultList, res.Error()
		}

		resultRoomSlice := res.Item()
		for _, room := range resultRoomSlice {
			resultList = append(resultList, room.ToAPI())
		}
	}

	return resultList, nil
}

func (rb *roomBusiness) AddRoomSubscriptions(
	ctx context.Context,
	req *chatv1.AddRoomSubscriptionsRequest,
	addedBy *commonv1.ContactLink,
) error {
	if req.GetRoomId() == "" {
		return service.ErrRoomIDRequired
	}
	if len(req.GetMembers()) == 0 {
		return service.ErrProfileIDsRequired
	}

	if err := chatutil.IsValidContactLink(addedBy); err != nil {
		return err
	}

	// Check if the user has permission to add members
	admin, err := rb.subscriptionSvc.CanMembersManage(ctx, addedBy, req.GetRoomId())
	if err != nil {
		return fmt.Errorf("failed to check permissions: %w", err)
	}

	if admin == nil {
		return service.ErrRoomAddMembersDenied
	}

	// Check if room requires approval for changes
	if needsApproval, approvalErr := rb.requiresApproval(ctx, req.GetRoomId()); approvalErr == nil && needsApproval {
		if crErr := rb.createProposal(ctx, req.GetRoomId(), models.ProposalTypeAddSubscriptions,
			addedBy.GetProfileId(), req); crErr != nil {
			return fmt.Errorf("failed to create proposal: %w", crErr)
		}
		return service.ErrProposalRequired
	}

	// Extract ContactLinks and roles from members, preserving request order
	subscriptionList := req.GetMembers()
	for _, member := range subscriptionList {
		// Use first roles or default to "member"
		if len(member.GetRoles()) == 0 {
			member.Roles = []string{roleMember}
		}
	}

	// Add members with their respective roles.
	// PartialBatchError is returned when some members were added successfully
	// but others failed validation. Propagate it so the handler can report details.
	err = rb.addRoomMembersWithRoles(ctx, req.GetRoomId(), subscriptionList, admin.GetID(), addedBy)
	if err != nil {
		if _, ok := service.IsPartialBatchError(err); ok {
			return err
		}
		return fmt.Errorf("failed to add members to room: %w", err)
	}

	return nil
}

func (rb *roomBusiness) RemoveRoomSubscriptions(
	ctx context.Context,
	req *chatv1.RemoveRoomSubscriptionsRequest,
	removedBy *commonv1.ContactLink,
) error {
	if req.GetRoomId() == "" {
		return service.ErrRoomIDRequired
	}
	if len(req.GetSubscriptionId()) == 0 {
		return service.ErrProfileIDsRequired
	}

	if err := chatutil.IsValidContactLink(removedBy); err != nil {
		return err
	}

	// Check if the user has permission to remove members
	admin, err := rb.subscriptionSvc.CanMembersManage(ctx, removedBy, req.GetRoomId())
	if err != nil {
		return fmt.Errorf("failed to check permissions: %w", err)
	}

	if admin == nil {
		return service.ErrRoomRemoveMembersDenied
	}

	// Check if room requires approval for changes
	if needsApproval, approvalErr := rb.requiresApproval(ctx, req.GetRoomId()); approvalErr == nil && needsApproval {
		if crErr := rb.createProposal(ctx, req.GetRoomId(), models.ProposalTypeRemoveSubscriptions,
			removedBy.GetProfileId(), req); crErr != nil {
			return fmt.Errorf("failed to create proposal: %w", crErr)
		}
		return service.ErrProposalRequired
	}

	// Remove members from the room by subscription ID
	return rb.removeRoomMembersBySubscriptionID(ctx, req.GetRoomId(), req.GetSubscriptionId(), admin.GetID(), removedBy)
}

func (rb *roomBusiness) UpdateSubscriptionRole(
	ctx context.Context,
	req *chatv1.UpdateSubscriptionRoleRequest,
	actor *commonv1.ContactLink,
) error {
	if req.GetRoomId() == "" {
		return service.ErrRoomIDRequired
	}
	if req.GetSubscriptionId() == "" {
		return service.ErrUnspecifiedID
	}

	if err := chatutil.IsValidContactLink(actor); err != nil {
		return err
	}

	// Reject unknown role strings before any state change. Without this an owner
	// could persist garbage roles that RoleToRelation silently maps to member,
	// diverging the DB role from the Keto relation.
	if err := validateRoles(req.GetRoles()); err != nil {
		return err
	}

	// Check if the updater has permission to update roles
	admin, err := rb.subscriptionSvc.CanRolesManage(ctx, actor, req.GetRoomId())
	if err != nil {
		return fmt.Errorf("failed to check permissions: %w", err)
	}

	if admin == nil {
		return service.ErrRoomUpdateRoleDenied
	}

	// Check if room requires approval for changes
	if needsApproval, approvalErr := rb.requiresApproval(ctx, req.GetRoomId()); approvalErr == nil && needsApproval {
		if crErr := rb.createProposal(ctx, req.GetRoomId(), models.ProposalTypeUpdateSubscriptionRole,
			actor.GetProfileId(), req); crErr != nil {
			return fmt.Errorf("failed to create proposal: %w", crErr)
		}
		return service.ErrProposalRequired
	}

	// Update the member's role by subscription ID
	sub, err := rb.subscriptionRepo.GetByID(ctx, req.GetSubscriptionId())
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return service.ErrRoomMemberNotFound
		}
		return fmt.Errorf("failed to get subscription: %w", err)
	}

	// Verify subscription belongs to the specified room
	if sub.RoomID != req.GetRoomId() {
		return service.ErrRoomMemberNotFound
	}

	// Last-owner guard: refuse to demote the final owner of a room.
	if err = rb.guardOwnerDemotion(ctx, req, sub); err != nil {
		return err
	}

	// Update roles with DB-first semantics so we can compensate cleanly if authz update fails.
	if err = rb.syncRoleUpdate(ctx, req, sub); err != nil {
		return err
	}

	// Send member role updated event
	if err = rb.sendRoomChangeEvent(ctx, req.GetRoomId(), actor,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_ROLE_CHANGED,
		admin.GetID(), "Member(s) role updated",
		req.GetSubscriptionId()); err != nil {
		util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, req.GetRoomId()).
			Warn("failed to emit role update event")
	}

	return nil
}

// syncRoleUpdate updates the DB subscription role first, then syncs the authz tuple.
// If the authz update fails, the DB change is rolled back to preserve consistency.
func (rb *roomBusiness) syncRoleUpdate(
	ctx context.Context,
	req *chatv1.UpdateSubscriptionRoleRequest,
	sub *models.RoomSubscription,
) error {
	oldRole := sub.Role
	var newRole string
	if len(req.GetRoles()) > 0 {
		newRole = strings.Join(req.GetRoles(), ",")
	}

	if newRole != "" {
		sub.Role = newRole
	}

	if _, updateErr := rb.subscriptionRepo.Update(ctx, sub, "role"); updateErr != nil {
		return fmt.Errorf("failed to update member role: %w", updateErr)
	}

	if rb.authzMiddleware != nil && newRole != "" {
		if authzErr := rb.authzMiddleware.UpdateRoomMemberRole(
			ctx, req.GetRoomId(), sub.GetID(), oldRole, req.GetRoles()[0],
		); authzErr != nil {
			sub.Role = oldRole
			if _, rollbackErr := rb.subscriptionRepo.Update(ctx, sub, "role"); rollbackErr != nil {
				util.Log(ctx).WithError(rollbackErr).WithFields(map[string]any{
					chatutil.KeyRoomID:         req.GetRoomId(),
					chatutil.KeySubscriptionID: sub.GetID(),
				}).Error("failed to roll back role change after authz update failure")
				return fmt.Errorf("failed to update authorization tuple for role change: %w", authzErr)
			}

			return fmt.Errorf("failed to update authorization tuple for role change: %w", authzErr)
		}
	}

	return nil
}

// roleListContains reports whether the comma-separated role field contains the
// target role exactly (so "owner" matches in "owner,admin" but not "co-owner").
func roleListContains(roleField, target string) bool {
	for _, r := range strings.Split(roleField, ",") {
		if strings.TrimSpace(r) == target {
			return true
		}
	}
	return false
}

// validateRoles returns ErrInvalidRole if any role string is not recognised.
func validateRoles(roles []string) error {
	for _, r := range roles {
		if !authz.IsValidRole(r) {
			return service.ErrInvalidRole
		}
	}
	return nil
}

// guardOwnerDemotion blocks demoting the last owner of a room: if the
// subscription currently holds the owner role and the requested roles drop it,
// it must not be the only remaining owner.
func (rb *roomBusiness) guardOwnerDemotion(
	ctx context.Context,
	req *chatv1.UpdateSubscriptionRoleRequest,
	sub *models.RoomSubscription,
) error {
	if !roleListContains(sub.Role, roleOwner) {
		return nil
	}
	if roleListContains(strings.Join(req.GetRoles(), ","), roleOwner) {
		return nil
	}
	return rb.guardLastOwner(ctx, req.GetRoomId(), []*models.RoomSubscription{sub})
}

// uniqueStrings returns the distinct values of in, preserving no particular order.
func uniqueStrings(in []string) []string {
	seen := make(map[string]struct{}, len(in))
	out := make([]string, 0, len(in))
	for _, v := range in {
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		out = append(out, v)
	}
	return out
}

// guardLastOwner returns ErrCannotRemoveLastOwner if losing the owner role on
// the supplied active owner subscriptions would leave the room with no owner.
func (rb *roomBusiness) guardLastOwner(
	ctx context.Context,
	roomID string,
	losing []*models.RoomSubscription,
) error {
	losingOwners := 0
	for _, s := range losing {
		if s.SubscriptionState == models.RoomSubscriptionStateActive && roleListContains(s.Role, roleOwner) {
			losingOwners++
		}
	}
	if losingOwners == 0 {
		return nil
	}

	totalOwners, err := rb.subscriptionRepo.CountActiveOwners(ctx, roomID)
	if err != nil {
		return fmt.Errorf("failed to count room owners: %w", err)
	}
	if totalOwners-int64(losingOwners) < 1 {
		return service.ErrCannotRemoveLastOwner
	}
	return nil
}

func (rb *roomBusiness) SearchRoomSubscriptions(
	ctx context.Context,
	req *chatv1.SearchRoomSubscriptionsRequest,
	searchedBy *commonv1.ContactLink,
) ([]*chatv1.RoomSubscription, error) {
	if req.GetRoomId() == "" {
		return nil, service.ErrRoomIDRequired
	}

	if err := chatutil.IsValidContactLink(searchedBy); err != nil {
		return nil, err
	}

	// Look up subscription, then check authz with subscriptionID
	sub, subErr := rb.subscriptionSvc.GetSubscription(ctx, searchedBy, req.GetRoomId())
	if subErr != nil {
		return nil, service.ErrRoomAccessDenied
	}

	if err := rb.authzMiddleware.CanRoomView(ctx, sub.GetID(), req.GetRoomId()); err != nil {
		return nil, service.ErrRoomAccessDenied
	}

	// Get active subscriptions for the room with pagination
	cursor := req.GetCursor()
	switch {
	case cursor == nil:
		cursor = &commonv1.PageCursor{Limit: defaultSearchLimit}
	case cursor.GetLimit() <= 0:
		cursor = &commonv1.PageCursor{Page: cursor.GetPage(), Limit: defaultSearchLimit}
	case cursor.GetLimit() > maxSearchLimit:
		cursor = &commonv1.PageCursor{Page: cursor.GetPage(), Limit: maxSearchLimit}
	}

	subscriptions, err := rb.subscriptionRepo.GetByRoomID(ctx, req.GetRoomId(), cursor)
	if err != nil {
		return nil, fmt.Errorf("failed to get room members: %w", err)
	}

	// Convert to proto
	protoSubs := make([]*chatv1.RoomSubscription, 0, len(subscriptions))
	for _, sub := range subscriptions {
		protoSubs = append(protoSubs, sub.ToAPI())
	}

	return protoSubs, nil
}

func (rb *roomBusiness) GetSubscriptionForContact(
	ctx context.Context,
	roomID string,
	contact *commonv1.ContactLink,
) (*models.RoomSubscription, error) {
	if err := chatutil.IsValidContactLink(contact); err != nil {
		return nil, err
	}

	if roomID == "" {
		return nil, service.ErrRoomIDRequired
	}

	sub, subErr := rb.subscriptionSvc.GetSubscription(ctx, contact, roomID)
	if subErr != nil {
		return nil, service.ErrRoomAccessDenied
	}

	if err := rb.authzMiddleware.CanRoomView(ctx, sub.GetID(), roomID); err != nil {
		return nil, service.ErrRoomAccessDenied
	}

	return sub, nil
}

func (rb *roomBusiness) UpdateSubscriptionSettings(
	ctx context.Context,
	req *chatv1.UpdateSubscriptionSettingsRequest,
	updatedBy *commonv1.ContactLink,
) (*chatv1.SubscriptionSettings, error) {
	if err := chatutil.IsValidContactLink(updatedBy); err != nil {
		return nil, err
	}

	if req.GetRoomId() == "" {
		return nil, service.ErrRoomIDRequired
	}

	// Look up the caller's subscription
	sub, subErr := rb.subscriptionSvc.GetSubscription(ctx, updatedBy, req.GetRoomId())
	if subErr != nil {
		return nil, service.ErrRoomAccessDenied
	}

	if err := rb.authzMiddleware.CanRoomView(ctx, sub.GetID(), req.GetRoomId()); err != nil {
		return nil, service.ErrRoomAccessDenied
	}

	// Apply updates (only non-nil fields)
	var updateFields []string

	if req.NotificationLevel != nil {
		sub.NotificationLevel = int32(req.GetNotificationLevel())
		updateFields = append(updateFields, "notification_level")
	}
	if req.Muted != nil {
		sub.Muted = req.GetMuted()
		updateFields = append(updateFields, "muted")
	}
	if req.Archived != nil {
		sub.Archived = req.GetArchived()
		updateFields = append(updateFields, "archived")
	}
	if req.Pinned != nil {
		sub.Pinned = req.GetPinned()
		updateFields = append(updateFields, "pinned")
	}

	if len(updateFields) == 0 {
		// Nothing to update, return current settings
		return sub.ToSettings(), nil
	}

	if _, updateErr := rb.subscriptionRepo.Update(ctx, sub, updateFields...); updateErr != nil {
		return nil, fmt.Errorf("failed to update subscription settings: %w", updateErr)
	}

	return sub.ToSettings(), nil
}

// Helper function to add members to a room with specific roles.
//
//nolint:gocognit,nestif,funlen // Membership sync is intentionally synchronous and idempotent across repo/authz boundaries.
func (rb *roomBusiness) addRoomMembersWithRoles(ctx context.Context,
	roomID string, subscriptionList []*chatv1.RoomSubscription,
	actorSubscriptionID string, actorLink *commonv1.ContactLink) error {
	// Deduplicate members by profile_id+contact_id to avoid redundant processing
	seen := make(map[string]struct{}, len(subscriptionList))
	dedupList := make([]*chatv1.RoomSubscription, 0, len(subscriptionList))
	for _, subscription := range subscriptionList {
		key := subscription.GetMember().GetProfileId() + "|" + subscription.GetMember().GetContactId()
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		dedupList = append(dedupList, subscription)
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID: roomID,
		"total_members":    len(subscriptionList),
		"dedup_members":    len(dedupList),
	}).Debug("addRoomMembersWithRoles deduplication")

	// Create subscriptions synchronously so the room is usable immediately on success.
	var itemErrors []service.ItemError
	var addedSubscriptionIDs []string
	for idx, subscription := range dedupList {
		if subscription == nil || subscription.GetMember() == nil {
			itemErrors = append(itemErrors, service.ItemError{
				Index:   idx,
				Message: "subscription member must be specified",
			})
			continue
		}

		// Validate Contact and Profile ID via Profile Service
		if validateErr := rb.validateContactProfile(ctx, subscription.GetMember()); validateErr != nil {
			itemErrors = append(itemErrors, service.ItemError{
				Index:   idx,
				ItemID:  subscription.GetMember().GetProfileId(),
				Message: validateErr.Error(),
			})
			continue
		}

		roles := subscription.GetRoles()
		if len(roles) == 0 {
			roles = []string{roleMember}
		}

		subscriptionModel := &models.RoomSubscription{
			RoomID:            roomID,
			ProfileID:         subscription.GetMember().GetProfileId(),
			ContactID:         subscription.GetMember().GetContactId(),
			SubscriptionState: models.RoomSubscriptionStateActive,
			Role:              strings.Join(roles, ","),
		}
		createdSubscription := false
		if subscription.GetId() != "" {
			subscriptionModel.ID = subscription.GetId()
		}

		err := rb.subscriptionRepo.Create(ctx, subscriptionModel)
		if err != nil {
			if !data.ErrorIsDuplicateKey(err) {
				itemErrors = append(itemErrors, service.ItemError{
					Index:   idx,
					ItemID:  subscription.GetMember().GetProfileId(),
					Message: fmt.Sprintf("failed to create subscription: %v", err),
				})
				continue
			}

			existingSubs, lookupErr := rb.subscriptionRepo.GetByRoomIDAndContactLinks(
				ctx, roomID, subscription.GetMember(),
			)
			if lookupErr != nil || len(existingSubs) == 0 {
				itemErrors = append(itemErrors, service.ItemError{
					Index:   idx,
					ItemID:  subscription.GetMember().GetProfileId(),
					Message: fmt.Sprintf("failed to resolve duplicate subscription: %v", err),
				})
				continue
			}

			subscriptionModel = existingSubs[0]
			if !subscriptionModel.IsActive() {
				if activateErr := rb.subscriptionRepo.Activate(ctx, subscriptionModel.GetID()); activateErr != nil {
					itemErrors = append(itemErrors, service.ItemError{
						Index:   idx,
						ItemID:  subscription.GetMember().GetProfileId(),
						Message: fmt.Sprintf("failed to reactivate subscription: %v", activateErr),
					})
					continue
				}
			}
			if subscriptionModel.Role != strings.Join(roles, ",") {
				subscriptionModel.Role = strings.Join(roles, ",")
				if _, updateErr := rb.subscriptionRepo.Update(ctx, subscriptionModel, "role"); updateErr != nil {
					itemErrors = append(itemErrors, service.ItemError{
						Index:   idx,
						ItemID:  subscription.GetMember().GetProfileId(),
						Message: fmt.Sprintf("failed to sync subscription role: %v", updateErr),
					})
					continue
				}
			}
		} else {
			createdSubscription = true
		}

		if rb.authzMiddleware != nil {
			if authzErr := rb.authzMiddleware.AddRoomMember(
				ctx,
				roomID,
				subscriptionModel.GetID(),
				roles[0],
			); authzErr != nil {
				if createdSubscription {
					_ = rb.subscriptionRepo.Deactivate(ctx, subscriptionModel.GetID())
				}
				itemErrors = append(itemErrors, service.ItemError{
					Index:   idx,
					ItemID:  subscription.GetMember().GetProfileId(),
					Message: fmt.Sprintf("failed to authorize subscription: %v", authzErr),
				})
				continue
			}
		}

		addedSubscriptionIDs = append(addedSubscriptionIDs, subscriptionModel.GetID())
		chattel.SubscriptionsAddedCounter.Add(ctx, 1)
	}

	if len(addedSubscriptionIDs) > 0 {
		if err := rb.sendRoomChangeEvent(ctx, roomID, actorLink,
			chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED,
			actorSubscriptionID, "Member(s) added to room",
			addedSubscriptionIDs...); err != nil {
			util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, roomID).
				Warn("failed to emit room member add event")
		}
	}

	if len(itemErrors) > 0 {
		return &service.PartialBatchError{
			Succeeded: len(addedSubscriptionIDs),
			Failed:    len(itemErrors),
			Errors:    itemErrors,
		}
	}

	return nil
}

// validateContactProfile validates contact and profile ID via Profile Service.
func (rb *roomBusiness) validateContactProfile(ctx context.Context, link *commonv1.ContactLink) error {
	if link.GetContactId() == "" || rb.profileCli == nil {
		return nil
	}

	resp, profileErr := rb.profileCli.GetByContact(ctx, connect.NewRequest(&profilev1.GetByContactRequest{
		Contact: link.GetContactId(),
	}))
	if profileErr != nil {
		return fmt.Errorf("contact validation failed for %s: %w", link.GetContactId(), profileErr)
	}

	// The profile as source of truth
	foundProfileID := resp.Msg.GetData().GetId()

	if link.GetProfileId() != "" {
		if link.GetProfileId() != foundProfileID {
			return fmt.Errorf("profile id mismatch for contact %s: expected %s, got %s",
				link.GetContactId(), foundProfileID, link.GetProfileId())
		}
	} else {
		// Populate ProfileID if missing
		link.ProfileId = foundProfileID
	}

	return nil
}

func (rb *roomBusiness) removeRoomMembersBySubscriptionID(
	ctx context.Context,
	roomID string,
	subscriptionIDs []string,
	actorSubscriptionID string,
	actor *commonv1.ContactLink,
) error {
	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID:   roomID,
		"subscription_count": len(subscriptionIDs),
	}).Debug("removeRoomMembersBySubscriptionID")

	// Validate that every supplied subscription ID actually belongs to this
	// room. Without this check, an admin of room A could pass subscription IDs
	// from room B and have them deactivated (cross-room IDOR).
	subs, err := rb.subscriptionRepo.GetByIDsInRoom(ctx, roomID, subscriptionIDs)
	if err != nil {
		return fmt.Errorf("failed to load subscriptions for removal: %w", err)
	}
	if len(subs) != len(uniqueStrings(subscriptionIDs)) {
		// At least one ID does not belong to this room.
		return service.ErrRoomMemberNotFound
	}

	// Last-owner guard: refuse to remove the final owner(s), which would orphan
	// the room (no one could ever delete or manage it again).
	if err = rb.guardLastOwner(ctx, roomID, subs); err != nil {
		return err
	}

	// Deactivate subscriptions, scoped to this room so a stray ID can never
	// affect another room even if validation above is bypassed in future.
	if _, err = rb.subscriptionRepo.DeactivateInRoom(ctx, roomID, subscriptionIDs); err != nil {
		return fmt.Errorf("failed to deactivate subscription: %w", err)
	}

	// Sync authorization tuples - remove from Keto using subscription IDs
	if rb.authzMiddleware != nil {
		var authzErrors []error
		for _, subID := range subscriptionIDs {
			if authzErr := rb.authzMiddleware.RemoveRoomMember(ctx, roomID, subID); authzErr != nil {
				util.Log(ctx).WithError(authzErr).WithFields(map[string]any{
					chatutil.KeyRoomID:         roomID,
					chatutil.KeySubscriptionID: subID,
				}).Warn("failed to remove authorization tuple for removed room member")
				authzErrors = append(authzErrors, authzErr)
			}
		}
		if len(authzErrors) > 0 {
			return fmt.Errorf("failed to remove authorization tuples for %d member(s): %w",
				len(authzErrors), errors.Join(authzErrors...))
		}
	}

	// Send member removed event
	_ = rb.sendRoomChangeEvent(ctx, roomID, actor,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED,
		actorSubscriptionID, "Member(s) removed from room",
		subscriptionIDs...)

	return nil
}

// deactivateAllRoomSubscriptions deactivates all subscriptions for a room and removes authz tuples.
func (rb *roomBusiness) deactivateAllRoomSubscriptions(ctx context.Context, roomID string) error {
	allSubs, subErr := rb.subscriptionRepo.GetAllByRoomID(ctx, roomID, nil)
	if subErr != nil {
		return fmt.Errorf("failed to get room subscriptions for cleanup: %w", subErr)
	}

	if len(allSubs) == 0 {
		return nil
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID:   roomID,
		"subscription_count": len(allSubs),
	}).Debug("deactivateAllRoomSubscriptions")

	subIDs := make([]string, 0, len(allSubs))
	for _, sub := range allSubs {
		subIDs = append(subIDs, sub.GetID())
	}
	if deactivateErr := rb.subscriptionRepo.Deactivate(ctx, subIDs...); deactivateErr != nil {
		return fmt.Errorf("failed to deactivate room subscriptions: %w", deactivateErr)
	}

	if rb.authzMiddleware != nil {
		var authzErrors []error
		for _, sub := range allSubs {
			if authzErr := rb.authzMiddleware.RemoveRoomMember(ctx, roomID, sub.GetID()); authzErr != nil {
				util.Log(ctx).WithError(authzErr).WithFields(map[string]any{
					chatutil.KeyRoomID:         roomID,
					chatutil.KeySubscriptionID: sub.GetID(),
				}).Warn("failed to remove authorization tuple during room deletion")
				authzErrors = append(authzErrors, authzErr)
			}
		}
		if len(authzErrors) > 0 {
			return fmt.Errorf("failed to remove authorization tuples for %d member(s) during room deletion: %w",
				len(authzErrors), errors.Join(authzErrors...))
		}
	}

	return nil
}

// sendRoomChangeEvent emits a RoomChangeContent event for room lifecycle changes.
func (rb *roomBusiness) sendRoomChangeEvent(
	ctx context.Context,
	roomID string,
	senderContact *commonv1.ContactLink,
	action chatv1.RoomChangeAction,
	actorSubscriptionID string,
	body string,
	targetSubscriptionIDs ...string,
) error {
	req := &chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{
			{
				RoomId: roomID,
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM,
				Payload: &chatv1.Payload{
					Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
					Data: &chatv1.Payload_RoomChange{
						RoomChange: &chatv1.RoomChangeContent{
							Action:                action,
							ActorSubscriptionId:   actorSubscriptionID,
							TargetSubscriptionIds: targetSubscriptionIDs,
							Body:                  body,
						},
					},
				},
			},
		},
	}

	_, err := rb.messageBusiness.SendEvents(ctx, req, senderContact)
	return err
}

// requiresApproval checks if a room has the approval flag set.
// Returns false if the context indicates a pre-approved change.
func (rb *roomBusiness) requiresApproval(ctx context.Context, roomID string) (bool, error) {
	if isApprovedChange(ctx) {
		return false, nil
	}

	room, err := rb.roomRepo.GetByID(ctx, roomID)
	if err != nil {
		return false, fmt.Errorf("failed to get room: %w", err)
	}
	return room.RequiresApproval, nil
}

// createProposal creates a pending proposal for a room operation that requires approval.
func (rb *roomBusiness) createProposal(
	ctx context.Context,
	roomID string,
	proposalType models.ProposalType,
	requestedBy string,
	payload any,
) error {
	if rb.proposalRepo == nil {
		return errors.New("proposal repository not configured; cannot create approval requests")
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal proposal payload: %w", err)
	}

	var payloadMap data.JSONMap
	if err = json.Unmarshal(payloadBytes, &payloadMap); err != nil {
		return fmt.Errorf("failed to convert payload to map: %w", err)
	}

	proposal := &models.Proposal{
		ScopeType:    models.ProposalScopeRoom,
		ScopeID:      roomID,
		ProposalType: proposalType,
		RequestedBy:  requestedBy,
		Payload:      payloadMap,
		State:        models.ProposalStatePending,
		ExpiresAt:    time.Now().Add(proposalExpiryHours * time.Hour),
	}
	proposal.GenID(ctx)

	if createErr := rb.proposalRepo.Create(ctx, proposal); createErr != nil {
		return fmt.Errorf("failed to create proposal: %w", createErr)
	}

	return nil
}
