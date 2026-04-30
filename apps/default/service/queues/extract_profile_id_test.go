package queues

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/stretchr/testify/assert"
)

func TestExtractProfileID(t *testing.T) {
	tests := []struct {
		name     string
		delivery *eventsv1.Delivery
		want     string
	}{
		{
			name: "valid profile ID",
			delivery: &eventsv1.Delivery{
				Destination: &eventsv1.Subscription{
					ContactLink: &commonv1.ContactLink{
						ProfileId: "profile-123",
					},
				},
			},
			want: "profile-123",
		},
		{
			name: "empty profile ID",
			delivery: &eventsv1.Delivery{
				Destination: &eventsv1.Subscription{
					ContactLink: &commonv1.ContactLink{
						ProfileId: "",
						ContactId: "contact-456",
					},
				},
			},
			want: "",
		},
		{
			name: "nil contact link",
			delivery: &eventsv1.Delivery{
				Destination: &eventsv1.Subscription{
					ContactLink: nil,
				},
			},
			want: "",
		},
		{
			name: "nil destination",
			delivery: &eventsv1.Delivery{
				Destination: nil,
			},
			want: "",
		},
		{
			name:     "empty delivery",
			delivery: &eventsv1.Delivery{},
			want:     "",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := extractProfileID(tc.delivery)
			assert.Equal(t, tc.want, got)
		})
	}
}
