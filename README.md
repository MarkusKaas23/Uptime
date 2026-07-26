# Uptime 🧍

> A macOS menu bar app that helps desk workers build a sustainable sit/stand habit — with a character that evolves from cave-dweller to posture champion as you improve.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![Status](https://img.shields.io/badge/status-in%20development-yellow)

---

## What It Does

Uptime lives quietly in your menu bar and counts down to your next sit/stand switch. Click the icon to see your status, toggle your state, and track your weekly progress — all without ever opening a full app window.

The twist: your **posture character** evolves based on how consistently you hit your weekly goal. Start as a hunched cave-dweller. Graduate to office slouch, upriser, and finally — posture champion, arms raised in victory.

```
Menu bar:  🧍 12m          ← character icon + countdown

Popover:   ┌──────────────────────┐
           │  🧍 Standing  12:34  │
           │  [ I'm Now Sitting ] │
           │  ─────────────────── │
           │  😑 The Office Slouch│
           │  ████████░░  4/5 days│
           └──────────────────────┘
```

---

## The Science

No arbitrary goals — the cycles are based on published research:

| Level | Cycle | Standing/day (8h) | Basis |
|---|---|---|---|
| Starter | 50 min sit → 10 min stand | ~1.3h | WHO baseline |
| Standard | 30 min sit → 15 min stand | ~2.6h | Callaghan (2025) sweet spot |
| Intermediate | 25 min sit → 15 min stand | ~3h | 30:15 protocol |
| Advanced | 20 min sit → 10 min stand + stretch | ~3.3h | Full ergonomics protocol |

Sources:
- [BeUpstanding — Optimal sit-stand ratio (2025)](https://beupstanding.blog/2025/11/what-is-the-optimal-sit-stand-ratio-for-workers-with-back-pain/)
- [Phys.org — Sit-stand sweet spot boosts productivity (2025)](https://phys.org/news/2025-11-ratio-sweet-boost-office-productivity.html)
- [UCLA Health — Rest Breaks](https://www.uclahealth.org/safety/ergonomics/office-ergonomics/rest-breaks)

---

## Character Stages

Progress is a persistent **level**, not a weekly score — it only ever goes up. Each finished
day awards XP scaled to how close you got to your standing goal, with a streak bonus (up to
+30% at a 10-day streak). The weekly bars still show *this week's* consistency, but a rough
week no longer de-levels your character — only new days finished below goal slow the climb.

| Stage | Unlocks at | Description |
|---|---|---|
| 🦴 The Cave Dweller | Level 1 | Severely hunched, knuckles dragging |
| 😑 The Office Slouch | Level 6 | Forward head, drooping shoulders |
| 🙂 The Upriser | Level 12 | Standing tall, hint of a smile |
| 🏆 The Posture Champion | Level 20 | Arms raised, wearing a crown |

Crossing a level (or stage) boundary triggers a one-time level-up celebration in the popover.

---

## Features

### v1 — MVP (in development)
- [x] HTML prototype with full character system and weekly tracking
- [x] macOS menu bar app shell (MenuBarExtra + SwiftUI popover)
- [x] Cycle timer with countdown display in menu bar
- [x] Sit/Stand toggle with session logging
- [x] Local notifications ("Time to stand!")
- [ ] Adaptive onboarding (workday length → suggested cycle)
- [x] 4-stage character (illustrated PNGs, not yet Canvas-drawn)
- [x] Weekly progress bar + streak tracking
- [ ] SwiftData persistence (currently UserDefaults + JSON — fine for v1, revisit if data needs grow)
- [x] Settings panel (cycle sliders, presets, launch at login)

Remaining before App Store submission — see [Submission Checklist](#app-store-submission-checklist) below.

### v2 — Post-launch
- [ ] Apple Watch companion app
- [ ] HealthKit integration (standing minutes → Activity rings)
- [ ] Guided stretch animations at cycle end
- [ ] Weekly summary report
- [ ] Pro tier (IAP via StoreKit)

---

## Tech Stack

| Component | Technology |
|---|---|
| UI | SwiftUI |
| Menu bar | `MenuBarExtra` (macOS 13+) |
| Persistence | SwiftData |
| Notifications | UserNotifications |
| Timer | Swift Concurrency (async/await) |
| Launch at login | ServiceManagement |
| Distribution | Mac App Store |

---

## Project Structure (planned)

```
Uptime/
├── UptimeApp.swift        # App entry point, MenuBarExtra
├── Models/
│   ├── Session.swift          # SwiftData model for sit/stand sessions
│   ├── CycleEngine.swift      # Timer logic, state machine
│   └── GoalTracker.swift      # Weekly goal calculation, streak
├── Views/
│   ├── PopoverView.swift      # Main popover content
│   ├── CharacterView.swift    # SwiftUI Canvas character drawing
│   ├── WeeklyBarView.swift    # 7-day progress bars
│   └── SettingsView.swift     # Inline settings panel
└── Resources/
    └── prototype/
        └── standup-tracker.html  # Original HTML/JS prototype
```

---

## Reference & Inspiration

Similar open-source macOS menu bar apps worth studying:

- [CapyTimer](https://github.com/andev0x/CapyTimer) — Pomodoro + menu bar, SwiftUI, very close structure to Uptime
- [MenubarCountdown](https://github.com/kristopherjohnson/MenubarCountdown) — How to show dynamic text/timer in the status bar icon
- [reminders-menubar](https://github.com/DamascenoRafael/reminders-menubar) — Clean SwiftUI popover layout pattern
- [SwiftBar](https://github.com/swiftbar/SwiftBar) — Advanced menu bar customization reference

Competing apps (for market research):
- [Stand Up! (App Store)](https://apps.apple.com/us/app/stand-standing-desk-app/id6741711329) — Closest competitor, minimal UI, no gamification
- [Desk Control](https://apps.apple.com/gb/app/desk-control/id1203254365) — LINAK desk integration focus

---

## Learning Resources

Building this from scratch with SwiftUI:

1. [Stanford CS193p](https://cs193p.sites.stanford.edu) — Free SwiftUI course, do lessons 1–5 first
2. [Apple MenuBarExtra docs](https://developer.apple.com/documentation/swiftui/menubarextra) — The API that makes this whole app possible in ~10 lines
3. [Apple SwiftUI tutorials](https://developer.apple.com/tutorials/swiftui) — Official, well-paced

---

## Roadmap

- **Now** — Learn SwiftUI basics (CS193p 1–5), build a simple timer as practice
- **Weeks 4–5** — Menu bar shell + working cycle timer + notifications
- **Weeks 6–8** — Character system + data persistence + onboarding
- **Weeks 9–10** — Polish, App Store assets, TestFlight beta, submit

---

## App Store Submission Checklist

### Account & signing
- [ ] Enroll in the Apple Developer Program ($99/yr, requires identity verification — can take a few days)
- [ ] In Xcode → target → Signing & Capabilities, set your Team (bundle ID `com.markuskaas.Uptime` is already set)
- [ ] Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` before each submission

### App content
- [ ] Replace the 4 giraffe stage illustrations with a style-consistent set (see art pipeline notes below)
- [ ] Decide whether more/finer level tiers are wanted before locking in the character progression
- [ ] Add an app icon that matches the final illustration style (current `AppIcon.appiconset` is a placeholder)
- [ ] Write real onboarding copy / first-run flow (currently jumps straight into "Standard" preset)

### App Store Connect listing
- [ ] Create the app record in App Store Connect, matching bundle ID
- [ ] App name, subtitle, description, keywords, category (likely Health & Fitness or Productivity)
- [ ] 3–10 screenshots per required Mac display size (App Store Connect will list exact sizes)
- [ ] Privacy policy URL — required even though this app stores everything locally (no account, no network calls)
- [ ] Support URL
- [ ] Age rating questionnaire
- [ ] Export compliance: app uses no encryption beyond standard OS APIs → answer "No" to the encryption question
- [ ] Pricing tier (free, per the v1 plan — Pro/IAP is v2 scope)

### Build & submit
- [ ] Archive (Product → Archive) with a Release build, signed with your Distribution certificate
- [ ] Validate and upload via Xcode Organizer (or `xcodebuild -exportArchive`)
- [ ] TestFlight beta — invite a few people who actually work desk jobs, since the character-motivation loop is the whole pitch
- [ ] Submit for review once TestFlight feedback is incorporated

---

## License

MIT — open source, feel free to learn from it.

---

*Built because existing stand-up apps track time but don't make you care about the result.*
