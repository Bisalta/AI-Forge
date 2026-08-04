---
name: enrich-user-story
description: Turn a rough task or idea into a decision-closed, senior-reviewable requirement by asking structured questions grounded in the existing codebase. Only draft the final artifact after all key decisions are resolved and the user confirms.
---

# Close Requirement

## Purpose

Help the user transform a vague task or idea into a **decision-closed, technically clear requirement**.

This artifact must be understandable by a senior engineer and serve as input for Spec-Driven Development (SDD) planning.

Do not optimize for wording.  
Optimize for **clarity, completeness, and closed decisions**.

---

## Context

You MUST read the following file before asking any questions:

SDD/docs/doc_architecture.md

If you cannot access or read this file, stop and inform the user. (If the plugin's `/sdd-init` command is available, suggest running it to bootstrap this file instead of writing it by hand.)

You SHOULD also read the following file if it exists — it is optional, not blocking:

docs/foundation/01-prd.md

This is the project's Product Requirements Document (produced by a separate day-zero tool, when the team uses one). If present, use it to ground the **actor and usage context** and **success criteria** dimensions in real personas, jobs-to-be-done, and product metrics — not just in code shape. If it does not exist, proceed exactly as before: ground everything in `SDD/docs/doc_architecture.md` and the codebase, with no product-level anchor for those two dimensions.

---

## Behavior

### 1. Understand the request

Read the input and briefly identify:
- what the user wants
- what problem it solves
- what is unclear

---

### 2. Ask clarifying questions

Ask questions in the same language used by the user.

Your goal is NOT to explore — it is to **force decisions**.

Rules:
- tone: conversational
- ask as many questions as needed to fully close decisions (no artificial limit)
- each question must resolve a concrete decision
- avoid redundant or overlapping questions
- prefer trade-off questions (A vs B) over open-ended ones
- whenever possible, include a suggested default

---

### Mandatory decision dimensions

Your questions MUST collectively cover these dimensions:

1. Solution shape  
   (e.g. new endpoint vs extending existing behavior)

2. Expected output  
   (what must be returned and in what form)

3. Behavior  
   (normal flow, edge cases, and failure scenarios)

4. Actor and usage context  
   (who uses this and why — if `docs/foundation/01-prd.md` exists, anchor this in its real personas/jobs-to-be-done instead of guessing)

5. Scope boundaries  
   (what is in scope vs out of scope)

6. Success criteria  
   (how we know this is correctly implemented — if `docs/foundation/01-prd.md` exists, align with its stated success metrics/KPIs where relevant)

If any of these is unclear, you MUST ask about it.

- **SEO (solo si el scope incluye frontend)**: son dos decisiones separadas, no una.
  1. **¿Hay frontend en el alcance?** Si sí → `seo.applies: true` (activa el Tier Universal: perf/accesibilidad/HTML semántico, aplica también a apps internas, paneles admin y áreas autenticadas). Si no hay front → `seo.applies: false` y omitís el bloque.
  2. **¿Ese frontend es público indexable por buscadores?** Si sí → `seo.indexable: true` (activa además el Tier Indexable) y confirmá idiomas/locales. Si es interno/autenticado → `seo.indexable: false` (igual conserva el Tier Universal).
  No asumas — preguntá ambas.

---

### Code-grounded suggestions (CRITICAL)

Before proposing any suggested default:

- inspect the existing codebase when relevant
- identify current patterns, endpoints, naming conventions, and data structures
- align with the architecture described in `SDD/docs/doc_architecture.md`

Suggested defaults must be grounded in:

- existing endpoints or API structure  
- current request/response contracts  
- existing services or flows  
- real constraints visible in the codebase  

Avoid generic suggestions if code-based evidence is available.

When suggesting defaults:

- explain briefly why the recommendation fits the current system
- when possible, reference specific files, routes, or components

### Product-grounded suggestions (only if a PRD exists)

If `docs/foundation/01-prd.md` was found, use it as a second grounding source — orthogonal to the codebase — for the **actor** and **success criteria** dimensions specifically:

- pull the actual persona(s) and their jobs-to-be-done instead of inferring an actor from code
- pull the stated success metrics/KPIs when the task's success criteria overlaps with them
- when possible, reference the specific PRD section (e.g. "per PRD §4 Target users")

If no PRD exists, do not ask the user to write one — this skill only closes the current requirement, it does not scaffold project-level docs. Proceed with code-grounded suggestions alone, as before.

---

### 3. Iterate until decisions are closed

- If answers are incomplete → ask again  
- If something is ambiguous → ask again  
- Do not proceed while decisions remain open  

---

### 4. Confirm before writing

When all key decisions are resolved, ask:

"Everything looks clear now. Do you want me to draft the final requirement?"

Do not write it yet.

---

### 5. Draft only after confirmation

Only if the user explicitly confirms, write the final artifact.

---

## Output

### If there are still open decisions

Respond in the same language as the user:

## Understanding

<what you believe the user wants>

## Questions

1. <question>

   Suggested default:
   <recommended option grounded in code and architecture>

2. <question>

   Suggested default:
   <recommended option grounded in code and architecture>

---

### If everything is clear but not confirmed

Respond in the same language as the user:

## Status

All key decisions are clear and no relevant ambiguity remains.

## Confirmation

Do you want me to draft the final requirement?

---

### If confirmed

Respond in the same language as the user:

# Requirement: <clear title>

## Story

As a <actor>,  
I want <capability>,  
so that <outcome>.

## Objective

<what this enables>

## Context

<problem and why it matters>

## Scope

### In scope

- <item>
- <item>

### Out of scope

- <item>
- <item>

## Closed decisions

- <decision>
- <decision>

## SEO
<!-- Incluir solo si el scope tiene frontend. Si no hay front, omitir esta sección. -->
- applies: <true|false>     # hay frontend con SEO en alcance
- indexable: <true|false>   # es público indexable (activa tier Indexable)
- locales: []               # vacío = monolingüe; ≥2 entradas activan hreflang

## Expected behavior

- <normal behavior>
- <edge case behavior>
- <failure behavior>

## Expected output

- <what is returned and in what shape>

## Success criteria

- <observable condition>
- <validation outcome>

---

## Rules

- Do not write code  
- Do not assume missing decisions  
- Do not draft if decisions remain open  
- Always respond in the user's language  
- Optimize for clarity, not verbosity  
