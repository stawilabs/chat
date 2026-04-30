package business

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strconv"
	"strings"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
)

const (
	defaultDirectCallMemberLimit = 2
	defaultMeshCallMemberLimit   = 6
	defaultMaxVideoPublishers    = 5

	callSignalKindGroupStart       = "group_start"
	callSignalKindGroupJoin        = "group_join"
	callSignalKindGroupLeave       = "group_leave"
	callSignalKindGroupEnd         = "group_end"
	callSignalKindGroupOffer       = "group_offer"
	callSignalKindGroupAnswer      = "group_answer"
	callSignalKindGroupICE         = "group_ice"
	callSignalKindGroupMuteUpdate  = "group_mute_update"
	callSignalKindGroupStageUpdate = "group_stage_update"

	callTopologyP2P  = "p2p"
	callTopologyMesh = "mesh"
	callTopologySFU  = "sfu"

	callMetadataKeySignalKind              = "signalKind"
	callMetadataKeyTopology                = "topology"
	callMetadataKeySFUNodeID               = "sfuNodeId"
	callMetadataKeyInitiatorSubscriptionID = "initiatorSubscriptionId"
	callMetadataKeySenderSubscriptionID    = "senderSubscriptionId"
	callMetadataKeyCallType                = "callType"
	callMetadataKeyHostProfileID           = "hostProfileId"
	callMetadataKeyActiveParticipantIDs    = "activeParticipantProfileIds"
	callMetadataKeyActiveVideoProfileIDs   = "activeVideoProfileIds"
	callMetadataKeyMaxVideoPublishers      = "maxVideoPublishers"
)

var errCallNotFound = errors.New("call not found")

type CallPolicyConfig struct {
	DirectCallMemberLimit int
	MeshCallMemberLimit   int
	MaxVideoPublishers    int
}

func DefaultCallPolicyConfig() CallPolicyConfig {
	return CallPolicyConfig{
		DirectCallMemberLimit: defaultDirectCallMemberLimit,
		MeshCallMemberLimit:   defaultMeshCallMemberLimit,
		MaxVideoPublishers:    defaultMaxVideoPublishers,
	}
}

type callPolicy struct {
	callRepo repository.RoomCallRepository
	subRepo  repository.RoomSubscriptionRepository
	cfg      CallPolicyConfig
}

func newCallPolicy(
	callRepo repository.RoomCallRepository,
	subRepo repository.RoomSubscriptionRepository,
	cfg CallPolicyConfig,
) *callPolicy {
	if callRepo == nil || subRepo == nil {
		return nil
	}

	if cfg.DirectCallMemberLimit <= 0 || cfg.MeshCallMemberLimit <= 0 || cfg.MaxVideoPublishers <= 0 {
		cfg = DefaultCallPolicyConfig()
	}

	return &callPolicy{
		callRepo: callRepo,
		subRepo:  subRepo,
		cfg:      cfg,
	}
}

func (cp *callPolicy) ValidateEvent(
	ctx context.Context,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
) error {
	if cp == nil {
		return nil
	}

	return cp.validateCall(ctx, roomID, senderSubscriptionID, call)
}

func (cp *callPolicy) RecordPersistedEvent(
	ctx context.Context,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
) error {
	if cp == nil {
		return nil
	}
	if err := cp.validateCall(ctx, roomID, senderSubscriptionID, call); err != nil {
		return err
	}

	logger := util.Log(ctx).WithFields(map[string]any{
		"room_id":         roomID,
		"call_id":         call.GetCallId(),
		"action":          call.GetAction().String(),
		"signal_kind":     cp.signalKind(call),
		"sender_sub_id":   senderSubscriptionID,
		"call_topology":   cp.topology(call),
		"call_sfu_nodeid": cp.sfuNodeID(call),
	})

	signalKind := cp.signalKind(call)
	switch {
	case signalKind == callSignalKindGroupStart || call.GetAction() == chatv1.CallContent_CALL_ACTION_OFFER:
		return cp.handleCallOffer(ctx, logger, roomID, senderSubscriptionID, call, signalKind)
	case call.GetAction() == chatv1.CallContent_CALL_ACTION_ANSWER:
		return cp.handleCallAnswer(ctx, logger, roomID, call)
	case cp.isControlSignal(call, signalKind):
		return cp.handleCallControl(ctx, logger, roomID, senderSubscriptionID, call)
	case call.GetAction() == chatv1.CallContent_CALL_ACTION_END || signalKind == callSignalKindGroupEnd:
		return cp.handleCallEnd(ctx, logger, roomID, call)
	default:
		return nil
	}
}

func (cp *callPolicy) validateCall(
	ctx context.Context,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
) error {
	if call == nil {
		return connect.NewError(connect.CodeInvalidArgument, errors.New("call events require call payload"))
	}
	if roomID == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New("call events require room id"))
	}
	if call.GetCallId() == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New("call events require call_id"))
	}

	signalKind := cp.signalKind(call)
	topology := cp.topology(call)

	if err := cp.validateCallPayload(call); err != nil {
		return err
	}

	if signalKind == "" && call.GetAction() == chatv1.CallContent_CALL_ACTION_UNSPECIFIED {
		return connect.NewError(connect.CodeInvalidArgument, errors.New("call event missing action"))
	}

	if signalKind == callSignalKindGroupStageUpdate {
		if senderSubscriptionID == "" {
			return connect.NewError(
				connect.CodePermissionDenied,
				errors.New("group stage updates require a room subscription"),
			)
		}
		return cp.validateStageUpdate(ctx, roomID, senderSubscriptionID, call)
	}

	if err := cp.validateTopology(topology, call); err != nil {
		return err
	}

	return cp.validateParticipantCapacity(ctx, roomID, signalKind, topology)
}

func (cp *callPolicy) getOrCreateCall(
	ctx context.Context,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
	initialStatus string,
) error {
	callRecord, err := cp.findCall(ctx, roomID, call.GetCallId())
	if err != nil {
		if !errors.Is(err, errCallNotFound) {
			return err
		}
		callRecord = nil
	}
	if callRecord != nil {
		if callRecord.Status == repository.CallStatusEnded {
			return connect.NewError(
				connect.CodeFailedPrecondition,
				errors.New("call already ended"),
			)
		}
		if err = cp.updateSFUNode(ctx, callRecord, call); err != nil {
			return err
		}
		return nil
	}

	activeCall, err := cp.callRepo.GetActiveCallByRoomID(ctx, roomID)
	if err != nil && !data.ErrorIsNoRows(err) {
		return fmt.Errorf("failed to load active room call: %w", err)
	}
	if activeCall != nil && activeCall.GetID() != "" && activeCall.CallID != call.GetCallId() {
		return connect.NewError(
			connect.CodeFailedPrecondition,
			errors.New("room already has an active call"),
		)
	}

	record := &models.RoomCall{
		RoomID:    roomID,
		CallID:    call.GetCallId(),
		Status:    initialStatus,
		StartedAt: time.Now(),
		Metadata: data.JSONMap{
			callMetadataKeySignalKind:              cp.signalKind(call),
			callMetadataKeyTopology:                cp.topology(call),
			callMetadataKeySFUNodeID:               cp.sfuNodeID(call),
			callMetadataKeyInitiatorSubscriptionID: senderSubscriptionID,
			callMetadataKeySenderSubscriptionID:    senderSubscriptionID,
			callMetadataKeyCallType:                call.GetType().String(),
		},
	}
	record.GenID(ctx)
	if sfuNodeID := cp.sfuNodeID(call); sfuNodeID != "" {
		record.SFUNodeID = sfuNodeID
	}
	if err = cp.updateCallMetadata(ctx, record, senderSubscriptionID, call); err != nil {
		return err
	}

	if err = cp.callRepo.Create(ctx, record); err != nil {
		return fmt.Errorf("failed to create room call: %w", err)
	}

	return nil
}

func (cp *callPolicy) requireCall(
	ctx context.Context,
	roomID string,
	callID string,
) (*models.RoomCall, error) {
	callRecord, err := cp.findCall(ctx, roomID, callID)
	if err != nil {
		return nil, err
	}
	if callRecord == nil {
		return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("call does not exist"))
	}
	if callRecord.Status == repository.CallStatusEnded {
		return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("call already ended"))
	}
	return callRecord, nil
}

func (cp *callPolicy) findCall(
	ctx context.Context,
	roomID string,
	callID string,
) (*models.RoomCall, error) {
	callRecord, err := cp.callRepo.GetByCallID(ctx, callID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil, errCallNotFound
		}
		return nil, fmt.Errorf("failed to load call by id: %w", err)
	}
	if callRecord.RoomID != roomID {
		return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("call does not belong to room"))
	}
	return callRecord, nil
}

func (cp *callPolicy) updateSFUNode(
	ctx context.Context,
	callRecord *models.RoomCall,
	call *chatv1.CallContent,
) error {
	sfuNodeID := cp.sfuNodeID(call)
	if sfuNodeID == "" || callRecord.SFUNodeID == sfuNodeID {
		return nil
	}
	if err := cp.callRepo.UpdateSFUNode(ctx, callRecord.GetID(), sfuNodeID); err != nil {
		return fmt.Errorf("failed to update call sfu node: %w", err)
	}
	return nil
}

func (cp *callPolicy) validateStageUpdate(
	ctx context.Context,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
) error {
	callRecord, err := cp.requireCall(ctx, roomID, call.GetCallId())
	if err != nil {
		return err
	}

	senderSubscription, err := cp.subRepo.GetByID(ctx, senderSubscriptionID)
	if err != nil {
		return fmt.Errorf("failed to load sender subscription for stage update: %w", err)
	}
	if senderSubscription == nil || senderSubscription.GetID() == "" {
		return connect.NewError(connect.CodePermissionDenied, errors.New("sender subscription not found"))
	}
	if !cp.canManageVideoStage(callRecord, senderSubscription) {
		return connect.NewError(
			connect.CodePermissionDenied,
			errors.New("only the call initiator or room admins can update the video stage"),
		)
	}

	activeVideoProfileIDs := normalizeStringList(
		metadataStringSlice(call.GetMetadata(), callMetadataKeyActiveVideoProfileIDs),
	)
	if len(activeVideoProfileIDs) > cp.cfg.MaxVideoPublishers {
		return connect.NewError(
			connect.CodeFailedPrecondition,
			fmt.Errorf("video stage exceeds supported publisher limit (%d)", cp.cfg.MaxVideoPublishers),
		)
	}

	requestedMax := metadataInt(call.GetMetadata(), callMetadataKeyMaxVideoPublishers)
	if requestedMax > cp.cfg.MaxVideoPublishers {
		return connect.NewError(
			connect.CodeFailedPrecondition,
			fmt.Errorf("video stage limit cannot exceed %d", cp.cfg.MaxVideoPublishers),
		)
	}

	activeParticipantProfileIDs, err := cp.activeCallParticipantProfileIDs(ctx, roomID, callRecord)
	if err != nil {
		return err
	}
	for _, profileID := range activeVideoProfileIDs {
		if !slices.Contains(activeParticipantProfileIDs, profileID) {
			return connect.NewError(
				connect.CodeFailedPrecondition,
				fmt.Errorf("video stage profile %s is not an active call participant", profileID),
			)
		}
	}

	return nil
}

func (cp *callPolicy) canManageVideoStage(
	callRecord *models.RoomCall,
	senderSubscription *models.RoomSubscription,
) bool {
	if callRecord == nil || senderSubscription == nil {
		return false
	}
	if senderSubscription.GetID() == jsonMapString(callRecord.Metadata, callMetadataKeyInitiatorSubscriptionID) {
		return true
	}
	for _, role := range strings.Split(strings.ToLower(senderSubscription.Role), ",") {
		switch strings.TrimSpace(role) {
		case repository.RoleOwner, repository.RoleAdmin:
			return true
		}
	}
	return false
}

func (cp *callPolicy) activeCallParticipantProfileIDs(
	ctx context.Context,
	roomID string,
	callRecord *models.RoomCall,
) ([]string, error) {
	activeParticipantProfileIDs := jsonMapStringSlice(callRecord.Metadata, callMetadataKeyActiveParticipantIDs)
	if len(activeParticipantProfileIDs) > 0 {
		return activeParticipantProfileIDs, nil
	}

	subscriptions, err := cp.subRepo.GetByRoomID(ctx, roomID, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to load active room subscriptions: %w", err)
	}
	profileIDs := make([]string, 0, len(subscriptions))
	for _, subscription := range subscriptions {
		if subscription.ProfileID == "" {
			continue
		}
		profileIDs = append(profileIDs, subscription.ProfileID)
	}
	return normalizeStringList(profileIDs), nil
}

func (cp *callPolicy) updateCallMetadata(
	ctx context.Context,
	callRecord *models.RoomCall,
	senderSubscriptionID string,
	call *chatv1.CallContent,
) error {
	if callRecord == nil {
		return nil
	}
	if callRecord.Metadata == nil {
		callRecord.Metadata = data.JSONMap{}
	}
	if senderSubscriptionID != "" {
		callRecord.Metadata[callMetadataKeySenderSubscriptionID] = senderSubscriptionID
		if callRecord.Metadata[callMetadataKeyInitiatorSubscriptionID] == nil {
			callRecord.Metadata[callMetadataKeyInitiatorSubscriptionID] = senderSubscriptionID
		}
	}
	if signalKind := cp.signalKind(call); signalKind != "" {
		callRecord.Metadata[callMetadataKeySignalKind] = signalKind
	}
	if topology := cp.topology(call); topology != "" {
		callRecord.Metadata[callMetadataKeyTopology] = topology
	}
	if sfuNodeID := cp.sfuNodeID(call); sfuNodeID != "" {
		callRecord.Metadata[callMetadataKeySFUNodeID] = sfuNodeID
	}
	callRecord.Metadata[callMetadataKeyCallType] = call.GetType().String()
	callRecord.Metadata[callMetadataKeyMaxVideoPublishers] = cp.cfg.MaxVideoPublishers

	senderSubscription, err := cp.loadSubscription(ctx, senderSubscriptionID)
	if err != nil {
		return err
	}

	if err = cp.applySignalMetadata(callRecord, senderSubscription, call); err != nil {
		return err
	}

	if callRecord.CreatedAt.IsZero() {
		return nil
	}
	if _, err = cp.callRepo.Update(ctx, callRecord, "metadata"); err != nil {
		return fmt.Errorf("failed to update call metadata: %w", err)
	}
	return nil
}

func (cp *callPolicy) loadSubscription(
	ctx context.Context,
	subscriptionID string,
) (*models.RoomSubscription, error) {
	if subscriptionID == "" {
		return &models.RoomSubscription{}, nil
	}
	subscription, err := cp.subRepo.GetByID(ctx, subscriptionID)
	if err != nil {
		return nil, fmt.Errorf("failed to load subscription: %w", err)
	}
	return subscription, nil
}

func removeString(values []string, target string) []string {
	filtered := make([]string, 0, len(values))
	for _, value := range values {
		if value == target {
			continue
		}
		filtered = append(filtered, value)
	}
	return normalizeStringList(filtered)
}

func (cp *callPolicy) signalKind(call *chatv1.CallContent) string {
	return metadataString(call.GetMetadata(), "signalKind")
}

func (cp *callPolicy) topology(call *chatv1.CallContent) string {
	topology := metadataString(call.GetMetadata(), "topology")
	if topology != "" {
		return topology
	}
	if cp.isGroupSignal(cp.signalKind(call)) {
		return callTopologyMesh
	}
	return callTopologyP2P
}

func (cp *callPolicy) sfuNodeID(call *chatv1.CallContent) string {
	return metadataString(call.GetMetadata(), "sfuNodeId")
}

func (cp *callPolicy) isGroupSignal(signalKind string) bool {
	switch signalKind {
	case callSignalKindGroupStart,
		callSignalKindGroupJoin,
		callSignalKindGroupLeave,
		callSignalKindGroupEnd,
		callSignalKindGroupOffer,
		callSignalKindGroupAnswer,
		callSignalKindGroupICE,
		callSignalKindGroupMuteUpdate,
		callSignalKindGroupStageUpdate:
		return true
	default:
		return false
	}
}

func metadataString(meta *structpb.Struct, key string) string {
	if meta == nil {
		return ""
	}
	value, ok := meta.GetFields()[key]
	if !ok {
		return ""
	}
	return value.GetStringValue()
}

func metadataStringSlice(meta *structpb.Struct, key string) []string {
	if meta == nil {
		return nil
	}
	value, ok := meta.GetFields()[key]
	if !ok {
		return nil
	}
	listValue := value.GetListValue()
	if listValue == nil {
		return nil
	}
	values := listValue.GetValues()
	result := make([]string, 0, len(values))
	for _, item := range values {
		str := strings.TrimSpace(item.GetStringValue())
		if str == "" || slices.Contains(result, str) {
			continue
		}
		result = append(result, str)
	}
	return result
}

func metadataInt(meta *structpb.Struct, key string) int {
	if meta == nil {
		return 0
	}
	value, ok := meta.GetFields()[key]
	if !ok {
		return 0
	}
	switch kind := value.GetKind().(type) {
	case *structpb.Value_NumberValue:
		return int(kind.NumberValue)
	case *structpb.Value_StringValue:
		parsed, err := strconv.Atoi(kind.StringValue)
		if err != nil {
			return 0
		}
		return parsed
	default:
		return 0
	}
}

func jsonMapString(meta data.JSONMap, key string) string {
	if meta == nil {
		return ""
	}
	value, ok := meta[key]
	if !ok {
		return ""
	}
	str, _ := value.(string)
	return str
}

func jsonMapStringSlice(meta data.JSONMap, key string) []string {
	if meta == nil {
		return nil
	}
	raw, ok := meta[key]
	if !ok {
		return nil
	}
	switch typed := raw.(type) {
	case []string:
		return normalizeStringList(typed)
	case []any:
		result := make([]string, 0, len(typed))
		for _, item := range typed {
			str, _ := item.(string)
			str = strings.TrimSpace(str)
			if str == "" || slices.Contains(result, str) {
				continue
			}
			result = append(result, str)
		}
		return result
	default:
		return nil
	}
}

func normalizeStringList(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" || slices.Contains(result, value) {
			continue
		}
		result = append(result, value)
	}
	return result
}

func (cp *callPolicy) handleCallOffer(
	ctx context.Context,
	logger *util.LogEntry,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
	signalKind string,
) error {
	if err := cp.getOrCreateCall(ctx, roomID, senderSubscriptionID, call, repository.CallStatusRinging); err != nil {
		return err
	}
	if signalKind == callSignalKindGroupStart {
		logger.Debug("registered group call start")
		return nil
	}
	logger.Debug("registered call offer")
	return nil
}

func (cp *callPolicy) handleCallAnswer(
	ctx context.Context,
	logger *util.LogEntry,
	roomID string,
	call *chatv1.CallContent,
) error {
	callRecord, err := cp.requireCall(ctx, roomID, call.GetCallId())
	if err != nil {
		return err
	}
	if callRecord.Status != repository.CallStatusActive {
		if err = cp.callRepo.UpdateStatus(ctx, callRecord.GetID(), repository.CallStatusActive); err != nil {
			return fmt.Errorf("failed to mark call active: %w", err)
		}
	}
	if err = cp.updateSFUNode(ctx, callRecord, call); err != nil {
		return err
	}
	logger.Debug("marked call active")
	return nil
}

func (cp *callPolicy) handleCallControl(
	ctx context.Context,
	logger *util.LogEntry,
	roomID string,
	senderSubscriptionID string,
	call *chatv1.CallContent,
) error {
	callRecord, err := cp.requireCall(ctx, roomID, call.GetCallId())
	if err != nil {
		return err
	}
	if err = cp.updateCallMetadata(ctx, callRecord, senderSubscriptionID, call); err != nil {
		return err
	}
	if err = cp.updateSFUNode(ctx, callRecord, call); err != nil {
		return err
	}
	logger.Debug("validated active call control event")
	return nil
}

func (cp *callPolicy) handleCallEnd(
	ctx context.Context,
	logger *util.LogEntry,
	roomID string,
	call *chatv1.CallContent,
) error {
	callRecord, err := cp.findCall(ctx, roomID, call.GetCallId())
	if err != nil {
		if errors.Is(err, errCallNotFound) {
			logger.Debug("call already ended or missing during end event")
			return nil
		}
		return err
	}
	if callRecord.Status == repository.CallStatusEnded {
		logger.Debug("call already ended or missing during end event")
		return nil
	}
	if err = cp.callRepo.EndCall(ctx, callRecord.GetID()); err != nil {
		return fmt.Errorf("failed to end call: %w", err)
	}
	logger.Debug("ended call")
	return nil
}

func (cp *callPolicy) validateCallPayload(call *chatv1.CallContent) error {
	switch call.GetAction() {
	case chatv1.CallContent_CALL_ACTION_OFFER, chatv1.CallContent_CALL_ACTION_ANSWER:
		if call.GetSdp() == "" {
			return connect.NewError(connect.CodeInvalidArgument, errors.New("call offer/answer requires SDP"))
		}
	case chatv1.CallContent_CALL_ACTION_ICE_CANDIDATE:
		if call.GetIceCandidate() == "" {
			return connect.NewError(connect.CodeInvalidArgument, errors.New("call ICE candidate requires candidate"))
		}
	case chatv1.CallContent_CALL_ACTION_UNSPECIFIED, chatv1.CallContent_CALL_ACTION_END:
		return nil
	}

	return nil
}

func (cp *callPolicy) validateTopology(topology string, call *chatv1.CallContent) error {
	if topology == callTopologySFU && cp.sfuNodeID(call) == "" {
		return connect.NewError(
			connect.CodeFailedPrecondition,
			errors.New("sfu topology requires sfuNodeId"),
		)
	}

	return nil
}

func (cp *callPolicy) validateParticipantCapacity(
	ctx context.Context,
	roomID string,
	signalKind string,
	topology string,
) error {
	if topology == callTopologySFU {
		return nil
	}

	activeMembers, err := cp.subRepo.CountActiveMembers(ctx, roomID)
	if err != nil {
		return fmt.Errorf("failed to count active room members: %w", err)
	}

	memberLimit := cp.cfg.DirectCallMemberLimit
	callMode := "direct"
	if cp.isGroupSignal(signalKind) || topology == callTopologyMesh {
		memberLimit = cp.cfg.MeshCallMemberLimit
		callMode = "group_mesh"
	}

	if activeMembers <= int64(memberLimit) {
		return nil
	}

	return connect.NewError(
		connect.CodeFailedPrecondition,
		fmt.Errorf(
			"%s call exceeds supported member limit (%d) without SFU assignment",
			callMode,
			memberLimit,
		),
	)
}

func (cp *callPolicy) isControlSignal(call *chatv1.CallContent, signalKind string) bool {
	if call.GetAction() == chatv1.CallContent_CALL_ACTION_ICE_CANDIDATE {
		return true
	}

	switch signalKind {
	case callSignalKindGroupJoin,
		callSignalKindGroupLeave,
		callSignalKindGroupMuteUpdate,
		callSignalKindGroupStageUpdate,
		callSignalKindGroupAnswer,
		callSignalKindGroupICE:
		return true
	default:
		return false
	}
}

func (cp *callPolicy) applySignalMetadata(
	callRecord *models.RoomCall,
	senderSubscription *models.RoomSubscription,
	call *chatv1.CallContent,
) error {
	switch cp.signalKind(call) {
	case callSignalKindGroupStart:
		cp.applyGroupStartMetadata(callRecord, senderSubscription, call)
	case callSignalKindGroupJoin:
		cp.applyGroupJoinMetadata(callRecord, senderSubscription)
	case callSignalKindGroupLeave:
		cp.applyGroupLeaveMetadata(callRecord, senderSubscription)
	case callSignalKindGroupStageUpdate:
		cp.applyGroupStageMetadata(callRecord, call)
	}

	return nil
}

func (cp *callPolicy) applyGroupStartMetadata(
	callRecord *models.RoomCall,
	senderSubscription *models.RoomSubscription,
	call *chatv1.CallContent,
) {
	hostProfileID := senderSubscription.ProfileID
	callRecord.Metadata[callMetadataKeyHostProfileID] = hostProfileID
	callRecord.Metadata[callMetadataKeyActiveParticipantIDs] = normalizeStringList([]string{hostProfileID})

	stageProfiles := normalizeStringList(
		metadataStringSlice(call.GetMetadata(), callMetadataKeyActiveVideoProfileIDs),
	)
	if len(stageProfiles) == 0 && hostProfileID != "" {
		stageProfiles = []string{hostProfileID}
	}
	callRecord.Metadata[callMetadataKeyActiveVideoProfileIDs] = cp.limitStageProfiles(stageProfiles)
}

func (cp *callPolicy) applyGroupJoinMetadata(
	callRecord *models.RoomCall,
	senderSubscription *models.RoomSubscription,
) {
	if senderSubscription.ProfileID == "" {
		return
	}
	active := normalizeStringList(
		append(
			jsonMapStringSlice(callRecord.Metadata, callMetadataKeyActiveParticipantIDs),
			senderSubscription.ProfileID,
		),
	)
	callRecord.Metadata[callMetadataKeyActiveParticipantIDs] = active
}

func (cp *callPolicy) applyGroupLeaveMetadata(
	callRecord *models.RoomCall,
	senderSubscription *models.RoomSubscription,
) {
	if senderSubscription.ProfileID == "" {
		return
	}
	callRecord.Metadata[callMetadataKeyActiveParticipantIDs] = removeString(
		jsonMapStringSlice(callRecord.Metadata, callMetadataKeyActiveParticipantIDs),
		senderSubscription.ProfileID,
	)
	callRecord.Metadata[callMetadataKeyActiveVideoProfileIDs] = removeString(
		jsonMapStringSlice(callRecord.Metadata, callMetadataKeyActiveVideoProfileIDs),
		senderSubscription.ProfileID,
	)
}

func (cp *callPolicy) applyGroupStageMetadata(
	callRecord *models.RoomCall,
	call *chatv1.CallContent,
) {
	stageProfiles := normalizeStringList(
		metadataStringSlice(call.GetMetadata(), callMetadataKeyActiveVideoProfileIDs),
	)
	callRecord.Metadata[callMetadataKeyActiveVideoProfileIDs] = cp.limitStageProfiles(stageProfiles)
}

func (cp *callPolicy) limitStageProfiles(stageProfiles []string) []string {
	if len(stageProfiles) <= cp.cfg.MaxVideoPublishers {
		return stageProfiles
	}
	return stageProfiles[:cp.cfg.MaxVideoPublishers]
}
