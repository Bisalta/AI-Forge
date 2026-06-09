# Verification Guide

## Purpose

Use this document to choose the right verification path for a task without rediscovering test commands or debug workflows.

This is a curated guide for:
- Fast local checks
- Integration validation
- End-to-end validation
- Manual smoke testing

Use the cheapest verification that can detect the risk introduced by the task.

---

## ⚠️ Template Notice

**This file is a skeleton. Fill it in before starting development.**

Replace every `[PLACEHOLDER]` section with the commands and paths specific to your project.

---

## Verification Strategy

Prefer this order:

1. Unit tests for pure logic changes
2. Integration tests for multi-layer or API behavior
3. End-to-end tests for real user flows
4. Manual smoke checks only when automated tests are too indirect

Do not default to E2E for every change.

---

## Quick Reference

### I changed pure business logic

```bash
# [Replace with your unit test command]
# Example: npm run test:unit
[PLACEHOLDER]
```

### I changed API endpoints or services

```bash
# [Replace with your integration test command]
# Example: npm run test:integration
[PLACEHOLDER]
```

### I changed UI components

```bash
# [Replace with your frontend test command]
# Example: npm run test -- --testPathPattern=components
[PLACEHOLDER]
```

### I changed end-to-end flows

```bash
# [Replace with your E2E test command]
# Example: npx playwright test
[PLACEHOLDER]
```

---

## Recommended Commands by Goal

### Run all tests

```bash
[PLACEHOLDER]
```

### Run tests for a specific feature

```bash
[PLACEHOLDER]
```

### Verify the app locally

```bash
# Start dev server
[PLACEHOLDER]

# Expected: app available at http://localhost:[PORT]
```

### Check types

```bash
[PLACEHOLDER]
# Example: npx tsc --noEmit
```

### Check linting

```bash
[PLACEHOLDER]
# Example: npm run lint
```

---

## Manual Smoke Checks

### Verify the main user flow

[Describe the steps to manually verify the primary user flow]

1. [Step 1]
2. [Step 2]
3. [Step 3]

### Verify an API endpoint

```bash
# [Replace with your curl/httpie example]
curl -X POST http://localhost:[PORT]/api/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{ [payload] }'
```

---

## Anti-patterns

Do not:
- Use E2E as the first and only debugging tool
- Trust manual tests as the only verification before merging
- Skip tests because "it's a small change"
