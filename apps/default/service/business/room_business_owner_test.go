package business_test

import (
	"context"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"buf.build/gen/go/antinvestor/profile/connectrpc/go/v2/profile/v1/profilev1connect"
	profilev1 "buf.build/gen/go/antinvestor/profile/protocolbuffers/go/profile/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/repository"
)

// contactProfiles answers GetByContact from a fixed contact → profile map and
// refuses any other contact, as the profile service does for one it lacks.
type contactProfiles struct {
	profilev1connect.ProfileServiceClient
	byContact map[string]string
}

func (c *contactProfiles) GetByContact(
	_ context.Context,
	req *profilev1.GetByContactRequest,
) (*profilev1.GetByContactResponse, error) {
	id, ok := c.byContact[req.GetContact()]
	if !ok {
		return nil, connect.NewError(connect.CodeNotFound, "contact not found")
	}
	return &profilev1.GetByContactResponse{Data: &profilev1.ProfileObject{Id: id}}, nil
}

// A room whose creator cannot be made its owner is not created, even when
// another member's subscription succeeded: it would have members and no one
// able to see or administer it.
func (s *RoomBusinessTestSuite) TestCreateRoomRefusedWhenTheOwnerCannotSubscribe() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
		subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
		subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
		messageBusiness := business.NewMessageBusiness(
			svc.EventsManager(),
			repository.NewRoomEventRepository(
				ctx,
				dbPool,
				workMan,
			),
			repository.NewRoomOutboxRepository(ctx, dbPool, workMan),
			subRepo,
			subscriptionSvc,
			s.AuthzMiddleware,
		)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		member := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		// The profile service knows the member's contact and not the creator's.
		profiles := &contactProfiles{byContact: map[string]string{member.GetContactId(): member.GetProfileId()}}
		rooms := business.NewRoomBusiness(
			svc,
			roomRepo,
			repository.NewRoomEventRepository(ctx, dbPool, workMan),
			subRepo,
			nil,
			subscriptionSvc,
			svc.EventsManager(),
			messageBusiness,
			profiles,
			s.AuthzMiddleware,
		)

		roomID := util.IDString()
		_, err := rooms.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Id: roomID, Name: "Ownerless", Members: []*commonv1.ContactLink{member},
		}, creator)
		require.Error(t, err, "a room its creator cannot own is refused")
		_, err = roomRepo.GetByID(ctx, roomID)
		require.Error(t, err, "and not left behind")
	})
}
