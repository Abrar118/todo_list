---
version: 1
slug: "lib-ui-screens-focus-screen-dart"
primary_target: "lib/ui/screens/focus_screen.dart"
related_targets: ["lib/ui/home_shell.dart"]
---

# Focus (Operate)

Scope: the Focus tab, plus the app shell (navigation, add action) it sits in. Mode: Operate.
Audience and job: one person glancing at their phone between other things; see what has waited longest, then complete it or consciously put it off. Must carry escalation (deferral count, days overdue) honestly; no invented data.
Memorable moment: the dark-forest hero card holding the task that has waited longest, its stamp warming from white to amber to coral, with a chunky green Done.
Open decisions: app icon redesign and a custom mascot (need real artwork; out of scope).

## Direction contract

THESIS: Focus is a meadow you check in on. A friendly greeting and three bright stat tiles, then the one task that has waited longest on a dark-forest hero card, then everything else as chunky white blocks. Pinned by the user's Duolingo / Headspace reference (2026-10-29), after a quiet grey "ticket rail" was rejected as generic and washed out.

OWN-WORLD: A grass band (#8BDB4A by day) rolling over painted hills into a pale green page (#F2F8EA); white chunky cards with a solid bottom lip; vivid leaf green (#58CC02) for every primary button and the add button, always with dark ink text; a dark-forest hero card (#1D4D2B); stat tiles in sun, leaf and sky tints with Fluent Emoji 3D illustrations; Nunito throughout, heavy (800–900) for headings and buttons. Lateness is still heat: amber when warming, red when critical (re-mixed for the hero card). Dark: the meadow at night — forest ground (#0E1912), cards a step lighter, the same vivid green buttons.

STORY: The visitor feels welcomed, sees at a glance what has waited longest and how their day is going, and completes or deliberately defers it.

FIRST VIEWPORT: The platform title bar painted grass green, carrying a time-of-day greeting. Under it on the grass, one line ("2 waiting, 1 of them late.") and three stat tiles: best habit streak, done today, waiting. Then the hero card: title, meta, illustration, the wait stamp large in its heat colour with put-off marks, chunky Done and Later. Below, sentence-case sections of chunky task cards. Add is the nav-bar + on iOS, the green FAB on Android; tabs are the native tab bar or navigation bar, floated as a chunky white block. Signature interaction: a completed task is struck through, then slides off.

FINISH: unreviewed and undocumented is unfinished; this build ends with an emulator check in both themes and both OS chromes, DESIGN.md, and every shipping raster carrying its provenance (assets/illustrations/README.md).
