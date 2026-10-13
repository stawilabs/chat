// This is a generated file - do not edit.
//
// Generated from chat/v1/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pb.dart' as $5;
import 'chat.pbjson.dart';

export 'chat.pb.dart';

abstract class ChatServiceBase extends $pb.GeneratedService {
  $async.Future<$5.SendEventResponse> sendEvent(
      $pb.ServerContext ctx, $5.SendEventRequest request);
  $async.Future<$5.GetEventResponse> getEvent(
      $pb.ServerContext ctx, $5.GetEventRequest request);
  $async.Future<$5.GetHistoryResponse> getHistory(
      $pb.ServerContext ctx, $5.GetHistoryRequest request);
  $async.Future<$5.GetRoomResponse> getRoom(
      $pb.ServerContext ctx, $5.GetRoomRequest request);
  $async.Future<$5.CreateRoomResponse> createRoom(
      $pb.ServerContext ctx, $5.CreateRoomRequest request);
  $async.Future<$5.SearchRoomsResponse> searchRooms(
      $pb.ServerContext ctx, $5.SearchRoomsRequest request);
  $async.Future<$5.UpdateRoomResponse> updateRoom(
      $pb.ServerContext ctx, $5.UpdateRoomRequest request);
  $async.Future<$5.DeleteRoomResponse> deleteRoom(
      $pb.ServerContext ctx, $5.DeleteRoomRequest request);
  $async.Future<$5.AddRoomSubscriptionsResponse> addRoomSubscriptions(
      $pb.ServerContext ctx, $5.AddRoomSubscriptionsRequest request);
  $async.Future<$5.RemoveRoomSubscriptionsResponse> removeRoomSubscriptions(
      $pb.ServerContext ctx, $5.RemoveRoomSubscriptionsRequest request);
  $async.Future<$5.UpdateSubscriptionRoleResponse> updateSubscriptionRole(
      $pb.ServerContext ctx, $5.UpdateSubscriptionRoleRequest request);
  $async.Future<$5.GetDirectPartnerAccountResponse> getDirectPartnerAccount(
      $pb.ServerContext ctx, $5.GetDirectPartnerAccountRequest request);
  $async.Future<$5.SearchRoomSubscriptionsResponse> searchRoomSubscriptions(
      $pb.ServerContext ctx, $5.SearchRoomSubscriptionsRequest request);
  $async.Future<$5.GetSubscriptionSettingsResponse> getSubscriptionSettings(
      $pb.ServerContext ctx, $5.GetSubscriptionSettingsRequest request);
  $async.Future<$5.UpdateSubscriptionSettingsResponse>
      updateSubscriptionSettings(
          $pb.ServerContext ctx, $5.UpdateSubscriptionSettingsRequest request);
  $async.Future<$5.LiveResponse> live(
      $pb.ServerContext ctx, $5.LiveRequest request);
  $async.Future<$5.ListProposalsResponse> listProposals(
      $pb.ServerContext ctx, $5.ListProposalsRequest request);
  $async.Future<$5.SubmitProposalResponse> submitProposal(
      $pb.ServerContext ctx, $5.SubmitProposalRequest request);
  $async.Future<$5.ResolveReplayCursorResponse> resolveReplayCursor(
      $pb.ServerContext ctx, $5.ResolveReplayCursorRequest request);
  $async.Future<$5.GetLatestReplayCursorResponse> getLatestReplayCursor(
      $pb.ServerContext ctx, $5.GetLatestReplayCursorRequest request);
  $async.Future<$5.ListReplayEventsResponse> listReplayEvents(
      $pb.ServerContext ctx, $5.ListReplayEventsRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'SendEvent':
        return $5.SendEventRequest();
      case 'GetEvent':
        return $5.GetEventRequest();
      case 'GetHistory':
        return $5.GetHistoryRequest();
      case 'GetRoom':
        return $5.GetRoomRequest();
      case 'CreateRoom':
        return $5.CreateRoomRequest();
      case 'SearchRooms':
        return $5.SearchRoomsRequest();
      case 'UpdateRoom':
        return $5.UpdateRoomRequest();
      case 'DeleteRoom':
        return $5.DeleteRoomRequest();
      case 'AddRoomSubscriptions':
        return $5.AddRoomSubscriptionsRequest();
      case 'RemoveRoomSubscriptions':
        return $5.RemoveRoomSubscriptionsRequest();
      case 'UpdateSubscriptionRole':
        return $5.UpdateSubscriptionRoleRequest();
      case 'GetDirectPartnerAccount':
        return $5.GetDirectPartnerAccountRequest();
      case 'SearchRoomSubscriptions':
        return $5.SearchRoomSubscriptionsRequest();
      case 'GetSubscriptionSettings':
        return $5.GetSubscriptionSettingsRequest();
      case 'UpdateSubscriptionSettings':
        return $5.UpdateSubscriptionSettingsRequest();
      case 'Live':
        return $5.LiveRequest();
      case 'ListProposals':
        return $5.ListProposalsRequest();
      case 'SubmitProposal':
        return $5.SubmitProposalRequest();
      case 'ResolveReplayCursor':
        return $5.ResolveReplayCursorRequest();
      case 'GetLatestReplayCursor':
        return $5.GetLatestReplayCursorRequest();
      case 'ListReplayEvents':
        return $5.ListReplayEventsRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'SendEvent':
        return sendEvent(ctx, request as $5.SendEventRequest);
      case 'GetEvent':
        return getEvent(ctx, request as $5.GetEventRequest);
      case 'GetHistory':
        return getHistory(ctx, request as $5.GetHistoryRequest);
      case 'GetRoom':
        return getRoom(ctx, request as $5.GetRoomRequest);
      case 'CreateRoom':
        return createRoom(ctx, request as $5.CreateRoomRequest);
      case 'SearchRooms':
        return searchRooms(ctx, request as $5.SearchRoomsRequest);
      case 'UpdateRoom':
        return updateRoom(ctx, request as $5.UpdateRoomRequest);
      case 'DeleteRoom':
        return deleteRoom(ctx, request as $5.DeleteRoomRequest);
      case 'AddRoomSubscriptions':
        return addRoomSubscriptions(
            ctx, request as $5.AddRoomSubscriptionsRequest);
      case 'RemoveRoomSubscriptions':
        return removeRoomSubscriptions(
            ctx, request as $5.RemoveRoomSubscriptionsRequest);
      case 'UpdateSubscriptionRole':
        return updateSubscriptionRole(
            ctx, request as $5.UpdateSubscriptionRoleRequest);
      case 'GetDirectPartnerAccount':
        return getDirectPartnerAccount(
            ctx, request as $5.GetDirectPartnerAccountRequest);
      case 'SearchRoomSubscriptions':
        return searchRoomSubscriptions(
            ctx, request as $5.SearchRoomSubscriptionsRequest);
      case 'GetSubscriptionSettings':
        return getSubscriptionSettings(
            ctx, request as $5.GetSubscriptionSettingsRequest);
      case 'UpdateSubscriptionSettings':
        return updateSubscriptionSettings(
            ctx, request as $5.UpdateSubscriptionSettingsRequest);
      case 'Live':
        return live(ctx, request as $5.LiveRequest);
      case 'ListProposals':
        return listProposals(ctx, request as $5.ListProposalsRequest);
      case 'SubmitProposal':
        return submitProposal(ctx, request as $5.SubmitProposalRequest);
      case 'ResolveReplayCursor':
        return resolveReplayCursor(
            ctx, request as $5.ResolveReplayCursorRequest);
      case 'GetLatestReplayCursor':
        return getLatestReplayCursor(
            ctx, request as $5.GetLatestReplayCursorRequest);
      case 'ListReplayEvents':
        return listReplayEvents(ctx, request as $5.ListReplayEventsRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ChatServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => ChatServiceBase$messageJson;
}
