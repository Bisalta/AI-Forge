---
name: project-foundation
description: >-
  Create (or back-fill) the six foundational documents every project should have
  from day zero: (1) Product Requirements Document (PRD), (2) Technical
  Requirements Document (TRD), (3) UI/UX Design Brief, (4) App Flow, (5) Backend
  Schema, and (6) Implementation Plan. Use when starting a NEW project, when the
  user asks to scaffold/define/write these foundational or "founding" docs (PRD,
  TRD, design brief, app flow, backend schema, implementation plan), or when an
  existing project lacks a clear definition and you need to derive these from the
  codebase. Works both greenfield (interview the user) and for an existing
  codebase (derive from the code, then confirm). Triggers: "PRD", "TRD",
  "documento de requerimientos", "brief de diseño", "app flow", "esquema del
  backend", "plan de implementación", "founding docs", "documentos fundacionales".
---

# Project Foundation — the six documents every project needs from day zero

You are setting up (or back-filling) the canonical definition of a software
project. The deliverable is **six living documents** that together answer *what
we're building, for whom, why, how, and in what order*. They are written once at
the start and kept updated as the project evolves — never a throwaway.

**Always write in the language the user is working in.** Detect it from the
conversation and match it (Spanish → Spanish docs, English → English, etc.). Keep
code, identifiers, and file paths verbatim.

## The six documents (and their dependency order)

Produce them in this order — each one draws on the ones before it:

| # | File | Document | Answers |
|---|------|----------|---------|
| 1 | `01-prd.md` | **Product Requirements Document (PRD)** | *What* & *for whom* & *why* — problem, users, features, success metrics |
| 2 | `02-trd.md` | **Technical Requirements Document (TRD)** | *How, technically* — architecture, stack, security, NFRs |
| 3 | `03-ui-ux-brief.md` | **UI/UX Design Brief** | *How it looks & feels* — IA, design system, a11y, tone |
| 4 | `04-app-flow.md` | **App Flow** | *How the user moves through it* — end-to-end flows, navigation, state machines |
| 5 | `05-backend-schema.md` | **Backend Schema** | *How data is modeled* — entities, relations, constraints, tenancy |
| 6 | `06-implementation-plan.md` | **Implementation Plan** | *In what order we build it* — phases, tasks, milestones, risks |

Dependency chain: **PRD → TRD → (UI/UX Brief ∥ App Flow ∥ Backend Schema) →
Implementation Plan.** The PRD is the source of truth; the TRD frames the
technical shape; docs 3–5 elaborate specific dimensions and can be drafted in
parallel once 1–2 exist; the implementation plan sequences everything.

## Where to write them

Default output directory: **`docs/foundation/`** (create it). Write the six
numbered files there plus a `README.md` index that links them and states the
"last updated" date. If the repo already has a docs convention, place them to fit
it and link from the existing docs index. Respect the argument-hint overrides.

> If the project already has overlapping docs (an architecture plan, a backlog, a
> go-to-market, ADRs), **consolidate — don't duplicate.** Reference and absorb
> them; note in each new doc which existing files it supersedes or draws from, so
> there is a single source of truth.

> **Interop with `sdd-flow`** (if that plugin is also installed): `sdd-flow`'s
> `enrich-user-story` skill reads `docs/foundation/01-prd.md` when present to
> ground actor/success-criteria decisions, and its `sdd-plan` skill reads
> `docs/foundation/06-implementation-plan.md` to check scope against the
> declared roadmap. `sdd-flow`'s own `/sdd-init` command also references
> `02-trd.md`/`05-backend-schema.md` instead of duplicating them into its
> `SDD/docs/doc_architecture.md`. None of this is required — `project-foundation`
> works standalone — but writing to the default `docs/foundation/` path keeps
> that interop working for free.

## Process

### Step 0 — Detect mode

- **Greenfield** (no code yet, or the user is defining a new idea): you must
  *interview* the user for the product substance before writing. You cannot invent
  a product vision.
- **Existing project** (there is a codebase): *derive* the facts from the code and
  existing docs first (read the schema, routes, modules, package manifests, ADRs),
  then write the docs, then flag anything you had to assume for the user to
  confirm. Use parallel exploration subagents for breadth (schema, frontend
  screens, API/modules, existing docs) rather than reading everything yourself.

### Step 1 — Gather context

**Greenfield — ask a focused round of questions** (don't over-ask; group them).
The essentials you need before writing:

- Product: what is it, who is it for, what problem does it solve, why now?
- Users/personas and their primary jobs-to-be-done.
- The core MVP capabilities vs. explicitly-later.
- Business model / how it makes money (if any), and target market/verticals.
- Platforms (web, mobile, both), and any hard technical constraints or existing
  preferences (stack, cloud, auth, budget, team, timeline).
- Success metrics — how we'll know it works.

**Existing project — derive, then confirm.** Extract: the domain model (DB
schema), the feature set (routes/screens + API modules), the stack and versions
(package manifests, Dockerfiles, CI), the multi-tenancy/security model, existing
product/planning docs and ADRs. Then write, and end with an "Assumptions to
confirm" list.

### Step 2 — Write the six documents

Follow the templates below. Each document must be **specific and concrete** — real
names, real entities, real endpoints, real screens. No vague filler. Every doc
starts with a short header block:

```
# <Document name> — <Project>
_Status: Draft · Owner: <who> · Last updated: <date> · Related: [PRD](01-prd.md) …_
```

Cross-link the documents to each other (e.g., the TRD's data section links to the
Backend Schema; the App Flow links to screens named in the UI/UX Brief).

### Step 3 — Index + close out

Write `docs/foundation/README.md` linking all six with a one-line summary each.
Then report to the user: what was created, what you assumed (existing-project
mode), and the open questions worth resolving next.

---

## Templates

Use these as the section skeleton for each document. Add or trim sections to fit
the project, but keep the intent. Prefer tables, bullet lists, and small diagrams
(Mermaid or ASCII) over walls of prose.

### 1. PRD — `01-prd.md`

1. **Summary / one-liner** — what this product is in two sentences.
2. **Problem & motivation** — the pain, who feels it, why solve it now.
3. **Goals & non-goals** — what success looks like; what we explicitly won't do.
4. **Target users & personas** — each persona: role, context, needs, pains.
5. **Jobs-to-be-done / user stories** — "As a X, I want Y, so that Z."
6. **Features / requirements** — prioritized (MVP / Next / Later). For each: a
   short description and **acceptance criteria**. Use a table with priority.
7. **Success metrics / KPIs** — the numbers that prove it works.
8. **Assumptions, constraints & dependencies.**
9. **Out of scope** — named explicitly to prevent scope creep.
10. **Open questions** — decisions still to make.

### 2. TRD — `02-trd.md`

1. **Architecture overview** — a diagram (Mermaid) + a paragraph. Components and
   how they talk.
2. **Tech stack** — languages, frameworks, DB, infra — each with a one-line
   rationale.
3. **System components** — each service/app/package: responsibility, boundaries.
4. **Data model summary** — high level; link to `05-backend-schema.md` for detail.
5. **APIs & contracts** — the surfaces (internal, public), auth for each, the
   shared-contract mechanism, versioning.
6. **AuthN / AuthZ** — identity provider, token model, roles/permissions,
   multi-tenancy isolation strategy (and how it's enforced, e.g. RLS).
7. **Non-functional requirements** — performance, scalability, availability,
   observability, i18n, accessibility targets — with concrete targets.
8. **Infrastructure & environments** — dev/stage/prod, deployment, secrets,
   the cloud/hosting path.
9. **Testing strategy** — unit / integration / e2e / contract, and CI gates.
10. **Risks & mitigations**, and **key technical decisions** (link ADRs).

### 3. UI/UX Design Brief — `03-ui-ux-brief.md`

1. **Design principles** — 3–6 principles this product's UI commits to.
2. **Brand & voice** — look/feel, tone, personality.
3. **Users & context of use** — device, environment, frequency, expertise.
4. **Information architecture** — the navigation map / sitemap; primary nav
   groupings and the app shell.
5. **Key screens & states** — the important screens, each with its purpose and
   its empty / loading / error / success states.
6. **Design system** — color tokens, typography scale, spacing, radius,
   elevation; core components (buttons, inputs, selects, dialogs/drawers, nav);
   iconography; **theming (light/dark)**.
7. **Accessibility** — contrast, focus management, keyboard, semantics, the
   standard targeted (e.g. WCAG AA).
8. **Responsive & platforms** — breakpoints; web vs mobile behavior.
9. **Internationalization & content** — languages, locale detection, copy tone,
   number/date/currency formatting.
10. **Interaction & motion patterns**, and **deliverables/references** (link
    design artifacts, Figma, screenshots).

### 4. App Flow — `04-app-flow.md`

1. **Actors / roles** — who moves through the app.
2. **Entry points** — how users arrive (sign-up, invite, public link, deep link).
3. **Core end-to-end flows** — for each primary journey (onboarding, the core
   task, and any public/customer flow): a numbered step sequence **and** a
   Mermaid flow/sequence diagram. Name the actual screens.
4. **Navigation map** — screen-to-screen graph (Mermaid).
5. **State machines** — lifecycles that matter (e.g. an order/booking/status
   workflow) as a Mermaid `stateDiagram`.
6. **Role-based differences** — where the flow diverges by role/permission.
7. **Edge cases & error flows** — empty states, failures, retries, conflicts.

### 5. Backend Schema — `05-backend-schema.md`

1. **Overview** — the domain in a paragraph + an ER diagram (Mermaid `erDiagram`).
2. **Entities** — grouped by domain area. For each entity: purpose, key fields
   (name · type · notes), and constraints. Use a table per entity or per group.
3. **Relationships** — the FK/relation graph; many-to-many join tables.
4. **Enums / controlled vocabularies** — each enum and its values.
5. **Multi-tenancy & data isolation** — how tenant scoping works and how it's
   enforced at the data layer.
6. **Indexes & constraints** — uniqueness, exclusion/no-overlap, performance
   indexes, and why.
7. **Migrations & data lifecycle** — migration approach, seed/demo data,
   retention/soft-delete.

### 6. Implementation Plan — `06-implementation-plan.md`

1. **Approach & phasing** — the milestones/phases and the logic of the sequence.
2. **Workstreams → tasks** — break each phase into concrete tasks with IDs
   (reuse the project's task-ID scheme if one exists, e.g. `IBW-NNNN`), each with
   a one-line scope and its dependencies.
3. **Dependency & sequencing view** — what blocks what (a table or Mermaid
   `gantt`/graph).
4. **Environments & release strategy** — branch/promotion model, how work ships
   to dev → stage → prod.
5. **Quality gates** — the tests/reviews/checks required to advance.
6. **Risks, unknowns & mitigations.**
7. **Definition of done** — per task and per milestone.
8. **Rough timeline / estimates** (if the user wants sizing).

---

## Quality bar

- **Concrete over generic.** A reader should learn this specific product, not a
  template. Name real entities, screens, endpoints, roles.
- **Consistent.** The same terms mean the same thing across all six docs. A
  feature in the PRD maps to a flow in the App Flow, a screen in the UI Brief, and
  tasks in the Implementation Plan.
- **Traceable.** Cross-link. Requirements → design → schema → tasks should be
  followable.
- **Honest.** In existing-project mode, separate observed facts from assumptions,
  and surface the assumptions for confirmation.
- **Living.** Each doc carries a status and last-updated date and is meant to be
  edited, not frozen.

## Reusing this for every new project

This skill is the standard kickoff for any project. When a new repo starts, run it
first (greenfield mode) so the six documents exist before code does. For an
existing project without them, run it in existing mode to back-fill and establish
the definition. Keep the six docs under `docs/foundation/` as the project's
canonical definition, and update them as the product evolves.
