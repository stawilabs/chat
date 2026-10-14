package business_test

import (
	"context"
	"errors"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"buf.build/gen/go/antinvestor/profile/connectrpc/go/v2/profile/v1/profilev1connect"
	profilev1 "buf.build/gen/go/antinvestor/profile/protocolbuffers/go/profile/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/repository"
)

type mockProfileClient struct {
	getByContactFunc func(context.Context, *profilev1.GetByContactRequest) (*profilev1.GetByContactResponse, error)
	getByIDFunc      func(context.Context, *profilev1.GetByIdRequest) (*profilev1.GetByIdResponse, error)
}

func (m *mockProfileClient) GetByContact(
	ctx context.Context,
	req *profilev1.GetByContactRequest,
) (*profilev1.GetByContactResponse, error) {
	if m.getByContactFunc != nil {
		return m.getByContactFunc(ctx, req)
	}
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) AddAddress(
	context.Context, *profilev1.AddAddressRequest,
) (*profilev1.AddAddressResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) AddContact(
	context.Context, *profilev1.AddContactRequest,
) (*profilev1.AddContactResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) AddRelationship(
	context.Context, *profilev1.AddRelationshipRequest,
) (*profilev1.AddRelationshipResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) AddRoster(
	context.Context, *profilev1.AddRosterRequest,
) (*profilev1.AddRosterResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) CheckVerification(
	context.Context, *profilev1.CheckVerificationRequest,
) (*profilev1.CheckVerificationResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) Create(
	context.Context, *profilev1.CreateRequest,
) (*profilev1.CreateResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) CreateContact(
	context.Context, *profilev1.CreateContactRequest,
) (*profilev1.CreateContactResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) CreateContactVerification(
	context.Context, *profilev1.CreateContactVerificationRequest,
) (*profilev1.CreateContactVerificationResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) DeleteRelationship(
	context.Context, *profilev1.DeleteRelationshipRequest,
) (*profilev1.DeleteRelationshipResponse, error) {
	return nil, errors.New("not implemented")
}

//nolint:staticcheck,revive // Method name required by interface
func (m *mockProfileClient) GetById(
	ctx context.Context,
	req *profilev1.GetByIdRequest,
) (*profilev1.GetByIdResponse, error) {
	if m.getByIDFunc != nil {
		return m.getByIDFunc(ctx, req)
	}
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) ListRelationship(
	context.Context, *profilev1.ListRelationshipRequest,
) (profilev1connect.ProfileServiceListRelationshipClientStream, error) {
	return profilev1connect.ProfileServiceListRelationshipClientStream{}, errors.New("not implemented")
}

func (m *mockProfileClient) Merge(
	context.Context, *profilev1.MergeRequest,
) (*profilev1.MergeResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) RemoveContact(
	context.Context, *profilev1.RemoveContactRequest,
) (*profilev1.RemoveContactResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) RemoveRoster(
	context.Context, *profilev1.RemoveRosterRequest,
) (*profilev1.RemoveRosterResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) Search(
	context.Context, *profilev1.SearchRequest,
) (profilev1connect.ProfileServiceSearchClientStream, error) {
	return profilev1connect.ProfileServiceSearchClientStream{}, errors.New("not implemented")
}

func (m *mockProfileClient) SearchRoster(
	context.Context, *profilev1.SearchRosterRequest,
) (profilev1connect.ProfileServiceSearchRosterClientStream, error) {
	return profilev1connect.ProfileServiceSearchRosterClientStream{}, errors.New("not implemented")
}

func (m *mockProfileClient) Update(
	context.Context, *profilev1.UpdateRequest,
) (*profilev1.UpdateResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) GetByIDAndPartition(
	context.Context, *profilev1.GetByIDAndPartitionRequest,
) (*profilev1.GetByIDAndPartitionResponse, error) {
	return nil, errors.New("not implemented")
}

func (m *mockProfileClient) PropertyHistory(
	context.Context, *profilev1.PropertyHistoryRequest,
) (*profilev1.PropertyHistoryResponse, error) {
	return nil, errors.New("not implemented")
}

func (s *RoomBusinessTestSuite) setupBusinessLayerWithProfileClient(
	ctx context.Context, svc *frame.Service, profileCli profilev1connect.ProfileServiceClient,
) business.RoomBusiness {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
	messageBusiness := business.NewMessageBusiness(
		evtsMan,
		eventRepo,
		outboxRepo,
		subRepo,
		subscriptionSvc,
		s.AuthzMiddleware,
	)
	roomBusiness := business.NewRoomBusiness(
		svc,
		roomRepo,
		eventRepo,
		subRepo,
		nil, // proposalRepo
		subscriptionSvc,
		evtsMan,
		messageBusiness,
		profileCli,
		s.AuthzMiddleware,
	)

	return roomBusiness
}

func (s *RoomBusinessTestSuite) TestCreateRoomWithValidationSuccess() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)

		validContactID := util.IDString()
		validProfileID := util.IDString()

		creatorID := util.IDString()
		creatorContactID := util.IDString()

		mockCli := &mockProfileClient{
			getByContactFunc: func(_ context.Context, req *profilev1.GetByContactRequest) (*profilev1.GetByContactResponse, error) {
				if req.GetContact() == validContactID {
					return &profilev1.GetByContactResponse{
						Data: &profilev1.ProfileObject{Id: validProfileID},
					}, nil
				}
				if req.GetContact() == creatorContactID {
					return &profilev1.GetByContactResponse{
						Data: &profilev1.ProfileObject{Id: creatorID},
					}, nil
				}
				return nil, errors.New("not found")
			},
		}

		roomBusiness := s.setupBusinessLayerWithProfileClient(ctx, svc, mockCli)

		req := &chatv1.CreateRoomRequest{
			Name:      "Validation Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ContactId: validContactID, ProfileId: validProfileID},
			},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.NotNil(room)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), validProfileID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Verify subscription created
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{
			RoomId: room.GetId(),
		}
		subs, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			searchReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		found := false
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == validProfileID {
				found = true
				break
			}
		}
		s.True(found)
	})
}

func (s *RoomBusinessTestSuite) TestCreateRoomWithValidationFailure_ProfileMismatch() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)

		validContactID := util.IDString()
		actualProfileID := util.IDString()
		wrongProfileID := util.IDString()

		mockCli := &mockProfileClient{
			getByContactFunc: func(_ context.Context, _ *profilev1.GetByContactRequest) (*profilev1.GetByContactResponse, error) {
				return &profilev1.GetByContactResponse{
					Data: &profilev1.ProfileObject{Id: actualProfileID},
				}, nil
			},
		}

		roomBusiness := s.setupBusinessLayerWithProfileClient(ctx, svc, mockCli)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		req := &chatv1.CreateRoomRequest{
			Name:      "Mismatch Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ContactId: validContactID, ProfileId: wrongProfileID},
			},
		}

		_, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.Error(t, err)
		s.Contains(err.Error(), "profile id mismatch")
	})
}

func (s *RoomBusinessTestSuite) TestCreateRoomWithValidationFailure_ContactNotFound() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)

		invalidContactID := util.IDString()

		mockCli := &mockProfileClient{
			getByContactFunc: func(_ context.Context, _ *profilev1.GetByContactRequest) (*profilev1.GetByContactResponse, error) {
				return nil, errors.New("contact not found")
			},
		}

		roomBusiness := s.setupBusinessLayerWithProfileClient(ctx, svc, mockCli)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		req := &chatv1.CreateRoomRequest{
			Name:      "Invalid Contact Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ContactId: invalidContactID},
			},
		}

		_, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.Error(t, err)
		s.Contains(err.Error(), "contact validation failed")
	})
}

// TestCreateRoomWithValidation_PopulatesProfileID tests that validateContactProfile
// populates the ProfileId from the profile service when it's missing from the ContactLink.
func (s *RoomBusinessTestSuite) TestCreateRoomWithValidation_PopulatesProfileID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)

		validContactID := util.IDString()
		resolvedProfileID := util.IDString()

		creatorID := util.IDString()
		creatorContactID := util.IDString()

		mockCli := &mockProfileClient{
			getByContactFunc: func(_ context.Context, req *profilev1.GetByContactRequest) (*profilev1.GetByContactResponse, error) {
				if req.GetContact() == validContactID {
					return &profilev1.GetByContactResponse{
						Data: &profilev1.ProfileObject{Id: resolvedProfileID},
					}, nil
				}
				if req.GetContact() == creatorContactID {
					return &profilev1.GetByContactResponse{
						Data: &profilev1.ProfileObject{Id: creatorID},
					}, nil
				}
				return nil, errors.New("not found")
			},
		}

		roomBusiness := s.setupBusinessLayerWithProfileClient(ctx, svc, mockCli)

		// Member has ContactId but no ProfileId - should be populated from profile service
		req := &chatv1.CreateRoomRequest{
			Name:      "Populate ProfileID Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ContactId: validContactID}, // no ProfileId
			},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.NotNil(room)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), resolvedProfileID, t)
	})
}

func (m *mockProfileClient) GetContacts(
	context.Context, *profilev1.GetContactsRequest,
) (*profilev1.GetContactsResponse, error) {
	return nil, connect.NewError(connect.CodeUnimplemented, "")
}

func (m *mockProfileClient) ResolveAccounts(
	context.Context, *profilev1.ResolveAccountsRequest,
) (*profilev1.ResolveAccountsResponse, error) {
	return nil, connect.NewError(connect.CodeUnimplemented, "")
}
