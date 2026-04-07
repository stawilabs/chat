//
//  Generated code. Do not modify.
//  source: chat/v1/chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pb.dart' as $10;
import 'chat.pbjson.dart';

export 'chat.pb.dart';

abstract class ChatServiceBase extends $pb.GeneratedService {
  $async.Future<$10.SendEventResponse> sendEvent($pb.ServerContext ctx, $10.SendEventRequest request);
  $async.Future<$10.GetEventResponse> getEvent($pb.ServerContext ctx, $10.GetEventRequest request);
  $async.Future<$10.GetHistoryResponse> getHistory($pb.ServerContext ctx, $10.GetHistoryRequest request);
  $async.Future<$10.GetRoomResponse> getRoom($pb.ServerContext ctx, $10.GetRoomRequest request);
  $async.Future<$10.CreateRoomResponse> createRoom($pb.ServerContext ctx, $10.CreateRoomRequest request);
  $async.Future<$10.SearchRoomsResponse> searchRooms($pb.ServerContext ctx, $10.SearchRoomsRequest request);
  $async.Future<$10.UpdateRoomResponse> updateRoom($pb.ServerContext ctx, $10.UpdateRoomRequest request);
  $async.Future<$10.DeleteRoomResponse> deleteRoom($pb.ServerContext ctx, $10.DeleteRoomRequest request);
  $async.Future<$10.AddRoomSubscriptionsResponse> addRoomSubscriptions($pb.ServerContext ctx, $10.AddRoomSubscriptionsRequest request);
  $async.Future<$10.RemoveRoomSubscriptionsResponse> removeRoomSubscriptions($pb.ServerContext ctx, $10.RemoveRoomSubscriptionsRequest request);
  $async.Future<$10.UpdateSubscriptionRoleResponse> updateSubscriptionRole($pb.ServerContext ctx, $10.UpdateSubscriptionRoleRequest request);
  $async.Future<$10.SearchRoomSubscriptionsResponse> searchRoomSubscriptions($pb.ServerContext ctx, $10.SearchRoomSubscriptionsRequest request);
  $async.Future<$10.GetSubscriptionSettingsResponse> getSubscriptionSettings($pb.ServerContext ctx, $10.GetSubscriptionSettingsRequest request);
  $async.Future<$10.UpdateSubscriptionSettingsResponse> updateSubscriptionSettings($pb.ServerContext ctx, $10.UpdateSubscriptionSettingsRequest request);
  $async.Future<$10.LiveResponse> live($pb.ServerContext ctx, $10.LiveRequest request);
  $async.Future<$10.ListProposalsResponse> listProposals($pb.ServerContext ctx, $10.ListProposalsRequest request);
  $async.Future<$10.SubmitProposalResponse> submitProposal($pb.ServerContext ctx, $10.SubmitProposalRequest request);
  $async.Future<$10.ResolveReplayCursorResponse> resolveReplayCursor($pb.ServerContext ctx, $10.ResolveReplayCursorRequest request);
  $async.Future<$10.GetLatestReplayCursorResponse> getLatestReplayCursor($pb.ServerContext ctx, $10.GetLatestReplayCursorRequest request);
  $async.Future<$10.ListReplayEventsResponse> listReplayEvents($pb.ServerContext ctx, $10.ListReplayEventsRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'SendEvent': return $10.SendEventRequest();
      case 'GetEvent': return $10.GetEventRequest();
      case 'GetHistory': return $10.GetHistoryRequest();
      case 'GetRoom': return $10.GetRoomRequest();
      case 'CreateRoom': return $10.CreateRoomRequest();
      case 'SearchRooms': return $10.SearchRoomsRequest();
      case 'UpdateRoom': return $10.UpdateRoomRequest();
      case 'DeleteRoom': return $10.DeleteRoomRequest();
      case 'AddRoomSubscriptions': return $10.AddRoomSubscriptionsRequest();
      case 'RemoveRoomSubscriptions': return $10.RemoveRoomSubscriptionsRequest();
      case 'UpdateSubscriptionRole': return $10.UpdateSubscriptionRoleRequest();
      case 'SearchRoomSubscriptions': return $10.SearchRoomSubscriptionsRequest();
      case 'GetSubscriptionSettings': return $10.GetSubscriptionSettingsRequest();
      case 'UpdateSubscriptionSettings': return $10.UpdateSubscriptionSettingsRequest();
      case 'Live': return $10.LiveRequest();
      case 'ListProposals': return $10.ListProposalsRequest();
      case 'SubmitProposal': return $10.SubmitProposalRequest();
      case 'ResolveReplayCursor': return $10.ResolveReplayCursorRequest();
      case 'GetLatestReplayCursor': return $10.GetLatestReplayCursorRequest();
      case 'ListReplayEvents': return $10.ListReplayEventsRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'SendEvent': return this.sendEvent(ctx, request as $10.SendEventRequest);
      case 'GetEvent': return this.getEvent(ctx, request as $10.GetEventRequest);
      case 'GetHistory': return this.getHistory(ctx, request as $10.GetHistoryRequest);
      case 'GetRoom': return this.getRoom(ctx, request as $10.GetRoomRequest);
      case 'CreateRoom': return this.createRoom(ctx, request as $10.CreateRoomRequest);
      case 'SearchRooms': return this.searchRooms(ctx, request as $10.SearchRoomsRequest);
      case 'UpdateRoom': return this.updateRoom(ctx, request as $10.UpdateRoomRequest);
      case 'DeleteRoom': return this.deleteRoom(ctx, request as $10.DeleteRoomRequest);
      case 'AddRoomSubscriptions': return this.addRoomSubscriptions(ctx, request as $10.AddRoomSubscriptionsRequest);
      case 'RemoveRoomSubscriptions': return this.removeRoomSubscriptions(ctx, request as $10.RemoveRoomSubscriptionsRequest);
      case 'UpdateSubscriptionRole': return this.updateSubscriptionRole(ctx, request as $10.UpdateSubscriptionRoleRequest);
      case 'SearchRoomSubscriptions': return this.searchRoomSubscriptions(ctx, request as $10.SearchRoomSubscriptionsRequest);
      case 'GetSubscriptionSettings': return this.getSubscriptionSettings(ctx, request as $10.GetSubscriptionSettingsRequest);
      case 'UpdateSubscriptionSettings': return this.updateSubscriptionSettings(ctx, request as $10.UpdateSubscriptionSettingsRequest);
      case 'Live': return this.live(ctx, request as $10.LiveRequest);
      case 'ListProposals': return this.listProposals(ctx, request as $10.ListProposalsRequest);
      case 'SubmitProposal': return this.submitProposal(ctx, request as $10.SubmitProposalRequest);
      case 'ResolveReplayCursor': return this.resolveReplayCursor(ctx, request as $10.ResolveReplayCursorRequest);
      case 'GetLatestReplayCursor': return this.getLatestReplayCursor(ctx, request as $10.GetLatestReplayCursorRequest);
      case 'ListReplayEvents': return this.listReplayEvents(ctx, request as $10.ListReplayEventsRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ChatServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => ChatServiceBase$messageJson;
}

