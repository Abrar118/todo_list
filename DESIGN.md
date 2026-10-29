---
name: Nudge
description: A local-first task manager where put-off work comes back hotter until it is handled.
colors:
  leaf-fill: "#58CC02"
  on-leaf-fill: "#10270A"
  leaf-lip: "#46A302"
  leaf-lip-dark: "#3B8A02"
  leaf-ink: "#2A750D"
  on-leaf-ink: "#FFFFFF"
  leaf-dim: "#578F40"
  leaf-ink-dark: "#86E04A"
  on-leaf-ink-dark: "#0E1912"
  leaf-dim-dark: "#4D8A37"
  forest-hero: "#1D4D2B"
  on-hero: "#FFFFFF"
  on-hero-muted: "#BFE3C4"
  hero-warm: "#F4B04B"
  hero-hot: "#FFB0A6"
  forest-hero-dark: "#215C30"
  on-hero-muted-dark: "#C3E8C8"
  hero-warm-dark: "#F7BE62"
  hero-hot-dark: "#FFB8AE"
  grass: "#8BDB4A"
  far-hill: "#6CC72E"
  grass-dark: "#1B3F20"
  far-hill-dark: "#24512A"
  streak-flame: "#FF9600"
  tint-sun: "#FFEFD2"
  tint-leaf: "#DDF4C9"
  tint-sky: "#DCEBFB"
  streak-flame-dark: "#FF9F1C"
  tint-sun-dark: "#3A2A12"
  tint-leaf-dark: "#1F3A1E"
  tint-sky-dark: "#172C40"
  meadow-page: "#F2F8EA"
  elevated: "#FFFFFF"
  card-white: "#FFFFFF"
  pressed: "#E4EFD8"
  forest-ink: "#13251A"
  ink-secondary: "#3B5243"
  ink-muted: "#4A604F"
  border: "#13251A24"
  border-strong: "#13251A38"
  meadow-page-dark: "#0E1912"
  elevated-dark: "#16241A"
  card-dark: "#1A2B1F"
  pressed-dark: "#223727"
  moon-ink-dark: "#EDF6E8"
  ink-secondary-dark: "#B7CBB0"
  ink-muted-dark: "#A5BA9E"
  border-dark: "#E6FFDC1F"
  border-strong-dark: "#E6FFDC33"
  overdue: "#B3261E"
  medium: "#8A4F00"
  done: "#21733A"
  low: "#2A5C85"
  overdue-dark: "#FF8A7E"
  medium-dark: "#F4B04B"
  done-dark: "#6ADB8E"
  low-dark: "#8CC2EA"
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
    fontFamily: "Nunito"
    fontSize: "34px"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "-0.8px"
    fontFeature: "tnum"
  title1:
    fontFamily: "Nunito"
    fontSize: "28px"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "-0.8px"
  title3:
    fontFamily: "Nunito"
    fontSize: "20px"
    fontWeight: 900
    lineHeight: 1.2
    letterSpacing: "-0.4px"
  callout:
    fontFamily: "Nunito"
    fontSize: "17px"
    fontWeight: 800
    letterSpacing: "-0.2px"
  body:
    fontFamily: "Nunito"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "0px"
  footnote:
    fontFamily: "Nunito"
    fontSize: "13px"
    fontWeight: 700
    letterSpacing: "0px"
  caption:
    fontFamily: "Nunito"
    fontSize: "11px"
    fontWeight: 800
    letterSpacing: "0px"
rounded:
  sm: "10px"
  md: "16px"
  lg: "24px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.leaf-fill}"
    textColor: "{colors.on-leaf-fill}"
    typography: "{typography.callout}"
    rounded: "{rounded.md}"
    padding: "0 20px 4px"
    height: "52px"
  button-primary-pressed:
    backgroundColor: "{colors.leaf-fill}"
    textColor: "{colors.on-leaf-fill}"
    typography: "{typography.callout}"
    rounded: "{rounded.md}"
    padding: "3px 20px 1px"
    height: "52px"
  button-outlined:
    backgroundColor: "{colors.card-white}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.callout}"
    rounded: "{rounded.md}"
    padding: "0 20px 4px"
    height: "52px"
  button-text:
    textColor: "{colors.leaf-ink}"
    typography: "{typography.body}"
    height: "44px"
  fab-android:
    backgroundColor: "{colors.leaf-fill}"
    textColor: "{colors.on-leaf-fill}"
    rounded: "{rounded.md}"
    size: "56px"
  hero-card:
    backgroundColor: "{colors.forest-hero}"
    textColor: "{colors.on-hero}"
    typography: "{typography.title3}"
    rounded: "{rounded.lg}"
    padding: "20px 20px 25px"
  stat-tile-sun:
    backgroundColor: "{colors.tint-sun}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.title1}"
    rounded: "{rounded.md}"
    padding: "12px 8px 16px 12px"
  stat-tile-leaf:
    backgroundColor: "{colors.tint-leaf}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.title1}"
    rounded: "{rounded.md}"
    padding: "12px 8px 16px 12px"
  stat-tile-sky:
    backgroundColor: "{colors.tint-sky}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.title1}"
    rounded: "{rounded.md}"
    padding: "12px 8px 16px 12px"
  task-card:
    backgroundColor: "{colors.card-white}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
  form-panel:
    backgroundColor: "{colors.card-white}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.callout}"
    rounded: "{rounded.md}"
  chip-filter:
    backgroundColor: "{colors.card-white}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.footnote}"
    rounded: "{rounded.pill}"
    padding: "4px 8px"
  chip-filter-selected:
    backgroundColor: "{colors.leaf-fill}"
    textColor: "{colors.on-leaf-fill}"
    typography: "{typography.footnote}"
    rounded: "{rounded.pill}"
    padding: "4px 8px"
  input-field:
    backgroundColor: "{colors.card-white}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "12px"
  toast:
    backgroundColor: "{colors.forest-hero}"
    textColor: "{colors.on-hero}"
    typography: "{typography.footnote}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  tab-bar:
    backgroundColor: "{colors.card-white}"
    textColor: "{colors.leaf-ink}"
    typography: "{typography.caption}"
    rounded: "{rounded.lg}"
    height: "64px"
  root-app-bar:
    backgroundColor: "{colors.grass}"
    textColor: "{colors.forest-ink}"
    typography: "{typography.title1}"
---

# Design System: Nudge

## Overview

**Creative North Star: "The Meadow"**

Nudge opens onto a field. Every root tab starts under a band of fresh grass: the app bar is painted grass green and runs straight into a painted header where a far hill swells across the width, a few daisies dot it, and the pale green page rolls up over it like a near slope. On that page sit chunky, soft blocks: white cards with a solid lip along their bottom edge, vivid leaf-green buttons that visibly sink when pressed, and 3D illustrations (a flame, a check, an alarm clock, a trophy) that make the counts feel like rewards rather than debts. The tone is playful and encouraging, in the family of Duolingo and Headspace, not a grey utility list.

The one task that has waited longest sits on a dark-forest hero card near the top of Focus, printed large with how late it is and with Done and Later right there. Lateness still has a temperature: a task warms to amber and then goes red the longer it is put off, and a hollow ring under it counts each deferral. Everything else is a stack of white task cards in sentence-case sections. Dark mode is the same meadow at night: deep forest ground, moonlit ink, cards a clear step lighter, the same leaf-green buttons.

The world is one identity across both OSes but its chrome behaves natively: an iOS large-title nav bar, `CupertinoTabBar` and nav-bar add button on iPhone; a Material app bar, `NavigationBar` and FAB on Android. Both tab bars are floated inside one chunky white block above the page.

**Key Characteristics:**
- A grass band (painted hills, scattered daisies) heads every root tab and flows from the status bar into the page.
- Chunky blocks: generous continuous corners (10/16/24px) and a solid bottom lip on everything pressable; pressed, the lip shrinks and the block sinks.
- Vivid leaf green is a fill with dark glyphs on it, never a text colour; a deeper leaf green carries green text.
- Lateness is heat (amber, then red); priority stays in ink.
- Cheerful 3D illustrations decorate stat tiles, the hero card and empty states; icons stay Material/Cupertino.
- Nunito throughout, heavy (800/900) for headings, figures and buttons.

## Colors

A fresh green meadow by day and a forest at night, with one vivid leaf-green fill for actions, a warm cheer family for rewards, and a heat pair that is reserved for lateness.

### Primary
- **Leaf Fill** (`leaf-fill`, both themes): every primary button, the Android FAB, the checked completion circle, the selected filter chip and segmented segment, the selected calendar day, switch tracks, sliders, progress fills and the focused-field border. Too light for white text; it always carries **On Leaf Fill** (`on-leaf-fill`), a near-black green.
- **Leaf Lip** (`leaf-lip` / `leaf-lip-dark`): the solid bottom lip under every leaf-green block.
- **Leaf Ink** (`leaf-ink` / `leaf-ink-dark`): the text- and icon-safe green. Text buttons ("Show completed", the editor's Done), selected tab icons and labels, the Material `primary` role and Cupertino `primaryColor`. **Leaf Dim** (`leaf-dim` / `leaf-dim-dark`) is the non-text green (3:1) for the `secondary` role.

### Secondary (the hero and heat)
- **Forest Hero** (`forest-hero` / `forest-hero-dark`): the dark-forest card the longest-waiting task sits on, in both themes; also the toast and the date-picker header. Text on it is **On Hero** (white) or **On Hero Muted** for meta.
- **Heat** is computed, never chosen: `TicketAge.heat` (0/1/2) maps through `heatColor` to secondary ink, **Medium** amber (`medium` / `medium-dark`) or **Overdue** red (`overdue` / `overdue-dark`). On the hero card the same heat goes through `heroHeatColor` to **Hero Warm** and **Hero Hot**, re-mixed to clear 4.5:1 on forest. Overdue is also the Material `error` role and the destructive dialog action.

### Tertiary (cheer)
- **Streak Flame** (`streak-flame` / `streak-flame-dark`): the streak colour and the Material `tertiary` role. A fill only.
- **Tint Sun / Tint Leaf / Tint Sky** (`tint-*`): the grounds of the three stat tiles (streak, done today, waiting) and of the swipe-to-Later reveal (sun). Ink text sits on them.
- **Grass / Far Hill** (`grass`, `far-hill` and their `-dark` pair): the meadow band at the top of every root tab and the hill rolling out of it. Text sits on the grass, never on the hill.

### Neutral
- **Meadow Page** (`meadow-page` / `meadow-page-dark`): scaffold and the near slope of the header.
- **Card White** (`card-white` / `card-dark`) and **Elevated** (`elevated` / `elevated-dark`): every card, panel, dialog, input, unselected chip and the tab-bar block; elevated is the sheet ground.
- **Pressed** (`pressed` / `pressed-dark`): pressed states, progress tracks, unchecked habit day dots.
- **Forest Ink / Moon Ink** (`forest-ink` / `moon-ink-dark`), **Ink Secondary**, **Ink Muted**: primary, secondary and placeholder text, inactive tab icons.
- **Border / Border Strong**: translucent forest (light) or moonlit green (dark) for card sides, field strokes, chip strokes and the source of the quiet lip.
- **Done** and **Low** (`done`, `low` and dark pair): completion and information semantics. Never decorative.

### Identity swatches
Twenty muted `swatch-*` colours (deep in light, pale in dark) give tasks, habits and goals a user-picked identity. Their order is parallel to the `Swatch` enum and `AppColors.decorative`; reorder the enum and both palettes together.

### Platform mirrors
Home-screen widgets and launch cannot read `AppColors`, so they carry a hand-kept copy of `AppColors.dark`: `android/app/src/main/res/values/colors.xml` (widget colours and `splash_background`), the colour constants in `ios/NudgeWidgets/NudgeWidgets.swift`, and the background of `ios/Runner/Base.lproj/LaunchScreen.storyboard`. All three open on the night-meadow ground. Change `AppColors.dark` and all three together.

### Named Rules
**The Heat Rule.** Lateness is the only thing that turns a task amber or red: `heatColor` on the page, `heroHeatColor` on the hero. Nothing else borrows those two colours as decoration.

**The Priority Speaks Ink Rule.** Priority never takes a hue: high is full ink with a filled flag, medium and low are secondary ink with an outlined flag (`priorityColor`, `priorityIcon`), so a high flag can never outshout a task that is actually late. The widgets follow it too.

**The Fill-Only Leaf Rule.** Leaf Fill is a surface, not a text colour, and what sits on it is always On Leaf Fill; white on it fails contrast. Green text uses Leaf Ink.

**The Cheer Is Fill Rule.** Streak Flame and the three tints are grounds and illustration companions. Text on them is ink; they are never text themselves.

**The Identity Dot Rule.** A swatch renders as a small solid dot (8px by a task title, likewise on habit and goal cards), never as a card tint or a flag. Deferral marks are hollow rings precisely so they cannot be read as identity dots.

**The Contrast Floor Rule.** Every text or meaningful-icon colour clears 4.5:1 on page, card and pressed in both themes; Leaf Dim clears 3:1; each fill clears 4.5:1 with its own foreground; on-hero colours clear 4.5:1 on forest (Leaf Fill 3:1); ink clears 4.5:1 on every tint and on the grass. `test/design_tokens_test.dart` enforces all of it.

## Typography

**Display Font:** Nunito (bundled, `assets/fonts/`, weights 400 to 900)
**Body Font:** Nunito
**Label/Mono Font:** none; counts and stamps use Nunito with tabular figures

**Character:** Rounded terminals and a heavy black weight: headings, figures and buttons are set at 800 to 900 so the type feels as chunky and friendly as the blocks it sits on; running text stays at 600 so it still reads easily.

### Hierarchy
- **Display** (900, 34px, 1, tracking -0.8): the iOS large title and the hero card's lateness stamp (tabular).
- **Title 1** (900, 28px, 1, tracking -0.8): the Android app-bar title and stat-tile figures (tabular).
- **Title 3** (900, 20px, 1.2, tracking -0.4): the hero task title, empty-state headings; dialog titles at 800.
- **Callout** (800, 17px, tracking -0.2): button labels, section headers (900), the summary line under the greeting, Cupertino nav titles.
- **Body** (600, 15px, 1.35): running text and task titles.
- **Footnote** (700, 13px): meta chips, chip labels, stat-tile labels (800), section counts, toast text.
- **Caption** (800, 11px): tab labels and small stamp captions.

### Named Rules
**The Scale-Only Rule.** Sizes come only from `AppTypography` (no literals, no half-points) and tracking from `AppTypography.trackingFor(size)`.

**The Tabular Figures Rule.** Every stamp, count, stat figure and timer is set with tabular figures.

**The Sentence Case Rule.** Headings and section headers are sentence case in ink. Weight carries emphasis, not case or letter-spacing.

## Layout

A 4/8 rhythm (`AppSpacing`: 4, 8, 12, 16, 24, 32). Root tabs use 16px side gutters. The meadow header pads its content 16px at the sides and 4px at the top and reserves its bottom 40px for the hills; on Focus it holds the summary line, 12px of air, then three equal stat tiles 8px apart. Lists start 8px below the header and pad their bottom by the safe-area inset plus 16px (plus 72px on Android to clear the FAB). Task cards stack with 8px between them. Section headers sit 24px below the previous section (4px for the first) and 8px above their cards. The tag filter is a 48px horizontal row of pill chips at 8px spacing. The tab-bar block floats 16px in from each side and sits on the home indicator inset (12px when there is none). Editors and detail screens drop the meadow band and group fields in white panels on the page, under sentence-case section headers.

## Elevation & Depth

Depth is mostly built, not cast: a block reads as raised because of its solid bottom lip, not a shadow. Cards and panels are elevation 0 with surface tint disabled. A few floating elements cast a soft shadow on top of their lip.

### Shadow Vocabulary
- **Tab-bar block** (Material elevation 4, shadow `#00000033`): the floating tab bar.
- **FAB** (Material elevation 3, 1 while pressed): the Android add button.
- **Toast** (Material elevation 6, shadow `#00000066`): the forest confirmation slip at the top of the screen.

### Named Rules
**The Lip Rule.** Every pressable block carries a solid lip on its bottom edge (`ChunkyBorder`): 4px on buttons, the FAB, stat tiles and the tab bar; 3px on task, habit and goal cards; 5px on the hero. Pressed, a button's lip drops to 1px and its label drops with the face (80ms), so the block sinks. The leaf lip is Leaf Lip; quiet blocks take a lip of Border Strong blended over their own face; the hero takes 35% black over forest.

## Shapes

Soft, chunky, toy-block forms with continuous (superellipse) corners, via `AppRadii.*Shape` and `ChunkyBorder`. Small (10px) for fields, calendar cells and inline pills; medium (16px) for buttons, the FAB, task cards, stat tiles, form panels, toasts and the segmented control; large (24px) for the hero card, the calendar card, the tab-bar block, dialogs and sheet tops. Filter chips are full pills. Circles are reserved for the completion control (round on both platforms, filled leaf green once done), habit day dots, identity dots and the hollow deferral marks. The meadow header's hills are the only free-form curves: one long cubic swell for the far hill and two gentle waves for the near slope.

## Components

### Buttons
Chunky, cheerful and pressable.
- **Shape:** medium continuous corners (16px) with a 4px solid lip.
- **Primary (Filled):** Leaf Fill face, On Leaf Fill label at callout 800, 52px tall, 20px side padding. Every empty-state action and Done on the hero.
- **Outlined (quiet):** card face, ink label, 1.5px Border Strong side, same lip and height. On the hero it is re-mixed as a translucent white face (12%) with a dark lip so it never competes with Done (Later).
- **Pressed:** the lip shrinks 4px to 1px and the label drops 3px; disabled blocks take a Border Strong lip.
- **Text:** Leaf Ink at 800, 44px minimum target. Android dialog actions are text buttons (destructive in Overdue); iOS dialogs use `CupertinoDialogAction`.
- **FAB (Android only):** Leaf Fill, 16px chunky shape with the Leaf Lip, 30px plus glyph. On iOS the same action is the nav-bar plus.

### Chips
- **Filter (ChoiceChip):** card face, 1.5px Border Strong side, Ink Secondary footnote label, full pill. Selected is Leaf Fill with an On Leaf Fill label at 800, so the active filter is the loudest chip.
- **MetaChip:** not a container; a 14px icon plus footnote label at 700 in Ink Secondary (On Hero Muted on the hero), coloured only by heat or priority ink.

### Cards / Containers
- **Task card:** white face, 16px, 1.5px Border side, 3px quiet lip, 8px gap below. Leads with the round completion control, may carry an 8px identity dot by the title, and ends in its stamp.
- **Stat tile:** a tint face (sun, leaf or sky), 4px lip, a 34px illustration, the figure at title 1 900 and a footnote 800 label. Read as one phrase by screen readers.
- **Form panel (editors, detail):** white face, 16px corners, no side and no lip; panels are containers, not pressable blocks.
- **Calendar card:** the month grid on a white block, 24px corners, 4px lip, sitting on the meadow band; the selected day is a Leaf Fill cell.

### Inputs / Fields
- **Style:** filled card white, 1.5px Border Strong stroke, 10px corners, 12px padding, Ink Muted hint.
- **Focus:** the stroke turns Leaf Fill at 2px. No glow.

### Navigation
- **Root app bar:** painted Grass in both forms so it runs into the meadow header. iOS: `CupertinoSliverNavigationBar` large title (display 900), no border, actions and the add plus trailing. Android: pinned `SliverAppBar` with a title 1 900 title; the add action is the FAB.
- **Tab bar:** the platform's own bar (`CupertinoTabBar`, 58px, or Material `NavigationBar`, 64px) on a transparent ground inside one floating white chunky block (24px, 4px lip, elevation 4). Active icon and label in Leaf Ink, inactive in Ink Muted, caption labels at 800; Android shows a Tint Leaf pill indicator.
- **Secondary destinations** (Completed, Settings) open from a `CupertinoActionSheet` on iOS and a popup menu on Android.

### Meadow Header (signature)
The grass band under every root tab's app bar: Grass fill, a Far Hill swell 40px from the bottom with five fixed daisies (card colour, 85%), and the page colour rolling up as a two-wave near slope. Focus puts the greeting's summary line and the stat tiles on it; Calendar puts the month card on it; Habits puts its segmented control and stat tiles on it.

### Hero Card (signature)
The single longest-waiting open task on Forest Hero, 24px corners, 5px lip. Title at title 3 900 (3 lines max), meta chips in On Hero Muted, a 56px illustration that follows heat (bullseye when cold, hourglass when warming, alarm clock when critical), the stamp at display 900 with its caption, deferral marks on the right, the put-off line in heat, then Done (flex 3) and Later (flex 2) 8px apart. Swiping it left also defers.

### Stamp and Deferral Marks
The right edge of every Focus task card: the value ("1d", "5:00 PM", "Nov 28") in ink when cold and in heat at 700 when warm, with its caption at caption size. One hollow 9px ring per deferral (2px rim in the heat colour, the surface showing through), five at most, then "+N".

### Illustrations
Fluent Emoji 3D renders (`assets/illustrations/`, MIT, provenance in its README) through the `Art` enum and `Illustration`: 34px on stat tiles, 56px on the hero, 112px in empty states, 22px beside habit streaks. Hidden from screen readers; the words beside them carry meaning.

### Empty State
One for every tab: a 112px illustration, a title 3 heading that says what is true, one teaching sentence in Ink Secondary, and a chunky Leaf Fill action.

### Completion exit (signature motion)
Completing a Focus task strikes its title through (2px), slides the card fully off to the right (ease-in cubic, 20 to 65% of 560ms) and then closes the gap (ease-out cubic, 60 to 100%). Skipped under Reduce Motion. Other motion uses `AppMotion` (140 / 240 / 360ms, ease-out cubic in, ease-in cubic out); the toast slides down 240ms and leaves in 140ms.

## Do's and Don'ts

### Do:
- **Do** route every colour through `context.colors`; never a hardcoded palette constant.
- **Do** colour lateness only through `heatColor` on the page and `heroHeatColor` on the hero.
- **Do** set priority in ink: full ink and a filled flag for high, secondary ink and an outlined flag otherwise.
- **Do** put On Leaf Fill on every Leaf Fill surface, and use Leaf Ink when green must be text.
- **Do** give every pressable block the solid lip (`ChunkyBorder`, or `chunkyCard` for cards) and let it sink when pressed.
- **Do** open each root tab under the meadow band, with the app bar painted Grass, and keep text on the grass rather than the hill.
- **Do** use illustrations for stat tiles, the hero card and empty states, and Material/Cupertino glyphs for every icon.
- **Do** show a swatch only as a small identity dot.
- **Do** take sizes from `AppTypography`, gaps from `AppSpacing` and corners from `AppRadii` (10/16/24, pill for chips), using the continuous `*Shape` getters.
- **Do** keep chrome native in behaviour: `isCupertino(context)` picks the large-title nav bar, `CupertinoTabBar` and nav-bar add on iOS, the app bar, `NavigationBar` and FAB on Android; use `.adaptive` dialogs, switches and progress indicators.
- **Do** honour Reduce Motion.
- **Do** change `AppColors.dark` together with its Android, iOS widget and launch-screen mirrors.

### Don't:
- **Don't** put white text on Leaf Fill; it fails contrast.
- **Don't** use Streak Flame or the tints as text colours.
- **Don't** colour priority amber or red; those two mean late.
- **Don't** tint a card or surface with a swatch.
- **Don't** replace an icon with an illustration, or put an illustration where a control's meaning depends on it.
- **Don't** swap the native tab bar or nav bar for a custom widget; restyle around them.
- **Don't** write a font-size, radius or spacing literal.
