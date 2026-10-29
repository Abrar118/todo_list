---
name: Nudge
description: A local-first task manager where put-off work comes back hotter until it is handled.
colors:
  ticket-ink: "#111417"
  ink-secondary: "#454E57"
  ink-muted: "#4F5862"
  ink-dim: "#6A747D"
  steel-ground: "#DDE2E6"
  steel-raised: "#F3F5F6"
  ticket-paper: "#FFFFFF"
  ticket-pressed: "#E8ECEE"
  steel-hairline: "#0E1A261F"
  steel-hairline-strong: "#0E1A2633"
  heat-lamp: "#7F4C00"
  thermal-red: "#AE2A21"
  done-green: "#1C6B41"
  info-blue: "#2B5574"
  paper-ink-dark: "#F1F3F5"
  ink-secondary-dark: "#BCC3C9"
  ink-muted-dark: "#AEB6BD"
  ink-dim-dark: "#8A949D"
  steel-ground-dark: "#1D2124"
  steel-raised-dark: "#24292D"
  ticket-paper-dark: "#2E3439"
  ticket-pressed-dark: "#33393F"
  steel-hairline-dark: "#FFFFFF17"
  steel-hairline-strong-dark: "#FFFFFF29"
  heat-lamp-dark: "#F2AE45"
  thermal-red-dark: "#FF7F73"
  done-green-dark: "#63D894"
  info-blue-dark: "#86BDE0"
  swatch-sage: "#48673C"
  swatch-mist: "#395A6A"
  swatch-lilac: "#4B396A"
  swatch-clay: "#6C4C37"
  swatch-sand: "#685D36"
  swatch-rose: "#6C3745"
  swatch-moss: "#4E6539"
  swatch-stone: "#4C5157"
  swatch-brick: "#713B33"
  swatch-apricot: "#76542D"
  swatch-ochre: "#646230"
  swatch-olive: "#566336"
  swatch-fern: "#3C6747"
  swatch-seafoam: "#37675B"
  swatch-teal: "#36686D"
  swatch-sky: "#315472"
  swatch-denim: "#37406C"
  swatch-iris: "#53396A"
  swatch-plum: "#653E65"
  swatch-berry: "#6F3456"
  swatch-sage-dark: "#A9C69F"
  swatch-mist-dark: "#9CBAC9"
  swatch-lilac-dark: "#AC9CC9"
  swatch-clay-dark: "#CBAE9A"
  swatch-sand-dark: "#CBC09A"
  swatch-rose-dark: "#CB9AA6"
  swatch-moss-dark: "#B1C89D"
  swatch-stone-dark: "#ADB2B8"
  swatch-brick-dark: "#D09D95"
  swatch-apricot-dark: "#D5B590"
  swatch-ochre-dark: "#CDCB98"
  swatch-olive-dark: "#BCC99C"
  swatch-fern-dark: "#9FC6A9"
  swatch-seafoam-dark: "#9CC9BE"
  swatch-teal-dark: "#98C7CD"
  swatch-sky-dark: "#94B5D1"
  swatch-denim-dark: "#9AA2CB"
  swatch-iris-dark: "#B49CC9"
  swatch-plum-dark: "#C5A0C5"
  swatch-berry-dark: "#CE97B6"
typography:
  display:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.8px"
    fontFeature: "tnum"
  title1:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "28px"
    fontWeight: 700
    letterSpacing: "-0.8px"
  title3:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.4px"
  callout:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "17px"
    fontWeight: 600
    letterSpacing: "-0.2px"
  body:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "0px"
  body-strong:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "15px"
    fontWeight: 600
    letterSpacing: "0px"
  footnote:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "13px"
    fontWeight: 500
    letterSpacing: "0px"
  caption:
    fontFamily: "SF Pro (iOS system), Roboto (Android system)"
    fontSize: "11px"
    fontWeight: 500
    letterSpacing: "0px"
rounded:
  sm: "4px"
  md: "6px"
  lg: "12px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.ticket-ink}"
    textColor: "{colors.ticket-paper}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    height: "48px"
  button-primary-dark:
    backgroundColor: "{colors.paper-ink-dark}"
    textColor: "{colors.steel-ground-dark}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    height: "48px"
  button-outlined:
    backgroundColor: "{colors.ticket-paper}"
    textColor: "{colors.ticket-ink}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    height: "48px"
  button-text:
    textColor: "{colors.ticket-ink}"
    typography: "{typography.body-strong}"
    height: "44px"
  fab-android:
    backgroundColor: "{colors.ticket-ink}"
    textColor: "{colors.ticket-paper}"
    rounded: "{rounded.md}"
    size: "56px"
  pass-ticket:
    backgroundColor: "{colors.ticket-paper}"
    textColor: "{colors.ticket-ink}"
    typography: "{typography.title3}"
    rounded: "{rounded.md}"
    padding: "16px"
  rail-tile:
    backgroundColor: "{colors.ticket-paper}"
    textColor: "{colors.ticket-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "8px 12px 8px 4px"
  ticket-stamp:
    textColor: "{colors.ticket-ink}"
    typography: "{typography.body-strong}"
  ticket-stamp-pass:
    textColor: "{colors.thermal-red}"
    typography: "{typography.display}"
  chip-filter:
    backgroundColor: "{colors.ticket-paper}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.footnote}"
    rounded: "{rounded.sm}"
    padding: "4px 8px"
  chip-filter-selected:
    backgroundColor: "{colors.ticket-ink}"
    textColor: "{colors.steel-ground}"
    typography: "{typography.footnote}"
    rounded: "{rounded.sm}"
    padding: "4px 8px"
  input-field:
    backgroundColor: "{colors.ticket-paper}"
    textColor: "{colors.ticket-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "12px"
  toast-slip:
    backgroundColor: "{colors.ticket-ink}"
    textColor: "{colors.steel-ground}"
    typography: "{typography.footnote}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  nav-bar-android:
    backgroundColor: "{colors.steel-raised}"
    textColor: "{colors.ticket-ink}"
    typography: "{typography.caption}"
    height: "72px"
---

# Design System: Nudge

## Overview

**Creative North Star: "The Ticket Rail at the Pass"**

Nudge is a kitchen pass. Every open task is a paper ticket hanging on a brushed-steel rail, stamped with how long it has waited; the ticket that has been put off longest sits on the pass at the top, printed large. Chrome and actions are print-black ink on white paper (light) or paper ink on a mid-dark steel (dark). Nothing is decorated. Colour has exactly one job, heat: a ticket warms to heat-lamp amber and then goes thermal red as it is ignored, and it holds that colour until someone handles it.

Density is phone-glance density: one strong ticket on the pass, then a compact rail of sentence-case sections (Up next, Overdue, Today, Coming up) where each row ends in a right-aligned stamp in tabular figures. The world is one identity across both OSes, but its chrome is native: an iOS large-title nav bar, translucent tab bar and nav-bar add button on iPhone; a Material top app bar, navigation bar and ink FAB on Android. Dark is "the pass after close": a mid-dark steel, tickets a clear step lighter, never near-black and never blue slate. Theme follows the system by default.

The world refuses the category default (a priority-coloured checklist of identical cards), and it refuses glass, gradients, background washes, watermark motifs, uppercase tracked labels and hero numbers.

**Key Characteristics:**
- Steel ground, white ticket paper, print-black ink; colour only for heat.
- Small, square-shouldered corners (6px) with continuous (superellipse) curvature.
- Hairline steel dividers inside one strip of paper per section, not floating cards.
- Tabular figures on every stamp, count and timer.
- Done is a struck line, then the ticket slides off the rail.
- Platform-native chrome per OS around one shared visual world.

## Colors

A cool steel-and-paper neutral system with a single print-black ink and a two-step heat ramp; every hue outside heat is either a quiet semantic signal or a user-chosen identity dot.

### Primary
- **Ticket Ink** (light `ticket-ink`, dark `paper-ink-dark`): the accent. Fills the primary button, the Android FAB, selected chips and segmented buttons, the checked completion circle, the progress track fill and the toast slip. Because it is ink, chrome and actions carry no hue at all. In dark it inverts to paper ink on steel.
- **Ink Dim** (`ink-dim` / `ink-dim-dark`): non-text accent only (3:1): switch tracks, focused input borders, secondary/tertiary Material roles.

### Secondary (the heat ramp)
- **Heat Lamp** (`heat-lamp` / `heat-lamp-dark`): heat 1, a ticket warming. Any late ticket is at least this warm. Darkened in light so it still carries text on steel.
- **Thermal Red** (`thermal-red` / `thermal-red-dark`): heat 2, a ticket gone critical. Also the Material `error` role, destructive dialog actions and the storage-error banner rim.

Heat is computed, never chosen: `TicketAge.heat` (`lib/domain/logic/ticket_age.dart`) returns 0/1/2 and `heatColor` in `lib/ui/widgets/ticket.dart` maps it to secondary ink, heat lamp, or thermal red.

### Tertiary (quiet semantics)
- **Done Green** (`done-green` / `done-green-dark`) and **Info Blue** (`info-blue` / `info-blue-dark`): completion and information states on Habits detail. Semantic, never decorative, and never on Focus.

### Neutral
- **Steel Ground** (`steel-ground` / `steel-ground-dark`): scaffold, app bars, the inside of a punch mark.
- **Steel Raised** (`steel-raised` / `steel-raised-dark`): navigation bar, tab bar, bottom sheets.
- **Ticket Paper** (`ticket-paper` / `ticket-paper-dark`): every ticket, card, dialog, input and unselected chip.
- **Ticket Pressed** (`ticket-pressed` / `ticket-pressed-dark`): pressed and selected container states, the swipe-to-defer reveal, progress tracks, the nav indicator.
- **Ink Secondary / Ink Muted**: secondary text, metadata chips, inactive tab icons and labels, placeholder text.
- **Steel Hairline / Steel Hairline Strong**: translucent dividers, field borders, outlined-button borders and the scrolled-under app bar edge.

### Identity swatches
Twenty muted `swatch-*` colours (light variants are deep, dark variants are pale) give tasks, habits and goals a user-picked identity. They render as a small dot (8px on task rows), never as a card fill or flag. Their order is parallel to the `Swatch` enum; reorder both palettes and the enum together.

### Platform mirrors
The home-screen widgets cannot read `AppColors`, so they carry a hand-kept copy of the dark palette: `android/app/src/main/res/values/colors.xml` (Kotlin widgets, plus `splash_background` at `steel-ground-dark` so launch opens onto steel) and the colour constants in `ios/NudgeWidgets/NudgeWidgets.swift`. Change `AppColors.dark` and both mirrors together.

Open item: the app icon in `assets/icon/` is still the pre-redesign purple bell and does not belong to this world. A ticket-rail icon needs a real asset; it is not specified here.

### Named Rules
**The Colour Means Heat Rule.** On Focus, the only hue on screen is heat. If a coloured pixel is not saying "this ticket is warming" or "this ticket is critical", it should be ink.

**The Priority Speaks Ink Rule.** Priority never takes a hue: high is full ink with a filled flag, medium and low are secondary ink with an outlined flag, so a high-priority ticket can never outshout one that is actually late.

**The Identity Dot Rule.** A swatch is an identity mark, never a semantic signal and never a surface tint. The punch mark is hollow precisely so it cannot be mistaken for a swatch dot.

**The Contrast Floor Rule.** Every colour that can carry text or a meaningful icon clears WCAG 4.5:1 against ground, paper and pressed in both themes; `ink-dim` is non-text and clears 3:1. `test/design_tokens_test.dart` enforces this.

## Typography

**Display Font:** the platform system face (SF Pro on iOS, Roboto on Android)
**Body Font:** the same system face
**Label/Mono Font:** none; figures use the system face with tabular figures

**Character:** Plain system type, set like a ticket printer: weights do the work, figures line up in columns, and large sizes are tightened so they do not look loose.

### Hierarchy
- **Display** (700, 34px, 1.1, tracking -0.8): the stamp on the pass ticket and the focus-timer countdown (600). The iOS large title is the system's own.
- **Title 1** (700, 28px, tracking -0.8): the headline figure or title on Goals and Habit detail.
- **Title 3** (600, 20px, 1.2, tracking -0.4): the pass ticket's title, Android app bar title, empty-state heading.
- **Callout** (600, 17px, tracking -0.2): dialog titles, Material titleMedium.
- **Body** (400, 15px, 1.35): running text; rail row titles at 500; section headers and rail stamps at 600.
- **Footnote** (500, 13px): metadata chips, section counts, chip labels, toast text.
- **Caption** (500, 11px): stamp captions ("late", "due"), navigation-bar labels, percent labels.

### Named Rules
**The Nine Sizes Rule.** Font sizes come only from `AppTypography`; no literals and no half-points. Tracking comes from `AppTypography.trackingFor(size)`.

**The Tabular Stamp Rule.** Every stamp, count, punch-mark overflow and timer is set with tabular figures so values align down the rail.

**The Sentence Case Rule.** Section headings are sentence case in ink at body weight 600. No small caps, no uppercase tracked labels.

## Layout

A strict 4/8 rhythm (`AppSpacing`: 4, 8, 12, 16, 24, 32). Root tabs inset content 16px left and right; the list starts 8px below the app bar and pads its bottom by the safe-area inset plus 16px (plus 72px on Android to clear the FAB). Section headers sit 24px below the previous section (4px for the first) and 8px above their run. Inside the pass ticket, 16px padding, 8px between title, meta and escalation line, 16px before the Done/Later pair, which splits the width with an 8px gap. Rail rows are 44px tap targets with 8px vertical padding (2px when the Compact rows setting is on). The tag filter is a 48px horizontal scroller of chips at 8px spacing.

## Elevation & Depth

Flat by default; depth is tonal. Steel ground sits under raised steel bars, and white (or one-step-lighter) ticket paper sits on the ground with no shadow. Cards, dialogs and tickets are elevation 0 with surface tint disabled, so the steel stays one colour.

### Shadow Vocabulary
- **Scrolled-under bar edge** (Material elevation 1, shadow in `steel-hairline-strong`): Android app bar when content passes under it.
- **FAB** (Material elevation 2): the Android add button.
- **Toast slip** (Material elevation 6, shadow #00000066): the inverse-ink confirmation slip at the top of the screen.

The iOS nav bar and tab bar are translucent (ground or raised steel at 86% alpha, 0.5px hairline edge): the system bar material, not decorative glass.

### Named Rules
**The Paper On Steel Rule.** A ticket reads as paper on metal by value step alone. No card shadows, no gradients, no blur behind content.

## Shapes

Small, square-shouldered corners: a ticket is cut paper, not a pill. Corners are continuous superellipses (`RoundedSuperellipseBorder` via the `AppRadii.*Shape` getters) wherever a widget takes a shape. Small (4px) for chips, fields and calendar cells; medium (6px) for ticket runs, the pass, buttons, the FAB, dialogs, toasts and panels; large (12px) for sheet tops only. Circles are reserved for the completion control (round on both platforms, the punched hole once done), punch marks and identity dots. A rail section is one strip: only its first and last tickets round their outer corners.

## Components

### Buttons
Inked and decisive, never coloured.
- **Shape:** gently squared (6px continuous).
- **Primary (Filled):** ink fill, paper text, weight 600, 48px min height. Done on the pass and every empty-state action.
- **Outlined:** ink text, strong steel hairline border, 48px min height. Later on the pass.
- **Text:** ink text, 44px min target. "Show completed", Android dialog actions (destructive in thermal red). iOS dialogs use `CupertinoDialogAction`.
- **FAB (Android only):** ink square-shouldered (6px) add button, elevation 2. On iOS the same action is the nav-bar plus.

### Chips
- **Filter (ChoiceChip):** paper ground, secondary-ink footnote label, no border, 4px corners. Selected is inked (ink fill, ground-coloured 600 label), so the active filter is the loudest chip.
- **MetaChip:** not a container; a 14px icon plus footnote label in secondary ink, coloured only by heat (overdue/escalation) or by priority ink.

### Cards / Containers
- **Corner Style:** 6px continuous.
- **Background:** ticket paper.
- **Shadow Strategy:** none (see Elevation & Depth).
- **Border:** none; rail tickets are divided by 0.5px hairlines indented 52px so they rule the text column.
- **Internal Padding:** 16px on the pass and panels; 8/12px on rail rows.

### Inputs / Fields
- **Style:** filled paper, 1px steel hairline, 4px corners, 12px padding, muted-ink hint.
- **Focus:** the border shifts to ink dim. No glow.

### Navigation
- **iOS:** `CupertinoSliverNavigationBar` large title with translucent steel and a 0.5px hairline; `CupertinoTabBar` in raised steel at 86%, ink active, muted inactive. Secondary destinations (Completed, Settings) open from an action sheet.
- **Android:** pinned `SliverAppBar` (title 3), Material `NavigationBar` in raised steel, 72px tall, pressed-steel indicator, caption labels in ink (selected) or muted ink. Secondary destinations open from a popup menu.

### The Pass Ticket (signature)
The single most put-off open task, on paper at the top of Focus. Title at title 3 (3 lines max), meta chips, and an escalation line ("Put off 3 times") in its heat colour; at the right, the stamp at display size in tabular figures with its caption and punch marks; below, Done (filled) and Later (outlined). Swiping it left also defers.

### Ticket Stamp and Punch Marks (signature)
The right edge of every Focus ticket. The value ("4d", "5:00 PM", "Sunday", "Nov 28") is ink when cold and heat-coloured at weight 700 when warm; the caption ("late", "due") is caption size. One hollow 8px punch per deferral (steel showing through, 1.5px rim in heat colour), five at most, then "+N".

### Rail Tile (signature)
A section is one strip of ticket paper: `RailTile` rounds only the first and last tickets and rules the rest with indented hairlines. Rows lead with the round 44px completion control and may carry an 8px identity dot by the title.

### The Spike (signature motion)
Completing a ticket strikes its title through (2px, muted ink), holds a beat, slides it fully off to the right (ease-in cubic, 20-65% of 560ms), then the rail closes over the gap (ease-out cubic, 60-100%). Skipped entirely under Reduce Motion.

### Empty State
One for every tab: a title 3 heading that says what is true, one teaching sentence in body secondary ink, and a filled ink action. No icon medallion.

## Do's and Don'ts

### Do:
- **Do** route every colour through `context.colors`; never a hardcoded palette constant.
- **Do** colour a Focus ticket only through `heatColor(colors, TicketAge.heat)`.
- **Do** set priority in ink: full ink and a filled flag for high, secondary ink and an outlined flag otherwise.
- **Do** show a swatch only as a small identity dot.
- **Do** take sizes from `AppTypography`, gaps from `AppSpacing` (4/8 rhythm) and corners from `AppRadii` (4/6/12), using the continuous `*Shape` getters.
- **Do** use tabular figures for every stamp, count and timer.
- **Do** use the platform form for chrome: `isCupertino(context)` picks large-title nav bar, tab bar and nav-bar add on iOS, app bar, navigation bar and FAB on Android; `.adaptive` dialogs, switches and progress indicators.
- **Do** honour Reduce Motion: durations from `AppMotion` (140 / 240 / 360ms, ease-out cubic in, ease-in cubic out) and none at all when animations are disabled.
- **Do** keep text and meaningful icons at 4.5:1 against ground, paper and pressed in both themes.

### Don't:
- **Don't** use glass, gradients, background washes, watermark motifs, uppercase tracked labels or hero numbers.
- **Don't** colour priority, chrome or actions; red is for a ticket gone critical, not a high flag.
- **Don't** tint a card or surface with a swatch.
- **Don't** add card shadows; depth is a value step from steel to paper.
- **Don't** use pill or large rounded corners on tickets, buttons or panels; 12px is for sheet tops only.
- **Don't** make dark near-black or blue slate; it is mid-dark steel with tickets a clear step lighter.
- **Don't** write a font-size, radius or spacing literal.
