package models

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/v2/data"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/types/known/structpb"
)

// Payload field constants.
const (
	PayloadTypeField      = "p_type"
	ContentField          = "content"
	maxPayloadTypeOrdinal = int64(2147483647)
)

// PayloadConverter handles conversion between protobuf payloads and JSON maps.
// It's stateless and can be used concurrently.
type PayloadConverter struct{}

// NewPayloadConverter creates a new PayloadConverter instance.
func NewPayloadConverter() *PayloadConverter {
	return &PayloadConverter{}
}

// ToProto converts a domain JSONMap to a protobuf Payload with typed content.
func (c *PayloadConverter) ToProto(content data.JSONMap) (*chatv1.Payload, error) {
	if content == nil {
		return nil, errors.New("content cannot be nil")
	}

	// Extract payload type and content
	payloadType, err := payloadTypeFromJSONMap(content)
	if err != nil {
		return nil, err
	}

	// Create base proto event
	protoPayload := &chatv1.Payload{Type: payloadType}

	rawContent, ok := content[ContentField]
	if ok {
		payloadData, normalizeErr := normalizePayloadContent(rawContent)
		if normalizeErr != nil {
			return nil, fmt.Errorf("failed to normalize payload content: %w", normalizeErr)
		}
		if setErr := c.setTypedContent(protoPayload, payloadType, payloadData); setErr != nil {
			return nil, fmt.Errorf("failed to set typed content: %w", setErr)
		}
	}

	return protoPayload, nil
}

func normalizePayloadContent(rawContent any) ([]byte, error) {
	switch value := rawContent.(type) {
	case nil:
		return nil, nil
	case []byte:
		return value, nil
	case string:
		decoded, err := base64.StdEncoding.DecodeString(value)
		if err == nil && json.Valid(decoded) {
			return decoded, nil
		}
		return []byte(value), nil
	case map[string]any, []any:
		normalized, err := json.Marshal(value)
		if err != nil {
			return nil, fmt.Errorf("marshal structured payload content: %w", err)
		}
		return normalized, nil
	default:
		return nil, fmt.Errorf("unsupported payload content %T", rawContent)
	}
}

func payloadTypeFromJSONMap(content data.JSONMap) (chatv1.PayloadType, error) {
	rawType, ok := content[PayloadTypeField]
	if !ok {
		return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, nil
	}

	switch value := rawType.(type) {
	case float64:
		return payloadTypeFromInt64(int64(value))
	case float32:
		return payloadTypeFromInt64(int64(value))
	case int:
		return payloadTypeFromInt64(int64(value))
	case int32:
		return payloadTypeFromInt64(int64(value))
	case int64:
		return payloadTypeFromInt64(value)
	case uint:
		return payloadTypeFromUint64(uint64(value))
	case uint32:
		return payloadTypeFromUint64(uint64(value))
	case uint64:
		return payloadTypeFromUint64(value)
	case json.Number:
		number, err := value.Int64()
		if err != nil {
			return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, fmt.Errorf(
				"invalid payload type %q: %w",
				value.String(),
				err,
			)
		}
		return payloadTypeFromInt64(number)
	case protoreflect.EnumNumber:
		return payloadTypeFromInt64(int64(value))
	default:
		return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, fmt.Errorf(
			"unsupported payload type %T",
			rawType,
		)
	}
}

func payloadTypeFromInt64(value int64) (chatv1.PayloadType, error) {
	if value < -maxPayloadTypeOrdinal-1 || value > maxPayloadTypeOrdinal {
		return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, fmt.Errorf(
			"payload type %d is out of int32 range",
			value,
		)
	}

	return chatv1.PayloadType(int32(value)), nil
}

func payloadTypeFromUint64(value uint64) (chatv1.PayloadType, error) {
	if value > uint64(maxPayloadTypeOrdinal) {
		return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, fmt.Errorf(
			"payload type %d is out of int32 range",
			value,
		)
	}

	return chatv1.PayloadType(int32(value)), nil
}

// FromProto converts a protobuf Payload to a domain JSONMap with content.
func (c *PayloadConverter) FromProto(protoEvent *chatv1.Payload) (data.JSONMap, error) {
	if protoEvent == nil {
		return nil, errors.New("proto event cannot be nil")
	}

	payloadType := protoEvent.GetType()
	if payloadType == chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED {
		payloadType = inferPayloadType(protoEvent)
	}

	// Extract payload based on type
	var payload interface{}
	switch payloadType {
	case chatv1.PayloadType_PAYLOAD_TYPE_MODERATION:
		payload = protoEvent.GetModeration()
	case chatv1.PayloadType_PAYLOAD_TYPE_TEXT:
		payload = protoEvent.GetText()
	case chatv1.PayloadType_PAYLOAD_TYPE_ATTACHMENT:
		payload = protoEvent.GetAttachment()
	case chatv1.PayloadType_PAYLOAD_TYPE_REACTION:
		payload = protoEvent.GetReaction()
	case chatv1.PayloadType_PAYLOAD_TYPE_ENCRYPTED:
		payload = protoEvent.GetEncrypted()
	case chatv1.PayloadType_PAYLOAD_TYPE_CALL:
		payload = protoEvent.GetCall()
	case chatv1.PayloadType_PAYLOAD_TYPE_MOTION:
		payload = protoEvent.GetMotion()
	case chatv1.PayloadType_PAYLOAD_TYPE_VOTE:
		payload = protoEvent.GetVote()
	case chatv1.PayloadType_PAYLOAD_TYPE_MOTION_TALLY:
		payload = protoEvent.GetMotionTally()
	case chatv1.PayloadType_PAYLOAD_TYPE_VOTE_TALLY:
		payload = protoEvent.GetVoteTally()
	case chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE:
		payload = protoEvent.GetRoomChange()
	case chatv1.PayloadType_PAYLOAD_TYPE_FORM_REQUEST:
		payload = protoEvent.GetFormRequest()
	case chatv1.PayloadType_PAYLOAD_TYPE_FORM_SUBMISSION_RESULT:
		payload = protoEvent.GetFormSubmissionResult()
	case chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED:
		payload = protoEvent.GetDefault()
	default: // Covers unknown types
		payload = protoEvent.GetDefault()
	}

	content := data.JSONMap{
		PayloadTypeField: payloadType.Number(),
	}

	if payload != nil {
		// Marshal payload to JSON
		jsonContent, err := json.Marshal(payload)
		if err != nil {
			return nil, err
		}

		content[ContentField] = jsonContent
	}

	// Return structured result
	return content, nil
}

func inferPayloadType(protoEvent *chatv1.Payload) chatv1.PayloadType {
	switch protoEvent.GetData().(type) {
	case *chatv1.Payload_Moderation:
		return chatv1.PayloadType_PAYLOAD_TYPE_MODERATION
	case *chatv1.Payload_Text:
		return chatv1.PayloadType_PAYLOAD_TYPE_TEXT
	case *chatv1.Payload_Attachment:
		return chatv1.PayloadType_PAYLOAD_TYPE_ATTACHMENT
	case *chatv1.Payload_Reaction:
		return chatv1.PayloadType_PAYLOAD_TYPE_REACTION
	case *chatv1.Payload_Encrypted:
		return chatv1.PayloadType_PAYLOAD_TYPE_ENCRYPTED
	case *chatv1.Payload_Call:
		return chatv1.PayloadType_PAYLOAD_TYPE_CALL
	case *chatv1.Payload_Motion:
		return chatv1.PayloadType_PAYLOAD_TYPE_MOTION
	case *chatv1.Payload_Vote:
		return chatv1.PayloadType_PAYLOAD_TYPE_VOTE
	case *chatv1.Payload_MotionTally:
		return chatv1.PayloadType_PAYLOAD_TYPE_MOTION_TALLY
	case *chatv1.Payload_VoteTally:
		return chatv1.PayloadType_PAYLOAD_TYPE_VOTE_TALLY
	case *chatv1.Payload_RoomChange:
		return chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE
	case *chatv1.Payload_FormRequest:
		return chatv1.PayloadType_PAYLOAD_TYPE_FORM_REQUEST
	case *chatv1.Payload_FormSubmissionResult:
		return chatv1.PayloadType_PAYLOAD_TYPE_FORM_SUBMISSION_RESULT
	case *chatv1.Payload_Default:
		return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED
	default:
		return chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED
	}
}

// setTypedContent sets the appropriate typed content field on the proto event.
//
//nolint:gocognit,gocyclo,cyclop,funlen // Payload decoding is intentionally centralized by payload type.
func (c *PayloadConverter) setTypedContent(
	protoEvent *chatv1.Payload,
	payloadType chatv1.PayloadType,
	content []byte,
) error {
	if len(content) == 0 {
		return nil
	}

	switch payloadType {
	case chatv1.PayloadType_PAYLOAD_TYPE_MODERATION:
		var payload chatv1.ModerationContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Moderation{Moderation: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_TEXT:
		var payload chatv1.TextContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Text{Text: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_ATTACHMENT:
		var payload chatv1.AttachmentContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Attachment{Attachment: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_REACTION:
		var payload chatv1.ReactionContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Reaction{Reaction: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_ENCRYPTED:
		var payload chatv1.EncryptedContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Encrypted{Encrypted: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_CALL:
		var payload chatv1.CallContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Call{Call: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_MOTION:
		var payload chatv1.MotionContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Motion{Motion: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_VOTE:
		var payload chatv1.VoteCast
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Vote{Vote: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_MOTION_TALLY:
		var payload chatv1.MotionTally
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_MotionTally{MotionTally: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_VOTE_TALLY:
		var payload chatv1.VoteTally
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_VoteTally{VoteTally: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE:
		var payload chatv1.RoomChangeContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_RoomChange{RoomChange: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_FORM_REQUEST:
		var payload chatv1.FormRequestContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_FormRequest{FormRequest: &payload}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_FORM_SUBMISSION_RESULT:
		var payload chatv1.FormSubmissionResultContent
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_FormSubmissionResult{
			FormSubmissionResult: &payload,
		}
		return nil
	case chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED:
		var payload structpb.Struct
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Default{Default: &payload}
		return nil
	default:
		var payload structpb.Struct
		if err := json.Unmarshal(content, &payload); err != nil {
			return err
		}
		protoEvent.Data = &chatv1.Payload_Default{Default: &payload}
		return nil
	}
}
