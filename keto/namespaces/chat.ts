// Keto Namespace Configuration for Service Chat
// Using Ory Permission Language (OPL) - TypeScript-like DSL
//
// This file defines the authorization model for the chat service.
// It uses a Zanzibar-style relationship-based access control (ReBAC) model.
//
// Two-layer authorization:
//   Layer 1 — tenancy_access: Data access gate (can this caller access this partition?)
//   Layer 2 — chat_room/chat_message: Resource-level permissions (rooms & messages)
//
// NOTE: Class names are prefixed with "chat_" to avoid collisions with other
// services sharing the same Keto instance. Keto uses the exact class name as
// the namespace identifier in API calls, so these must match the Go constants
// (e.g., NamespaceRoom = "chat_room", NamespaceProfile = "chat_profile").

import { Namespace, Context } from "@ory/keto-namespace-types"

// profile_user is the platform-wide user identity namespace, shared across all services.
class profile_user implements Namespace {}

// tenancy_access gates data access per tenant/partition (Layer 1).
// "member" = regular user, "service" = service bot (system_internal role).
class tenancy_access implements Namespace {
  related: {
    member: profile_user[]
    service: profile_user[]
  }
}

// chat_profile namespace represents users/actors in the chat system
class chat_profile implements Namespace {
  related: {
    self: chat_profile[]
  }
}

// chat_subscription namespace represents room memberships used as authz subjects
class chat_subscription implements Namespace {}

// chat_room namespace represents chat rooms with hierarchical roles
// Room relations use subscription subjects (subscription-based authz)
class chat_room implements Namespace {
  related: {
    // Room owner has full control
    owner: (chat_profile | chat_subscription)[]
    // Admins can manage members and moderate content
    admin: (chat_profile | chat_subscription)[]
    // Members can participate in the room
    member: (chat_profile | chat_subscription)[]
    // Viewers have read-only access (e.g., for channel subscribers)
    viewer: (chat_profile | chat_subscription)[]
  }

  permits = {
    // View room content and history
    view: (ctx: Context): boolean =>
      this.related.viewer.includes(ctx.subject) ||
      this.related.member.includes(ctx.subject) ||
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject),

    // Send messages to the room
    send_message: (ctx: Context): boolean =>
      this.related.member.includes(ctx.subject) ||
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject),

    // Delete any message in the room (moderation)
    delete_any_message: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject),

    // Update room metadata (name, description, etc.)
    update: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject),

    // Delete the room entirely
    delete: (ctx: Context): boolean =>
      this.related.owner.includes(ctx.subject),

    // Add or remove members from the room
    manage_members: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject),

    // Change member roles (promote/demote)
    manage_roles: (ctx: Context): boolean =>
      this.related.owner.includes(ctx.subject),
  }
}

// chat_message namespace represents individual messages with ownership
class chat_message implements Namespace {
  related: {
    // The profile that sent this message
    sender: chat_profile[]
    // The room this message belongs to (for permission inheritance)
    room: chat_room[]
  }

  permits = {
    // View the message (inherits from chat_room.view)
    view: (ctx: Context): boolean =>
      this.related.room.traverse((r) => r.permits.view(ctx)),

    // Delete the message (sender or room admin/owner)
    delete: (ctx: Context): boolean =>
      this.related.sender.includes(ctx.subject) ||
      this.related.room.traverse((r) => r.permits.delete_any_message(ctx)),

    // Edit the message (only sender)
    edit: (ctx: Context): boolean =>
      this.related.sender.includes(ctx.subject),

    // React to the message (anyone who can send messages to the room)
    react: (ctx: Context): boolean =>
      this.related.room.traverse((r) => r.permits.send_message(ctx)),
  }
}

// Export namespaces for Keto to use
export { profile_user, tenancy_access, chat_profile, chat_subscription, chat_room, chat_message }
