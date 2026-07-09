# Handoff — Baby Tracker MVP Prototype

**From:** Paco (vibe-coded with Claude Code) · **To:** Senior dev · **Date:** 2026-07-09

## Why this exists

This repo is a **SwiftUI prototype**, not production code. It was built to explore
what the Moonboon baby-tracking experience should feel like, iterating fast with
AI-assisted coding ("vibecoding"). The proposed workflow going forward:

> **Paco does ~90% of the exploration/first-draft in prototypes like this;
> you refine the winning direction into production-quality code.**

Your job with this handoff is *not* to productionize this repo. It's to understand
**what was tried, what stuck, and how the AI implemented it** — so you can judge
what's portable and define the refinement workflow with me.

## Evolution (each iteration is a commit on the archive branch `feat/science-driven-simplification`)

| Commit | What it explored | Verdict |
|---|---|---|
| `v1` | Liquid Glass UI, adaptive bottom session bar (pill expands during active nap) | Session pill concept **kept** through every iteration |
| `v2` | Data-dense timeline: daily rings, night-wakes card, activity feed, custom icons | Too dashboard-y; most of it later cut |
| `v3` | Stats pills, iOS Live Activities, daily report, event deletion, header redesign | Live Activity concept validated; stats overload rejected |
| `v4` | "Science-driven simplification" — stripped anxiety-inducing metrics, fewer numbers, more signal | Key product insight: **less is more** for tired parents |
| `v5` | Napper-app-style structure: Schedule (circular clock + predictions), Trends, Sounds, You tabs | Competitor teardown; circular clock + nap prediction worth keeping conceptually |
| `v6` | **Current: MVP Home** — single screen from the Figma MVP vision (node 989:4711): devices, latest events, track sheet | This is the direction to look at |

The rejected iterations are as informative as the final one — they live on the
archive branch `feat/science-driven-simplification` (each version commit is
runnable: `git checkout <commit>`), **not** here. This branch is a single
squashed commit containing only the v6 direction, so the diff you review is
exactly what matters.

## Current state (v6): what to actually look at

The whole app is 4 view-layer files + state + theme:

- `BabyTracker/Views/Home/MVPHomeView.swift` — the whole MVP screen:
  header, devices section (device cards + add-device sheet), latest-events feed,
  floating bottom bar (nap pill + track button), `MVPTrackSheet` for logging events.
- `BabyTracker/State/SessionManager.swift` — active nap/bedtime session state.
- `BabyTracker/State/TimelineStore.swift` — in-memory event store (seeded with mock data).
- `BabyTracker/Theme/Moonboon{Colors,Typography}.swift` — token names mirror the design system (`moonCreme`, `moonOlive`, `moonApricot`, Kepler font).
- `BabyTracker/Views/Timeline/SleepTrackingScreen.swift` — full-screen active-nap view.
- `SleepActivityWidget/` — Live Activity (lock screen / Dynamic Island) stub.

## Validated vs. speculative

**Confident in (UX-validated by iteration):**
- Floating bottom bar: persistent `+` track button, nap pill appearing only during active session
- Single-screen home over tab sprawl
- Devices as cards with connect flow
- 2-tap event logging via bottom sheet

**Speculative / placeholder:**
- All device state (`MVPDevice` is hardcoded, one device, fake status — no BLE/real connectivity)
- Nap prediction & circular clock (v5 `ScheduleTab`, see commit history) — concept only, fake algorithm
- Live Activity — compiles, minimal
- Voice memos, nap reminders — stubs

**Parked (not in scope for this handoff):**
- Empty-state / fresh-account onboarding (add-device empty state, "track your first
  event", genesis row) — preserved on branch `parked/empty-state`; we'll iterate on
  it separately before it enters the workflow.

## Known gaps (deliberate — this is a prototype)

- **No persistence** — everything is in-memory `@Observable` stores; app restart wipes state
- **No tests**, no CI, no error handling, no accessibility pass
- Image sizing in device cards uses magic-number offsets to match Figma
- One 550-line view file; production would decompose
- **The production Moonboon app is Flutter** — nothing here is drop-in; it's a spec-by-example. The Moonboon design-system tokens used here map 1:1 to the Flutter app's tokens.

## The ask (explicit)

1. **Watch the 30-min walkthrough** (agenda below) or do it live with me.
2. Assess: which validated concepts above are worth building into the real Moonboon app, and what's the right architecture for them there (state, persistence, device layer)?
3. Propose the **vibecode → refine workflow**: how should I hand you prototypes so refinement is cheap? (Branch conventions, what a "done" prototype includes, how you flag anti-patterns back to me so my prompts improve.)
4. Comment inline on the draft PR — especially where the AI's implementation would *not* survive production (patterns to ban early).

## Walkthrough agenda (30 min)

1. **(5m)** Run the app in the simulator — core flow: track an event → start nap → nap pill → sleep screen → end nap.
2. **(5m)** The story: flip through the v1→v6 commits on `feat/science-driven-simplification`, what each iteration taught us.
3. **(10m)** Code tour: `MVPHomeView`, `SessionManager`, `TimelineStore`, theme tokens — how the AI structured it when prompted for "production-minded" code.
4. **(5m)** What's fake: devices, predictions, persistence.
5. **(5m)** Discuss the workflow ask (#3 above).

## Running it

Open `BabyTracker.xcodeproj`, build the `BabyTracker` scheme for an iOS simulator
(built against iOS 26 SDK / Liquid Glass APIs — needs recent Xcode).
