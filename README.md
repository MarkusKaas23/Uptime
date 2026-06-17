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

Progress is measured by how many of your tracked days this week hit your goal:

| Stage | Threshold | Description |
|---|---|---|
| 🦴 The Cave Dweller | 0–24% of goal days | Severely hunched, knuckles dragging |
| 😑 The Office Slouch | 25–49% | Forward head, drooping shoulders |
| 🙂 The Upriser | 50–74% | Standing tall, hint of a smile |
| 🏆 The Posture Champion | 75–100% | Arms raised, wearing a crown |

---

## Features

### v1 — MVP (in development)
- [x] HTML prototype with full character system and weekly tracking
- [ ] macOS menu bar app shell (MenuBarExtra + SwiftUI popover)
- [ ] Cycle timer with countdown display in menu bar
- [ ] Sit/Stand toggle with session logging
- [ ] Local notifications ("Time to stand!")
- [ ] Adaptive onboarding (workday length → suggested cycle)
- [ ] 4-stage character drawn in SwiftUI Canvas
- [ ] Weekly progress bar + streak tracking
- [ ] SwiftData persistence
- [ ] Settings panel (cycle sliders, presets, launch at login)

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

## License

MIT — open source, feel free to learn from it.

---

*Built because existing stand-up apps track time but don't make you care about the result.*
