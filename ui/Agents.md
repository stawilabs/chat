# Multi-Agent Development Practices

This document establishes the development workflow, quality gates, and collaboration practices for the Chat application development team.

---

## Table of Contents

1. [Branch Strategy](#branch-strategy)
2. [Issue Workflow](#issue-workflow)
3. [Pull Request Process](#pull-request-process)
4. [Quality Gates](#quality-gates)
5. [Code Review Guidelines](#code-review-guidelines)
6. [Testing Requirements](#testing-requirements)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Sprint Execution](#sprint-execution)
9. [Issue Tracking](#issue-tracking)
10. [Communication Protocols](#communication-protocols)

---

## Branch Strategy

### Branch Naming Convention

This project uses trunk-based development with `main` as the single integration branch.

```
main                           # Protected, production-ready code
├── feature/MSG-EDIT-001       # Feature branches (from main)
├── feature/SEC-E2E-001
├── bugfix/MSG-EDIT-001-fix    # Bug fix branches (from main)
├── hotfix/critical-fix        # Emergency production fixes
└── release/v1.0.0             # Release branches
```

### Branch Rules

| Branch | Protection | Merge Strategy |
|--------|------------|----------------|
| `main` | Protected, requires PR | Squash merge |
| `feature/*` | None | Rebase from main |
| `bugfix/*` | None | Rebase from main |
| `hotfix/*` | None | Cherry-pick to main |
| `release/*` | None | Merge to main |

### Parallel Development with Worktrees

For efficient parallel development while waiting for CI checks, use git worktrees:

```bash
# Create worktree directory structure
mkdir -p ../chat-worktrees

# Add worktree for a new feature
git worktree add ../chat-worktrees/msg-delete feature/MSG-DEL-001

# List active worktrees
git worktree list

# Remove worktree after PR is merged
git worktree remove ../chat-worktrees/msg-delete
```

**Worktree Guidelines:**
- Maximum 10 concurrent worktrees to manage complexity
- Each worktree = one feature branch = one PR
- Always pull main before creating new worktrees
- Remove worktrees promptly after PR merge to avoid conflicts
- Avoid overlapping file changes between concurrent features
- Prioritize non-conflicting work streams for parallel execution

**Example Parallel Workflow:**
```
main repo:     Monitoring PRs, creating new worktrees
├── worktree1: feature/MSG-DEL-001 (Messaging)
├── worktree2: feature/NOTIF-PUSH-001 (Notifications)
└── worktree3: feature/CALL-TURN-001 (Calls)
```

### Creating a Feature Branch

```bash
# Always start from latest main
git checkout main
git pull origin main

# Create feature branch with issue ID
git checkout -b feature/MSG-EDIT-001

# Make changes, commit frequently
git add -p  # Interactively stage changes
git commit -m "feat(messages): add edit message UI

- Add long-press menu with edit option
- Implement 15-minute edit window check
- Show (edited) indicator on edited messages

Refs: #3"

# Push and create PR
git push -u origin feature/MSG-EDIT-001
```

---

## Issue Workflow

### Issue States

```
┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌──────────┐
│ Backlog │ -> │ In Progress │ -> │ In Review   │ -> │  Done    │
└─────────┘    └─────────────┘    └─────────────┘    └──────────┘
                     │                   │
                     v                   v
              ┌─────────────┐    ┌─────────────┐
              │  Blocked    │    │  Changes    │
              │             │    │  Requested  │
              └─────────────┘    └─────────────┘
```

### Starting Work on an Issue

```bash
# 1. Assign yourself to the issue
gh issue edit <issue-number> --add-assignee @me

# 2. Add "in-progress" label
gh issue edit <issue-number> --add-label "status:in-progress"

# 3. Create feature branch
git checkout -b feature/<ISSUE-ID>

# 4. Link commits to issue
git commit -m "feat(scope): description

Refs: #<issue-number>"
```

### Completing an Issue

```bash
# 1. Create PR linking to issue
gh pr create --title "[<ISSUE-ID>] Feature Title" \
  --body "Closes #<issue-number>

## Summary
- What was implemented

## Test Plan
- How to verify"

# 2. PR merge will auto-close issue via "Closes #X"
```

---

## Pull Request Process

### PR Template

```markdown
## Summary
<!-- Brief description of changes -->

## Related Issue
Closes #<issue-number>

## Changes Made
- [ ] Change 1
- [ ] Change 2

## Test Plan
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Tests pass locally
- [ ] Documentation updated (if needed)
- [ ] No new warnings introduced
```

### Creating a PR

```bash
# Create PR with proper formatting
gh pr create \
  --title "[MSG-EDIT-001] Implement message editing" \
  --body "$(cat <<'EOF'
## Summary
Implements message editing functionality allowing users to edit sent messages within a 15-minute window.

## Related Issue
Closes #3

## Changes Made
- Added edit option to message long-press menu
- Implemented 15-minute edit window validation
- Added (edited) indicator on edited messages
- Created EditMessageSheet component
- Updated MessageRepository with updateMessage method

## Test Plan
- [x] Unit tests for MessageRepository.updateMessage
- [x] Widget tests for EditMessageSheet
- [x] Manual testing: edit message within window
- [x] Manual testing: edit blocked after 15 minutes

## Checklist
- [x] Code follows project style guidelines
- [x] Self-review completed
- [x] Tests pass locally
- [x] No new warnings introduced
EOF
)"

# Add appropriate labels
gh pr edit --add-label "WS1:Messaging,sprint:1"
```

### PR Size Guidelines

| Size | Lines Changed | Files | Action |
|------|---------------|-------|--------|
| Small | < 100 | < 5 | Ideal |
| Medium | 100-400 | 5-10 | Acceptable |
| Large | > 400 | > 10 | Split if possible |

### Review Feedback Policy

**CRITICAL RULE**: All PR review feedback must be addressed before proceeding to work on other issues.

```
┌─────────────────────────────────────────────────────────────┐
│  PR Created → Review Comments → Address ALL Feedback →      │
│  Wait for CI → Merge → THEN start next issue                │
└─────────────────────────────────────────────────────────────┘
```

**Why this matters:**
- Prevents accumulation of unresolved issues
- Ensures code quality before moving forward
- Maintains clean PR history
- Avoids context-switching overhead later

**When to proceed to next issue:**
- [ ] All review comments marked as resolved
- [ ] No pending "Changes Requested" status
- [ ] CI checks passing
- [ ] PR merged OR explicitly paused with documented reason

**If blocked by reviewer availability:**
1. Document the blocker in PR comments
2. Add `status:awaiting-review` label
3. Only then may you start a new issue
4. Return to complete the PR once feedback is received

---

## Quality Gates

### Pre-Merge Requirements

All PRs must pass these gates before merging:

```yaml
quality_gates:
  required:
    - lint: "flutter analyze --no-fatal-infos"
    - format: "dart format --set-exit-if-changed ."
    - tests: "flutter test --coverage"
    - build: "flutter build apk --debug"

  thresholds:
    test_coverage: 70%  # Minimum coverage
    max_warnings: 0     # No new warnings

  reviews:
    required_approvals: 1
    dismiss_stale: true
```

### Running Quality Checks Locally

```bash
# 1. Format code
dart format .

# 2. Run analyzer
flutter analyze

# 3. Run tests with coverage
flutter test --coverage

# 4. Check coverage threshold
lcov --summary coverage/lcov.info

# 5. Build to verify no compile errors
flutter build apk --debug
```

### Quality Gate Checklist

Before creating a PR, ensure:

- [ ] `dart format .` produces no changes
- [ ] `flutter analyze` has no errors or warnings
- [ ] `flutter test` passes all tests
- [ ] New code has test coverage
- [ ] No TODO comments without issue references
- [ ] No commented-out code
- [ ] No debug print statements
- [ ] API keys/secrets not hardcoded

---

## Code Review Guidelines

### For Authors

1. **Self-review first**: Read your own diff before requesting review
2. **Small PRs**: Keep changes focused and atomic
3. **Clear descriptions**: Explain the "why" not just the "what"
4. **Respond promptly**: Address feedback within 24 hours
5. **Don't take it personally**: Reviews improve code quality
6. **CRITICAL: Address all review feedback before moving on**: All PR review comments must be resolved before starting work on other issues. This ensures quality and prevents accumulation of technical debt. Do not leave comments unaddressed.

### For Reviewers

1. **Be constructive**: Suggest improvements, don't just criticize
2. **Be timely**: Review within 24 hours when possible
3. **Check these areas**:
   - Logic correctness
   - Edge cases handled
   - Error handling
   - Performance implications
   - Security considerations
   - Test coverage
   - Code style consistency

### Review Comments

Use these prefixes for clarity:

| Prefix | Meaning |
|--------|---------|
| `nit:` | Minor style issue, optional to fix |
| `suggestion:` | Improvement idea, not blocking |
| `question:` | Need clarification |
| `issue:` | Must be fixed before merge |
| `blocker:` | Critical issue, blocks merge |

Example:
```
issue: This could throw a null pointer exception if `user` is null.
Consider adding a null check:
```dart
if (user != null) {
  processUser(user);
}
```
```

---

## Testing Requirements

### Test Types

| Type | Location | Purpose | Coverage Target |
|------|----------|---------|-----------------|
| Unit | `test/unit/` | Business logic | 80% |
| Widget | `test/widget/` | UI components | 70% |
| Integration | `test/integration/` | Feature flows | Key paths |
| E2E | `integration_test/` | Full app | Critical paths |

### Test File Naming

```
lib/features/messages/data/message_repository.dart
test/unit/features/messages/data/message_repository_test.dart

lib/features/messages/ui/message_bubble.dart
test/widget/features/messages/ui/message_bubble_test.dart
```

### Writing Tests

```dart
// Unit test example
void main() {
  group('MessageRepository', () {
    late MessageRepository repository;
    late MockDatabase mockDb;

    setUp(() {
      mockDb = MockDatabase();
      repository = MessageRepository(mockDb);
    });

    test('updateMessage updates content and sets edited flag', () async {
      // Arrange
      final originalEvent = createTestEvent(id: '1', content: 'Hello');
      when(mockDb.getEvent('1')).thenAnswer((_) async => originalEvent);

      // Act
      await repository.updateMessage('1', 'Hello Updated');

      // Assert
      verify(mockDb.updateEvent(
        argThat(predicate((e) => e.edited == true && e.content == 'Hello Updated')),
      )).called(1);
    });
  });
}
```

### Coverage Requirements

```bash
# Generate coverage report
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Check coverage threshold (CI)
lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//'
# Must be >= 70
```

---

## CI/CD Pipeline

### Pipeline Stages

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze --no-fatal-infos

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - name: Check coverage
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 70% threshold"
            exit 1
          fi

  build-android:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --debug

  build-ios:
    needs: [lint, test]
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --debug --no-codesign

  build-web:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build web --release
```

### Status Checks

All PRs require these checks to pass:

| Check | Description | Required |
|-------|-------------|----------|
| `lint` | Code formatting and analysis | Yes |
| `test` | Unit and widget tests | Yes |
| `build-android` | Android APK builds | Yes |
| `build-ios` | iOS build (no signing) | Yes |
| `build-web` | Web build | Yes |
| `coverage` | >= 70% test coverage | Yes |

---

## Sprint Execution

### Sprint Structure

```
Sprint Duration: 2 weeks
├── Day 1-2: Sprint planning, issue assignment
├── Day 3-8: Development
├── Day 9: Feature freeze
├── Day 10: Testing & bug fixes
└── Day 11-14: Buffer, retrospective
```

### Daily Workflow

```bash
# Morning: Pull latest, check assigned issues
git checkout main && git pull
gh issue list --assignee @me --state open

# During work: Commit frequently
git add -p  # Stage specific changes
git commit -m "feat(scope): incremental progress

Refs: #<issue>"

# End of day: Push work
git push origin feature/<branch>
```

### Sprint 1 Issue Priority Order

Execute issues in this order (P0 first, then P1, then P2):

#### P0 - Critical (Must complete)
1. `#65` [DEVOPS-CICD-001] CI/CD Pipeline - Foundation for all work
2. `#63` [DEVOPS-ERROR-001] Error Tracking - Crash reporting
3. `#59` [TEST-UNIT-001] Unit Test Infrastructure - Testing foundation
4. `#3` [MSG-EDIT-001] Message Editing
5. `#4` [MSG-DEL-001] Message Deletion
6. `#11` [SEC-E2E-001] Enable E2EE by Default
7. `#12` [SEC-PIN-001] Certificate Pinning
8. `#18` [NOTIF-PUSH-001] Push Notifications
9. `#40` [SEARCH-MSG-001] Message Search
10. `#44` [CALL-TURN-001] TURN Server Configuration

#### P1 - High Priority
11. `#7` [MSG-READ-001] Read Receipts UI
12. `#8` [MSG-TYPE-001] Typing Indicators
13. `#10` [MSG-RETRY-001] Message Retry Enhancement
14. `#22` [NOTIF-BADGE-001] Badge Counts
15. `#24` [MEDIA-COMP-001] Media Compression
16. `#25` [MEDIA-THUMB-001] Thumbnail Generation
17. `#31` [GROUP-ADMIN-001] Group Admin Controls
18. `#36` [CONTACT-SYNC-001] Contact Sync
19. `#39` [CONTACT-PROFILE-001] Profile Editing
20. `#45` [CALL-QUALITY-001] Call Quality
21. `#49` [SET-PERSIST-001] Settings Persistence
22. `#50` [SET-THEME-001] Theme System
23. `#54` [PERF-CACHE-001] Image/Widget Caching
24. `#58` [PERF-STARTUP-001] Startup Optimization

#### P2 - Medium Priority
25. `#9` [MSG-DRAFT-001] Draft Messages
26. `#33` [GROUP-DESC-001] Group Description

---

## Issue Tracking

### Labels

| Label | Color | Description |
|-------|-------|-------------|
| `priority:P0` | Red | Critical - blocks release |
| `priority:P1` | Orange | High - core functionality |
| `priority:P2` | Yellow | Medium - important |
| `priority:P3` | Green | Low - nice to have |
| `WS1:Messaging` | Blue | Core Messaging work stream |
| `WS2:Security` | Red | Security & Privacy |
| `sprint:1` | Gray | Sprint 1 (Week 1-2) |
| `status:in-progress` | Purple | Currently being worked on |
| `status:blocked` | Black | Blocked by dependency |

### Issue Commands

```bash
# List your assigned issues
gh issue list --assignee @me

# List sprint 1 issues by priority
gh issue list --label "sprint:1,priority:P0"
gh issue list --label "sprint:1,priority:P1"

# Start working on issue
gh issue edit 3 --add-assignee @me --add-label "status:in-progress"

# View issue details
gh issue view 3

# Close issue via PR
# Include "Closes #3" in PR description
```

---

## Communication Protocols

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**
```
feat(messages): add message editing capability

- Implement long-press menu with edit option
- Add 15-minute edit window validation
- Show (edited) indicator on edited messages
- Preserve original content in database

Closes #3
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### PR Status

GitHub automatically tracks PR states (ready for review, changes requested, approved) through its built-in review system. Use labels only for supplemental metadata like sprint assignments and work streams.

### Blocking Issues

If blocked, immediately:

1. Add `status:blocked` label
2. Comment with blocker details
3. Tag relevant team members
4. Create dependent issue if needed

```bash
gh issue edit 3 --add-label "status:blocked"
gh issue comment 3 --body "Blocked by #11 - E2EE must be enabled first"
```

---

## Appendix: Quick Reference

### Common Commands

```bash
# Start new feature
git checkout main && git pull
git checkout -b feature/MSG-EDIT-001
gh issue edit 3 --add-assignee @me --add-label "status:in-progress"

# Quality checks
dart format .
flutter analyze
flutter test --coverage

# Create PR
gh pr create --title "[MSG-EDIT-001] Feature title" --body "Closes #3"

# View CI status
gh pr checks

# Merge when approved
gh pr merge --squash --delete-branch
```

### Definition of Done

A feature is "done" when:

- [ ] Code implemented and self-reviewed
- [ ] Unit tests written (>80% coverage for new code)
- [ ] Widget tests for new UI components
- [ ] All CI checks pass
- [ ] PR approved by reviewer
- [ ] No unresolved comments
- [ ] Documentation updated (if applicable)
- [ ] Issue closed via PR merge

---

*Last Updated: January 2026*
*Version: 1.0*
