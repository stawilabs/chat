// Keto Namespace Configuration for Service Chat
// Using Ory Permission Language (OPL) - TypeScript-like DSL
//
// This file defines the authorization model for the chat service.
// It uses a Zanzibar-style relationship-based access control (ReBAC) model.
//
// NOTE: Class names are lowercase to match the namespace strings used in the
// Go authz middleware (e.g., NamespaceRoom = "room", NamespaceProfile = "profile").
// Keto uses the exact class name as the namespace identifier in API calls.

import { Namespace, Context } from "@ory/keto-namespace-types"

// profile namespace represents users/actors in the system
class profile implements Namespace {
  related: {
    self: profile[]
  }
}

// subscription namespace represents room memberships used as authz subjects
class subscription implements Namespace {}

// room namespace represents chat rooms with hierarchical roles
// Room relations use subscription subjects (subscription-based authz)
class room implements Namespace {
  related: {
    // Room owner has full control
    owner: (profile | subscription)[]
    // Admins can manage members and moderate content
    admin: (profile | subscription)[]
    // Members can participate in the room
    member: (profile | subscription)[]
    // Viewers have read-only access (e.g., for channel subscribers)
    viewer: (profile | subscription)[]
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

// message namespace represents individual messages with ownership
class message implements Namespace {
  related: {
    // The profile that sent this message
    sender: profile[]
    // The room this message belongs to (for permission inheritance)
    room: room[]
  }

  permits = {
    // View the message (inherits from room.view)
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
export { profile, subscription, room, message }
