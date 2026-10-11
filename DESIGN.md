# Design rules

Growstuff strives for consistent design. This is very much a work in progress.
Much of the site predates this document. Where a page disagrees with a rule
here, the rule is the target; fix it when you're next in there.

## A page says what it is about

A record page names its record type in the heading. Not "Chives" — that's a
crop. "Chives planting". Harvests and saved seeds do the same.

| Record   | `h1`              | Subtitle, muted             |
| -------- | ----------------- | --------------------------- |
| Planting | `<crop> planting` | `by <owner> in <garden>`    |
| Harvest  | `<crop> harvest`  | `by <owner> · <date>`       |
| Seed     | `<crop> seeds`    | `saved by <owner>`          |

The noun goes in the `h1` itself, not only in the subtitle. A garden is the
exception: its name is the member's own, so the noun sits in the subtitle
rather than being appended to a name that may already contain it.

The `<title>` tag and the OpenGraph title carry the same sentence, so a shared
link announces the same thing the page does.

Where the grower is goes in the subtitle too. It decides the seasons and the
harvest times, so it's one of the first things worth knowing.

## The actions menu

Every record page carries **one** actions menu: a three-dot (kebab) button, in
the top right of the hero, on the title's line. Plantings and crops both use
it; the rest should follow.

```
┌──────────────────────────────────────────────┐
│ 🌱 Sunflower                              ⋮  │   ← the kebab, top right
│ by shiny in The Deck                         │
```

There is no separate banner saying you may edit something. Seeing the menu at
all is what tells you that.

- Quiet, not raised: transparent, no border, a muted icon that darkens on
  hover, focus and while the menu is open.
- Items in order: edit, add photo, the state changes, then a divider, then
  delete last.
- Rendered only when the member may edit the record.
- One menu per page. No second dropdown further down, and no loose buttons
  doing the same job.
- No nested dropdowns and no forms inside the menu.
- **No icons on the items** — the words are the list, and a column of little
  pictures beside them is noise. Delete is the exception: it keeps its icon
  and its red, so the one dangerous item still looks dangerous.
- **Items are lower case, done in CSS** (`text-transform: lowercase` on
  `.dropdown-item`). Never by calling `downcase` on the label — those strings
  are buttons elsewhere, where they read as sentence case.
- Rare actions belong in the menu rather than the page. Transplanting happens
  once in a planting's life, so it takes no permanent room in the sidebar; the
  menu item opens it in a dialog.

## Forms open over the page

Adding or changing one record opens a dialog, saves, and leaves the member
where they were. Photos, harvests, saved seeds, editing a planting and marking
one finished all work this way.

- The dialog is the whole form, not a picker that then navigates away.
- It says what it is acting on: "Add photo to chives planting", not "Add a
  photo to chives".
- Icons that helped on the old form come with it — the plant-part pictures in
  the harvest dialog, for instance.
- While it is loading, it holds roughly the height it will end up, with the
  spinner centred, so it doesn't jump open when the content arrives.

## Section headings and their "add"

Every section that can take a new record carries the same control: a small
**"+ add"** button at the right-hand end of its green heading bar.

```
┌──────────────────────────────────────────────────────┐
│ Harvests                                    [ + add ]│   ← green bar
├──────────────────────────────────────────────────────┤
│ No harvests recorded yet.                            │   ← white body
└──────────────────────────────────────────────────────┘
```

- **Inside the bar**, not above or below it, and not out at the column edge.
  An "add" floating in the whitespace beside a heading reads as unrelated to
  the section it acts on.
- **A plus icon, then the word "add"**, lower case. The heading beside it
  already says what is being added, so the button doesn't repeat it: "add",
  not "Add harvest".
- **Outlined, not filled.** Transparent background with a thin white border,
  white text, smaller than the heading. It sits on the green without competing
  with it, and fills slightly on hover and focus.
- **The same control everywhere** — harvests, seeds saved, photos. A section
  with nothing to add (activities) simply has no button, and its bar is
  otherwise identical.
- **It opens the dialog**, and its `href` is the fallback for a ctrl-click or
  a member without JavaScript.

Other links in a section body are plain links, not buttons: "More photos" is a
link, and only appears when there are more photos than the page is already
showing.

## The record panel

Everything that *is* the record — its title, its facts, its photos, its
harvests, its planned activities — sits inside one subtle bordered panel. The
sidebar sits outside it.

```
┌─────────────────────────────────────────┐  ┌──────────────┐
│ 🌱 Common Thyme planting          ⋮     │  │ Grower       │
│ by shiny in The Deck · Wellington       │  ├──────────────┤
│                                         │  │ …            │
│ HARVEST MONTHS                          │  └──────────────┘
│ Not enough data on this crop yet.       │
│                                         │  ┌──────────────┐
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐             │  │ Crop         │
│ │fact│ │fact│ │fact│ │fact│             │  ├──────────────┤
│ └────┘ └────┘ └────┘ └────┘             │  │ …            │
│                                         │  └──────────────┘
│ ┌─────────────────────────────────────┐ │
│ │ Harvests                    [+ add] │ │       sidebar:
│ ├─────────────────────────────────────┤ │     outside the
│ │ No harvests recorded yet.           │ │        panel
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
      the record panel
```

Without it the page runs straight into the sidebar and reads as one flat wash
of content. The border says: this is the thing you came here for; that other
stuff is context.

- **Subtle and dark**, a hairline rather than a heavy rule, with the same
  corner radius as everything else.
- **No background of its own.** The page colour shows through, so the white
  sections inside it still stand out.
- **The hero is inside it**, with no side padding of its own, so the title
  starts on the same left edge as every section below it.
- **One spacing scale** between the sections it holds.

This is the pattern for **every record page**, not just plantings. Harvests,
saved seeds and gardens should each get the same panel around their own data,
with the sidebar outside it.

### Sections within the panel

A section is a bordered block with its green heading bar as the lid, so the
heading and the content beneath it read as one thing. Sidebar blocks use the
same vocabulary, so the two columns look related without looking identical.

Two traps:

- **Don't nest a grid card inside a section.** A partial written for
  `.index-cards` brings its own card, shadow and radius; inside a section
  that's a box in a box — a white strip under the heading, a shadow sitting
  proud of the border, an image overshooting the edge. Write a partial for
  that spot instead; flattening the card with negative margins is fighting it.
- **Give the page wrapper its own class.** `.planting` is the planting *card*,
  and its absolutely positioned badges will leak onto the page. The page is
  `.planting-show`, and the panel inside it is `.planting-detail`.

## Cards

Scrolling a mixed grid, you should know what kind of thing each card is before
reading a word of it. A planting, a harvest and a packet of seeds are three
different things and should not look alike.

Each record type has **one** `_card` partial, used everywhere that type appears
in a grid — the same card on the record's page, the member's page, the crop
page and the homepage, not a different look per page.

Cards are for **grids**. In a narrow sidebar they become one huge photo per
item, so a sidebar shows a compact row instead — a small square thumbnail, then
the one or two facts that matter there. The neighbours list is the example: the
crop is the same for every row, so each says who grows it and where.

What stays the same for the grid cards: a photo, the crop name, a link to the
record, an owner credit, and one shared corner radius (`$card-radius`, a fixed length — a
percentage draws an ellipse that changes with the card's size). Cards are told
apart by colour, proportion and texture, never by their corners.

### Planting

```
┌──────────────────┐
│                  │
│      photo       │
│                  │
├──────────────────┤
│   Cos lettuce    │
│  [harvesting now]│   ← badges
│  ▓▓▓▓▓▓░░░░ 61%  │   ← how far along it is
├──────────────────┤
│ Planted by skud  │
│ in Back Garden   │
└──────────────────┘
```

A planting is a span of time, so the card shows where it has got to: white,
green accent, badges and a progress bar.

### Harvest

```
┌══════════════════┐   ← warm accent along the top
│                  │
│      photo       │
│ 🧺               │   ← the harvest icon, on the photo
├──────────────────┤
│ Cos lettuce      │
│ harvest          │
│ ( leaf )         │   ← plant part, in the warm accent
├──────────────────┤
│ picked 3 Mar     │
│ by skud          │
└──────────────────┘
```

A harvest is an **event**: one crop, one plant part, one day. So where a
planting card shows progress, a harvest card shows the date it happened, and
the title says "\<crop\> harvest" rather than just the crop. The warm accent
and the icon are what separate it from a planting at a glance.

### Seed

```
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌   ← torn top edge
┌──────────────────┐
│ ┌──────────────┐ │
│ │  illustration│ │   ← inset window, printed frame
│ │      saved   │ │   ← the year, stamped at an angle
│ │       2026 ⟋ │ │
│ └──────────────┘ │
│  COS LETTUCE     │   ← printed band
│  seeds saved by  │
│  skud            │
│ ················ │
│ 20 SEEDS · SOW   │   ← the small print
│ BEFORE MAR 2027  │
└──────────────────┘
```

A seed card is drawn as a **seed packet**: portrait (3:4), a papery ground
rather than white, a torn strip across the top, the photo inset behind a
printed frame, the crop name in a bold printed band, and the small print along
the foot — quantity, sow-by date, organic, whether it's up for trade.

A home-saved packet has the year written on it, so ours does too: the year
saved, stamped at a slight angle in the corner of the window.

The risk with a decorative card is that it gets hard to scan in a long trading
list, so the crop name and the sow-by date stay at normal contrast; the paper,
the frame and the tear carry the theming.

## Fact cards

The small cards on a record page each hold one fact. The value slot holds
**one** thing — a number, a word or an icon — never a compound like `43/90` or
`4/5`, and the sub-line beneath always renders so the cards line up.

- Progress reads as a percentage, with "day 43 of 90" beneath.
- Quantity and what it was grown from are one card, not two both saying
  "seedling".
- Rating is stars you can click to rate, not a number.
- Say what's true: a perennial keeps growing year to year — it doesn't "grow
  back each year".

## Harvest months

Grouped into the grower's own seasons: three months each, named, starting at
*their* spring — March in the northern hemisphere, September in the southern.
Where we have no latitude, show the plain twelve-month row rather than guessing
at a hemisphere.

Whenever months or badges are highlighted to mean something, a legend says what
the highlighting means.

## Small things

The like button sits on the title line, beside the name it belongs to, at its
own size. It's a quiet control, not a raised one.
