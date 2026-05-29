# Production Readiness Hardening — Master Design

**Date:** 2026-05-29
**Branch:** `hardening/production-readiness`
**Status:** Approved (decomposition & sequencing)

## Context

A full backend (Go) + frontend (Flutter) audit surfaced **25 issues (14 critical, 11 high)**.
The system is NOT production-ready. This effort resolves **all** of them (P0+P1+P2),
plus finalizes the already-started TimescaleDB messaging integration.

User decisions:
- **E2EE:** full rebuild (Olm-wrapped session distribution), landed last as its own sub-project.
- **Scope:** everything (P0+P1+P2).
- **Durability:** transactional outbox + idempotency keys.
- **Delivery:** single long-lived branch, one workstream at a time, TDD, verified
  commits per task. User reviews each workstream plan before execution.

Cross-cutting principle: lean-but-scalable from the onset; track latest stable deps.

## TimescaleDB note

The messaging layer **already targets TimescaleDB**: `room_events` is configured as a
hypertable in `apps/default/service/models/hypertables.go` (24h chunks, compress after
7d, segment by `partition_id,room_id`, retained forever) and `ensureHypertables` runs at
startup. The work is to **finalize and harden** it, not introduce it.

## Workstreams & sequencing

### Phase 1 — Backend foundation
- **WS-A · AuthZ & tenancy** — cross-room IDOR (room-scope removal), last-owner guard,
  internal-role `Source` binding, role-string validation, drop hardcoded `SystemAccessID`,
  RLS defense-in-depth (frame fail-open tracked as a coordinated dependency change).
- **WS-C · TimescaleDB finalization** — decouple `ensureHypertables` from normal boot;
  zero-downtime + dedup-safe migrations (`CONCURRENTLY`, dedup CTE); resolve duplicate
  subscription-index definition; history ordering/pagination correctness under composite
  PK; soft-delete on compressed chunks; reject non-xid client event IDs.
- **WS-B · Message durability** — transactional outbox (+ relay/poller), idempotency keys
  with unique constraint, content/`ParentId`/payload validation.

### Phase 2 — Backend pipeline & operability
- **WS-D · Delivery pipeline** — idempotent consumers, broker-native retry backoff,
  fan-out batching + surface 100k drop, DLQ persistence, opportunistic replay trim.
- **WS-E · Operability** — readiness `frame.Checker` (DB/queue/cache), trace/correlation
  across queue hops, delivery-latency histogram, graceful-shutdown flush, gateway pool
  defaults + utilization gauge, server-side ping/read-deadline.

### Phase 3 — Frontend foundation
- **WS-I · Release safety** — fail build on missing signing key, R8/shrink + Dart
  obfuscation, wire `AppLogger`→Sentry, unpin dev deps / de-fork sentry.
- **WS-G · Client durability & sync** — fix `authExpired` (move out of `finally`),
  `ack.hasError()`/empty-`eventId` checks in all send paths, cross-isolate job claim +
  DB-unique dedup, upsert-room-before-event, gap detection + history backfill, real Drift
  migrations + tests.
- **WS-J · Client correctness/perf** — release camera/mic on dispose, Riverpod stream-leak
  fix, bounded chat pagination, contact-sync off main isolate, deep-link/notification nav.

### Phase 4 — Frontend security
- **WS-H · At-rest & transport** — SQLCipher, cert pinning, native `FLAG_SECURE`,
  notification `roomId` validation, log redaction, `allowBackup=false` + iOS ATS.
- **WS-K · E2EE rebuild** — Olm-wrapped (`m.room_key`) session distribution, consistent
  Curve25519 senderKey, key storage/verification, fail-closed (no silent plaintext).

Every phase boundary is a shippable, strictly-safer state.

## Per-workstream cycle

Each workstream: focused spec section → plan (checkbox tasks) → TDD execution →
`go test -race ./...` / `flutter test` + build → commit per task. The audit findings
(with file:line) are the acceptance criteria.
