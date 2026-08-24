# Nudge (iOS)

A free, ADHD-friendly daily planner — a visual timeline, gentle reminders, a
focus timer, and Home Screen widgets, in the same spirit as Tiimo or
Structured but with no subscription and no paywall.

## Opening the project

Open `Nudge.xcodeproj` in Xcode 15+ and run the `Nudge` scheme on an iOS 17+
simulator or device.

## Installing without a paid developer account (AltStore/SideStore)

No Apple Developer account is required to install this on your own device.
Every push of a `vX.Y.Z` tag runs [`.github/workflows/release.yml`](.github/workflows/release.yml),
which builds an **unsigned** `Nudge.ipa` (via [`scripts/build_ipa.sh`](scripts/build_ipa.sh)),
attaches it to a [GitHub Release](https://github.com/om0019/nudge-ios/releases),
and updates [`apps.json`](apps.json) — an AltStore/SideStore source manifest —
with the new version, size, and checksum.

To install:

1. Install [AltStore](https://altstore.io) or [SideStore](https://sidestore.io)
   and pair it with your computer (a free Apple ID is enough — it just needs
   re-signing every 7 days).
2. In AltStore/SideStore, add this source:
   ```
   https://raw.githubusercontent.com/om0019/nudge-ios/main/apps.json
   ```
3. Install **Nudge** from the source. AltServer/SideServer signs the unsigned
   IPA locally with your Apple ID at install time — that's what makes a free
   account work.

To cut a new release yourself: `git tag v1.0.0 && git push origin v1.0.0`.
Or run `./scripts/build_ipa.sh` locally to build `Nudge.ipa` without touching
GitHub at all (useful for sideloading via Xcode or AltServer's drag-and-drop
install without going through a release).

Nothing in the app requires paid Apple Developer capabilities: it only uses
local notifications, an App Group, WidgetKit, and a notification content
extension, all of which work under a free-tier Apple ID signed in through
Xcode or AltStore/SideStore.

## What's included

- **Nudge** — the container app.
  - **Today screen** (`Nudge/ContentView.swift`) — Up Next, Today's
    Timeline, Streak, and a Focus Timer prompt, each an independent,
    reorderable, hideable section (see Customize below).
  - **Add/Edit Task** (`Nudge/AddTaskView.swift`) — title, SF Symbol icon,
    color, start time, duration, weekly repeat days, and an optional
    reminder lead time.
  - **Focus Timer** (`Nudge/FocusTimerView.swift`) — a distraction-free
    circular countdown for whatever task you start it from.
  - **Customize** (`Nudge/CustomizeView.swift`) — accent color (8 presets or
    any custom color via `ColorPicker`), light/dark/system appearance, and
    the Today screen's section order + visibility toggles.
- **NudgeWidgets** — a WidgetKit extension with three Home Screen widgets,
  all reading the same shared task data as the app:
  - **Up Next** (small/medium) — your next task or routine block.
  - **Today's Timeline** (medium/large) — the day's tasks in order, with
    completion state.
  - **Streak** (small) — consecutive days you've completed every routine
    task.
- **NudgeNotificationContent** — a `UNNotificationContentExtension` that
  renders a rich "notification widget" for task reminders: the task's icon,
  title, and time in its accent color, with **Mark done** and **Snooze 10m**
  action buttons (`Nudge/NotificationManager.swift` registers the actions;
  `NudgeNotificationContent/NotificationViewController.swift` renders the
  custom content).
- **Shared** — the App Group storage layer both the app and both extensions
  read/write through:
  - `AppGroup.swift` — the shared `UserDefaults(suiteName:)` container.
  - `NudgeModels.swift` — `NudgeTask`, completion tracking + streak
    calculation, the accent-color/appearance store, the customizable
    dashboard section order/visibility store, and the read-only data access
    helpers the widgets use.

## Customization

Everything under "should have customizability" lives in **Customize**
(the slider icon in the Today screen's toolbar):

- **Accent color** — 8 curated presets plus a full `ColorPicker` for any
  custom color. Applied app-wide via `.tint()`, and read by the widgets and
  notification content extension too.
- **Appearance** — match device, force light, or force dark.
- **Today screen layout** — drag to reorder Up Next / Today's Timeline /
  Streak / Focus Timer, and toggle any of them off. The app only shows what
  you've turned on, in the order you picked.

## Notifications

`Nudge/NotificationManager.swift` schedules a local notification per task
using its optional reminder lead time (0–30 minutes before start). Each
notification:

- Uses the `nudge.task` category, which is rendered by the
  `NudgeNotificationContent` extension as a rich card (icon, title, time).
- Carries **Mark done** and **Snooze 10m** actions that work right from the
  lock screen/notification banner, no need to open the app.
- For a repeating routine (task has weekly repeat days set), one
  `UNCalendarNotificationTrigger` is scheduled per selected weekday so it
  only fires on the days you actually picked.

## Home Screen widgets

Build and run the app once on a device/simulator, then long-press an empty
area of the Home Screen → tap **+** in the top corner → search for "Nudge"
→ pick a widget size → **Add Widget**. Widgets refresh every 15 minutes and
immediately whenever the app changes a task, completion, or the accent
color (via `WidgetCenter.shared.reloadAllTimelines()`).

## One-time Xcode setup: App Group

The app, the widget extension, and the notification content extension share
task data through an App Group container. This has to be wired up once in
Xcode (it can't be done from files alone):

1. Select the **Nudge** target → **Signing & Capabilities** → **+
   Capability** → **App Groups**. Add (or check) the group
   `group.com.nudgeapp.shared`.
2. Repeat for the **NudgeWidgetsExtension** target, using the same group ID.
3. Xcode will generate/link `.entitlements` files for each target — this
   repo already has placeholder ones (`Nudge/Nudge.entitlements`,
   `NudgeWidgets/NudgeWidgets.entitlements`) with the matching group ID, so
   Xcode should just pick them up.

Without this step, the app and the widgets will each keep their own
disconnected copy of the data.
