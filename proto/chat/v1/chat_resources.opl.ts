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

// ---------------------------------------------------------------------------
// Resource-level OPL definitions for chat.v1
//
// These namespaces define per-resource access control for chat objects.
// They live alongside the proto definitions so other services that reference
// chat resources (e.g., notification service checking chat_room membership)
// can discover and reuse these namespace definitions.
//
// The service-level namespace (service_chat) with functional role grants
// is generated from proto annotations and lives in apps/default/.
// ---------------------------------------------------------------------------

import { Namespace, Context } from "@ory/keto-namespace-types"

// ---------------------------------------------------------------------------
// Plane 0 -- Platform identity (shared across all services)
// ---------------------------------------------------------------------------

class profile_user implements Namespace {}

// ---------------------------------------------------------------------------
// Plane 3 -- Per-resource namespaces (chat_room, chat_message, etc.)
// These enforce fine-grained, object-level access control.
// ---------------------------------------------------------------------------

// chat_profile represents users/actors in the chat system.
class chat_profile implements Namespace {
  related: {
    self: chat_profile[]
  }
}

// chat_subscription represents room memberships used as authz subjects.
class chat_subscription implements Namespace {}

// chat_room represents chat rooms with hierarchical roles.
// Subjects are subscriptions (subscription-based authz).
// Direct-grant relations are prefixed with "granted_" to avoid name conflicts
// with permit functions -- Keto skips permit evaluation when a relation shares
// the same name as a permit function.
class chat_room implements Namespace {
  related: {
    granted_owner: (chat_profile | chat_subscription)[]
    granted_admin: (chat_profile | chat_subscription)[]
    granted_member: (chat_profile | chat_subscription)[]
    granted_viewer: (chat_profile | chat_subscription)[]
  }

  permits = {
    view: (ctx: Context): boolean =>
      this.related.granted_viewer.includes(ctx.subject) ||
      this.related.granted_member.includes(ctx.subject) ||
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    message_send: (ctx: Context): boolean =>
      this.related.granted_member.includes(ctx.subject) ||
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    message_delete_any: (ctx: Context): boolean =>
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    update: (ctx: Context): boolean =>
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    delete: (ctx: Context): boolean =>
      this.related.granted_owner.includes(ctx.subject),

    members_manage: (ctx: Context): boolean =>
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    roles_manage: (ctx: Context): boolean =>
      this.related.granted_owner.includes(ctx.subject),
  }
}

// chat_message represents individual messages with ownership.
// Permissions inherit from the parent chat_room via the room relation.
class chat_message implements Namespace {
  related: {
    granted_sender: chat_profile[]
    room: chat_room[]
  }

  permits = {
    view: (ctx: Context): boolean =>
      this.related.room.traverse((r) => r.permits.view(ctx)),

    delete: (ctx: Context): boolean =>
      this.related.granted_sender.includes(ctx.subject) ||
      this.related.room.traverse((r) => r.permits.message_delete_any(ctx)),

    edit: (ctx: Context): boolean =>
      this.related.granted_sender.includes(ctx.subject),

    react: (ctx: Context): boolean =>
      this.related.room.traverse((r) => r.permits.message_send(ctx)),
  }
}
