package business

import (
	"context"
	"fmt"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/service"
	"github.com/antinvestor/service-chat/apps/default/service/authz"
	"github.com/antinvestor/service-chat/apps/default/service/events"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	"github.com/antinvestor/service-chat/internal"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/data"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type messageBusiness struct {
	eventRepo       repository.RoomEventRepository
	subRepo         repository.RoomSubscriptionRepository
	subscriptionSvc SubscriptionService
	eventsManager   frevents.Manager
	authzMiddleware authz.Middleware

	payloadConverter *models.PayloadConverter
}

// NewMessageBusiness creates a new instance of MessageBusiness.
func NewMessageBusiness(
	evtsManager frevents.Manager,
	eventRepo repository.RoomEventRepository,
	subRepo repository.RoomSubscriptionRepository,
	subscriptionSvc SubscriptionService,
	authzMiddleware authz.Middleware,
) MessageBusiness {
	return &messageBusiness{

		eventsManager:   evtsManager,
		eventRepo:       eventRepo,
		subRepo:         subRepo,
		subscriptionSvc: subscriptionSvc,
		authzMiddleware: authzMiddleware,

		payloadConverter: models.NewPayloadConverter(),
	}
}

//nolint:gocognit,funlen,nonamedreturns // Complex event validation; named return needed for deferred tracing
func (mb *messageBusiness) SendEvents(
	ctx context.Context,
	req *chatv1.SendEventRequest,
	sentBy *commonv1.ContactLink,
) (_ []*chatv1.AckEvent, err error) {
	ctx, span := chattel.MessageTracer.Start(ctx, "SendEvents")
	defer func() { chattel.MessageTracer.End(ctx, span, err) }()

	// Validate request
	if len(req.GetEvent()) == 0 {
		return nil, service.ErrMessageContentRequired
	}

	if validErr := internal.IsValidContactLink(sentBy); validErr != nil {
		return nil, validErr
	}

	requestEvents := req.GetEvent()

	// Pre-allocate response slice to maintain request order
	responses := make([]*chatv1.AckEvent, len(requestEvents))
	validEvents := make([]*models.RoomEvent, 0, len(requestEvents))
	eventToIndex := make(map[string]int, len(requestEvents))

	// Extract unique room IDs for batch access checking
	uniqueRoomIDs := make(map[string]bool)
	for _, reqEvt := range requestEvents {
		if reqEvt.GetRoomId() == "" {
			return nil, service.ErrMessageRoomIDRequired
		}
		uniqueRoomIDs[reqEvt.GetRoomId()] = true
	}

	uniqueRoomIDList := make([]string, 0, len(uniqueRoomIDs))
	for roomID := range uniqueRoomIDs {
		uniqueRoomIDList = append(uniqueRoomIDList, roomID)
	}

	// Batch-lookup subscriptions for all rooms first
	subsByRoomMap, subsErr := mb.subscriptionSvc.GetSubscriptionsForRooms(ctx, sentBy, uniqueRoomIDList)
	if subsErr != nil {
		return nil, fmt.Errorf("failed to get subscriptions: %w", subsErr)
	}

	// Build map[roomID]subscriptionID for batch authz check
	subscriptionsByRoom := make(map[string]string, len(subsByRoomMap))
	subscriptionMap := make(map[string]*models.RoomSubscription, len(subsByRoomMap))
	roomSubscriptionIDMap := make(map[string]string, len(subsByRoomMap))

	for roomID, sub := range subsByRoomMap {
		subscriptionsByRoom[roomID] = sub.GetID()
		subscriptionMap[sub.GetID()] = sub
		roomSubscriptionIDMap[roomID] = sub.GetID()
	}

	// Batch check send permission for all rooms via authz
	allowedRooms, batchErr := mb.authzMiddleware.CanSendMessagesToRooms(ctx, subscriptionsByRoom)
	if batchErr != nil {
		return nil, fmt.Errorf("failed to check room access: %w", batchErr)
	}

	// Build access map from allowed rooms
	subscriptionIDAccessMap := make(map[string]bool, len(allowedRooms))
	for roomID, allowed := range allowedRooms {
		if subID, ok := roomSubscriptionIDMap[roomID]; ok && allowed {
			subscriptionIDAccessMap[subID] = true
		}
	}

	// Phase 1: Validate all events and prepare valid ones for bulk save
	for i, reqEvt := range requestEvents {
		// Assign ID if not provided
		if reqEvt.GetId() == "" {
			reqEvt.Id = util.IDString()
		}

		// Map event ID to its position in the request for ordered responses
		eventToIndex[reqEvt.GetId()] = i

		roomID := reqEvt.GetRoomId()

		subscriptionID, ok := roomSubscriptionIDMap[roomID]
		if !ok {
			responses[i] = &chatv1.AckEvent{
				EventId: []string{reqEvt.GetId()},
				AckAt:   timestamppb.Now(),

				Error: &commonv1.ErrorDetail{
					Code:    int32(connect.CodeInternal),
					Message: fmt.Sprintf("no subscription to room: %v", roomID),
				},
			}
			continue
		}

		// Check if user has access to this room
		hasAccess := subscriptionIDAccessMap[subscriptionID]
		if !hasAccess {
			responses[i] = &chatv1.AckEvent{
				EventId: []string{reqEvt.GetId()},
				AckAt:   timestamppb.Now(),
				Error: &commonv1.ErrorDetail{
					Code:    int32(connect.CodePermissionDenied),
					Message: service.ErrMessageSendDenied.Error(),
				},
			}
			continue
		}

		// Create the message event using PayloadConverter
		content, convertErr := mb.payloadConverter.FromProto(reqEvt.GetPayload())
		if convertErr != nil {
			responses[i] = &chatv1.AckEvent{
				EventId: []string{reqEvt.GetId()},
				AckAt:   timestamppb.Now(),
				Error: &commonv1.ErrorDetail{
					Code:    int32(connect.CodeInternal),
					Message: fmt.Sprintf("failed to convert event: %v", convertErr),
				},
			}
			continue
		}

		// Create the message event
		event := &models.RoomEvent{
			RoomID:    reqEvt.GetRoomId(),
			EventType: int32(reqEvt.GetType()),
			Content:   content,
			SenderID:  subscriptionID,
		}

		if reqEvt.ParentId != nil {
			event.ParentID = reqEvt.GetParentId()
		}

		// Use client-provided ID if available, otherwise generate
		if reqEvt.GetId() != "" {
			event.ID = reqEvt.GetId()
		} else {
			event.GenID(ctx)
		}

		validEvents = append(validEvents, event)
	}

	// Phase 2: Deduplicate and bulk save valid events
	if len(validEvents) == 0 {
		return responses, nil
	}

	// Check for already-existing events (idempotency)
	candidateIDs := make([]string, 0, len(validEvents))
	for _, evt := range validEvents {
		candidateIDs = append(candidateIDs, evt.GetID())
	}

	existsMap, existsErr := mb.eventRepo.ExistsByIDs(ctx, candidateIDs)
	if existsErr != nil {
		util.Log(ctx).WithError(existsErr).Warn("idempotency check failed, proceeding with all events")
		existsMap = nil
	}

	// Filter out already-existing events and ack them as success
	if existsMap != nil {
		var newEvents []*models.RoomEvent
		for _, evt := range validEvents {
			if existsMap[evt.GetID()] {
				// Already exists - return success (idempotent)
				responseIdx := eventToIndex[evt.GetID()]
				responses[responseIdx] = &chatv1.AckEvent{
					EventId: []string{evt.GetID()},
					AckAt:   timestamppb.Now(),
				}
				continue
			}
			newEvents = append(newEvents, evt)
		}
		validEvents = newEvents
	}

	if len(validEvents) == 0 {
		return responses, nil
	}

	// Use CreateIgnoringDuplicates to atomically handle concurrent inserts.
	// Returns which events were actually inserted vs skipped (duplicate from concurrent request).
	insertedIDs, bulkCreateErr := mb.eventRepo.CreateIgnoringDuplicates(ctx, validEvents)
	if bulkCreateErr == nil {
		chattel.MessagesSentCounter.Add(ctx, int64(len(insertedIDs)))
	}

	// Phase 3: Process each valid event - emit to outbox or report errors
	for _, event := range validEvents {
		responseIdx := eventToIndex[event.GetID()]
		responses[responseIdx] = mb.emitOrAckEvent(ctx, event, insertedIDs, bulkCreateErr, subscriptionMap)
	}

	return responses, nil
}

// emitOrAckEvent processes a single event after bulk save: emits to outbox if newly inserted,
// returns success ack for duplicates, or returns error ack on failure.
func (mb *messageBusiness) emitOrAckEvent(
	ctx context.Context,
	event *models.RoomEvent,
	insertedIDs map[string]bool,
	bulkCreateErr error,
	subscriptionMap map[string]*models.RoomSubscription,
) *chatv1.AckEvent {
	if bulkCreateErr != nil {
		return &chatv1.AckEvent{
			EventId: []string{event.GetID()},
			AckAt:   timestamppb.Now(),
			Error: &commonv1.ErrorDetail{
				Code:    int32(connect.CodeInternal),
				Message: fmt.Sprintf("failed to save event: %v", bulkCreateErr),
			},
		}
	}

	// Skip events that were duplicates (already inserted by a concurrent request).
	// The concurrent request will handle emitting to the outbox.
	if !insertedIDs[event.GetID()] {
		return &chatv1.AckEvent{
			EventId: []string{event.GetID()},
			AckAt:   timestamppb.Now(),
		}
	}

	subscription, ok := subscriptionMap[event.SenderID]
	if !ok {
		util.Log(ctx).
			WithField("subscription_id", event.SenderID).
			Error("very unlikely, no such subscription exists")
		return &chatv1.AckEvent{
			EventId: []string{event.GetID()},
			AckAt:   timestamppb.Now(),
			Error: &commonv1.ErrorDetail{
				Code:    int32(connect.CodeInternal),
				Message: "no subscription found for sender",
			},
		}
	}

	// Emit event to outbox for delivery
	outboxEventLink := eventsv1.Link{
		EventId: event.GetID(),
		RoomId:  event.RoomID,
		Source: &eventsv1.Subscription{
			SubscriptionId: subscription.GetID(),
			ContactLink:    subscription.ToLink(),
		},
		ParentId:  event.ParentID,
		EventType: chatv1.RoomEventType(event.EventType),
		CreatedAt: timestamppb.New(event.CreatedAt),
	}

	emitErr := mb.eventsManager.Emit(ctx, events.RoomOutboxLoggingEventName, &outboxEventLink)
	if emitErr != nil {
		// Emit failed - delete the orphaned event so client can retry cleanly
		if delErr := mb.eventRepo.Delete(ctx, event.GetID()); delErr != nil {
			util.Log(ctx).WithError(delErr).
				WithField("event_id", event.GetID()).
				Warn("failed to clean up orphaned event after emit failure")
		}
		return &chatv1.AckEvent{
			EventId: []string{event.GetID()},
			AckAt:   timestamppb.Now(),
			Error: &commonv1.ErrorDetail{
				Code:    int32(connect.CodeInternal),
				Message: fmt.Sprintf("failed to emit event: %v", emitErr),
			},
		}
	}

	return &chatv1.AckEvent{
		EventId: []string{event.GetID()},
		AckAt:   timestamppb.Now(),
	}
}

func (mb *messageBusiness) GetMessage(
	ctx context.Context,
	messageID string,
	gottenBy *commonv1.ContactLink,
) (*models.RoomEvent, error) {
	if messageID == "" {
		return nil, service.ErrUnspecifiedID
	}

	if err := internal.IsValidContactLink(gottenBy); err != nil {
		return nil, err
	}

	// Get the message
	event, err := mb.eventRepo.GetByID(ctx, messageID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil, service.ErrMessageNotFound
		}
		return nil, fmt.Errorf("failed to get message: %w", err)
	}

	// Look up subscription first, then check authz with subscriptionID
	sub, subErr := mb.subscriptionSvc.GetSubscription(ctx, gottenBy, event.RoomID)
	if subErr != nil {
		return nil, service.ErrMessageAccessDenied
	}

	if authzErr := mb.authzMiddleware.CanViewRoom(ctx, sub.GetID(), event.RoomID); authzErr != nil {
		return nil, service.ErrMessageAccessDenied
	}

	return event, nil
}

//nolint:nonamedreturns // named return needed for deferred tracing
func (mb *messageBusiness) GetHistory(
	ctx context.Context,
	req *chatv1.GetHistoryRequest,
	gottenBy *commonv1.ContactLink,
) (_ []*chatv1.RoomEvent, err error) {
	ctx, span := chattel.MessageTracer.Start(ctx, "GetHistory")
	defer func() { chattel.MessageTracer.End(ctx, span, err) }()

	if req.GetRoomId() == "" {
		return nil, service.ErrMessageRoomIDRequired
	}

	if validErr := internal.IsValidContactLink(gottenBy); validErr != nil {
		return nil, validErr
	}

	// Look up subscription first, then check authz with subscriptionID
	sub, subErr := mb.subscriptionSvc.GetSubscription(ctx, gottenBy, req.GetRoomId())
	if subErr != nil {
		return nil, service.ErrRoomAccessDenied
	}

	if authzErr := mb.authzMiddleware.CanViewRoom(ctx, sub.GetID(), req.GetRoomId()); authzErr != nil {
		return nil, service.ErrRoomAccessDenied
	}

	// Build the query - use cursor for pagination
	var limit = 50 // default limit
	var cursor string
	if req.GetCursor() != nil {
		if req.GetCursor().GetLimit() > 0 {
			limit = int(req.GetCursor().GetLimit())
		}
		cursor = req.GetCursor().GetPage()
	}

	// Get messages
	evts, err := mb.eventRepo.GetHistory(ctx, req.GetRoomId(), cursor, "", limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get message history: %w", err)
	}

	// Convert to proto
	protoEvents := make([]*chatv1.RoomEvent, 0, len(evts))
	for _, event := range evts {
		protoEvents = append(protoEvents, event.ToAPI(ctx, mb.payloadConverter))
	}

	// Update last read sequence for the user if we have evts
	// When cursor is empty (first load), events are sorted ASC so last element is newest
	if len(evts) > 0 && cursor == "" {
		_ = mb.MarkMessagesAsRead(ctx, req.GetRoomId(), evts[len(evts)-1].GetID(), gottenBy)
	}

	return protoEvents, nil
}

//nolint:nonamedreturns // named return needed for deferred tracing
func (mb *messageBusiness) DeleteMessage(
	ctx context.Context, messageID string, deletedBy *commonv1.ContactLink,
) (err error) {
	ctx, span := chattel.MessageTracer.Start(ctx, "DeleteMessage")
	defer func() { chattel.MessageTracer.End(ctx, span, err) }()

	if messageID == "" {
		return service.ErrUnspecifiedID
	}

	if validErr := internal.IsValidContactLink(deletedBy); validErr != nil {
		return validErr
	}

	// Get the message
	event, err := mb.eventRepo.GetByID(ctx, messageID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return service.ErrMessageNotFound
		}
		return fmt.Errorf("failed to get message: %w", err)
	}

	// Get the sender's subscription to find their profile ID
	// Note: event.SenderID contains subscription ID, not profile ID
	senderSub, err := mb.subRepo.GetByID(ctx, event.SenderID)
	if err != nil {
		// If we can't find the sender subscription, check admin status only
		util.Log(ctx).WithError(err).WithField("sender_id", event.SenderID).
			Warn("could not find sender subscription for message deletion check")
		senderSub = nil
	}

	// Check if the user is the sender
	var isSender bool
	if senderSub != nil {
		isSender = senderSub.ProfileID == deletedBy.GetProfileId()
	}

	// If user is the sender, allow deletion
	if isSender {
		err = mb.eventRepo.Delete(ctx, event.GetID())
		if err != nil {
			return fmt.Errorf("failed to delete message: %w", err)
		}
		return nil
	}

	// Check if the user is an admin or owner (can delete any message)
	admin, err := mb.subscriptionSvc.HasRole(ctx, deletedBy, event.RoomID, roleAdminLevel)
	if err != nil || admin == nil {
		// User is not sender AND not admin - deny
		return service.ErrMessageDeleteDenied
	}

	// User is admin, allow deletion
	err = mb.eventRepo.Delete(ctx, event.GetID())
	if err != nil {
		return fmt.Errorf("failed to delete message: %w", err)
	}

	return nil
}

func (mb *messageBusiness) MarkMessagesAsRead(
	ctx context.Context,
	roomID string,
	eventID string,
	markedBy *commonv1.ContactLink,
) error {
	if err := internal.IsValidContactLink(markedBy); err != nil {
		return err
	}

	if roomID == "" {
		return service.ErrMessageRoomIDRequired
	}

	// Look up subscription first - reuse for both authz check and subscription update
	subscription, err := mb.subscriptionSvc.GetSubscription(ctx, markedBy, roomID)
	if err != nil {
		return service.ErrRoomAccessDenied
	}

	if authzErr := mb.authzMiddleware.CanViewRoom(ctx, subscription.GetID(), roomID); authzErr != nil {
		return service.ErrRoomAccessDenied
	}

	// Update the last read event ID
	// UnreadCount is now a generated column and will be automatically calculated
	subscription.LastReadEventID = eventID
	subscription.LastReadAt = time.Now().Unix()

	if _, updateErr := mb.subRepo.Update(ctx, subscription); updateErr != nil {
		return fmt.Errorf("failed to update subscription: %w", updateErr)
	}

	return nil
}
