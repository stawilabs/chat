// Copyright 2023-2026 Ant Investor Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import { Namespace, Context } from "@ory/keto-namespace-types"

// ---------------------------------------------------------------------------
// Plane 0 -- Platform identity
// ---------------------------------------------------------------------------

class profile_user implements Namespace {}

// ---------------------------------------------------------------------------
// Plane 1 -- Data-access gate (tenancy)
// ---------------------------------------------------------------------------

class tenancy_access implements Namespace {
  related: {
    member: (profile_user | tenancy_access)[]
    service: profile_user[]
  }
}

// ---------------------------------------------------------------------------
// Plane 2 -- Functional roles (service_chat)
// Generated from ServicePermissions on chat.v1.ChatService.
// ---------------------------------------------------------------------------

class service_chat implements Namespace {
  related: {
    owner: profile_user[]
    admin: profile_user[]
    operator: profile_user[]
    viewer: profile_user[]
    member: profile_user[]
    service: (profile_user | tenancy_access)[]

    granted_event_view: (profile_user | service_chat)[]
    granted_event_send: (profile_user | service_chat)[]
    granted_room_view: (profile_user | service_chat)[]
    granted_room_create: (profile_user | service_chat)[]
    granted_room_update: (profile_user | service_chat)[]
    granted_room_delete: (profile_user | service_chat)[]
    granted_subscription_view: (profile_user | service_chat)[]
    granted_subscription_manage: (profile_user | service_chat)[]
    granted_proposal_view: (profile_user | service_chat)[]
    granted_proposal_manage: (profile_user | service_chat)[]
  }

  permits = {
    event_view: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.member.includes(ctx.subject) ||
      this.related.operator.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.viewer.includes(ctx.subject) ||
      this.related.granted_event_view.includes(ctx.subject),

    event_send: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.member.includes(ctx.subject) ||
      this.related.operator.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.granted_event_send.includes(ctx.subject),

    room_view: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.member.includes(ctx.subject) ||
      this.related.operator.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.viewer.includes(ctx.subject) ||
      this.related.granted_room_view.includes(ctx.subject),

    room_create: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.granted_room_create.includes(ctx.subject),

    room_update: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.granted_room_update.includes(ctx.subject),

    room_delete: (ctx: Context): boolean =>
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.granted_room_delete.includes(ctx.subject),

    subscription_view: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.member.includes(ctx.subject) ||
      this.related.operator.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.viewer.includes(ctx.subject) ||
      this.related.granted_subscription_view.includes(ctx.subject),

    subscription_manage: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.granted_subscription_manage.includes(ctx.subject),

    proposal_view: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.operator.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.viewer.includes(ctx.subject) ||
      this.related.granted_proposal_view.includes(ctx.subject),

    proposal_manage: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.service.includes(ctx.subject) ||
      this.related.granted_proposal_manage.includes(ctx.subject),
  }
}

// ---------------------------------------------------------------------------
// Plane 3 -- Per-resource namespaces (chat_room, chat_message, etc.)
// MOVED to proto/chat/v1/chat_resources.opl.ts so they are co-located with
// the proto API definitions and reusable by other services.
// ---------------------------------------------------------------------------
