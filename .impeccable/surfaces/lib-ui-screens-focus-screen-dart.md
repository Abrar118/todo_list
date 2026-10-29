---
version: 1
slug: "lib-ui-screens-focus-screen-dart"
primary_target: "lib/ui/screens/focus_screen.dart"
related_targets: ["lib/ui/home_shell.dart"]
---

# Focus (Operate)

Scope: the Focus tab, plus the app shell (navigation, add action) it sits in. Mode: Operate.
Audience and job: one person glancing at their phone between other things; see what has waited longest, then complete it or consciously put it off. Must carry escalation (deferral count, days overdue) honestly; no invented data.
Memorable moment: the ticket on the pass, stamped with how long it has waited, warming from ink to amber to red.
Open decisions: app icon redesign (needs a real asset; out of scope).

## Direction contract

THESIS: Focus is a ticket rail. Every open task is a ticket stamped with how long it has waited; the most put-off ticket sits on the pass. It refuses the category default: a priority-coloured checklist of identical cards.

OWN-WORLD: Brushed-steel ground (cool blue-grey), white ticket surfaces, print-black ink for all chrome and primary actions. Colour is reserved for heat: heat-lamp amber when a ticket is warming, thermal red when critical. System type (SF / Roboto), tabular figures on every stamp. Small square-shouldered radii, hairline steel dividers; no glass, no gradients, no washes.

STORY: The visitor sees at a glance what has waited longest, understands that ignoring it makes it louder, and completes or deliberately defers it.

FIRST VIEWPORT: Platform large title "Focus". Under it, the pass: one full-width ticket with the title, its wait stamp large in tabular figures at the right in its heat colour, punch marks counting put-offs, inline Done and Later. Below, the rail: one list in sentence-case sections (Up next, Overdue, Today, Coming up), each row ending in a right-aligned wait or due stamp. Add is the nav-bar + on iOS, the FAB on Android; tabs are the platform tab bar or navigation bar. Signature interaction: a completed ticket is struck through, then slides off the rail.

FORM: kitchen ticket rail, 4 of 7; seed:312d9d97e7eb115e. Raises: from Ikeda, value not tint carries state; from the gate board, an escalated stamp holds its colour until handled; from airport yellow, colour has one job (heat); from the star atlas, one fixed heat ramp encodes escalation; from the centre rail, done is a struck line; from Crouwel, a strict 4/8 grid.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
