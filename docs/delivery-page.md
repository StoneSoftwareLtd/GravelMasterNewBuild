# Delivery page

The site's delivery information page, `/delivery`, in the new design. There's no Optima prototype for it, so it's in the Trade Accounts page's style, with the live page's own words. Built on 25 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#delivery-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_DeliveryPage.cshtml` | the new page, as a partial with no model: its words are written into it, as the About and Trade pages' are |
| `css/gm-info.css` | the styles, shared with the [calculator page](calculator-page.md) and meant for the other content pages still to do: the trade page's shield, hero card, buttons and FAQs, scoped to `.gm-info` |
| `img/gm-delivery-hero.jpg` | the live page's kerbside photo (`img/gravel-delivery.jpg`) at 900px wide: 131 KB, down from 283 KB at 1366px |

No script: "Track your order" opens the site's own Track Order pop-up, as the header's link does.

## Where the page comes from

`/delivery` has no view of its own. `ContentController.Display` finds the content with the key `delivery` in the admin site and shows it through `Views/Content/Display.cshtml`, which every such page shares (privacy, and the others without their own view). So the live page's words and layout are HTML typed into the admin site.

The new page has those words written into the partial instead, in the same order. `Display.cshtml` shows it only for the `delivery` key with the new design on; every other page it shows keeps its admin content ([merging.md](merging.md#delivery-page)). The page's title and description still come from the admin site. Changing the words now needs a developer, as on the About and Trade pages: an [open question](open-questions.md#delivery-page).

## What the old page shows, and where each part went

Read from the live page's HTML on 25 September 2026.

| Old page | New page |
|---|---|
| A banner picture with "Delivery" | The hero card: "Delivery information", the first two paragraphs, "Track your order" and "Call 0330 058 5068", and the kerbside photo |
| "All Internet Deliveries are made via Tail-Lift Vehicles, as shown below. We do not use Cranes or Hi-Abs", and the pallets and vehicles paragraph | The same, in the hero, without "as shown below" (the pictures it pointed to are gone) |
| "Checklist before placing your order": six points beside the kerbside photo | The same six points, with ticks, in a card of their own |
| A wide photo of a lorry with "Delivery Truck Size" drawn on it | Left out: the words drawn on the photo cover part of the lorry, so it can't be cropped clean |
| "Key Delivery Questions": four pictures with their words drawn in (No Hi-Abs, Kerbside Delivery, No Soft Ground, Contactless Delivery), each with a heading and a paragraph | Four cards with the same headings and paragraphs, and new icons (lorry, house, pallet truck, pen) in place of the pictures |
| "How do we deliver to you?", then Delivery Vehicle, Offloading your products, Possible Restrictions and Contact | The same, as a heading and four blocks in the same order. "Terms and Conditions" now links to them (`/term-conditions`), and the phone number can be tapped |
| "Delivery Terms" and "Returns": six paragraphs each | The same, side by side in two cards (one above the other on phones). The email address can be tapped |
| A picture of a lorry with the logo at the bottom | Left out: it looks like a mock-up rather than a GravelMaster lorry |

Every heading, paragraph and list item of the live page was checked against the new page in the preview, ignoring capitals and punctuation: all of them are there word for word except the first heading's "as shown below". Other changes: headings in sentence case, full stops where a paragraph had none, and "(option 2). Please note" where the live page ran the two sentences together.

## Tested

In the whole-website preview (`/delivery`) on 25 September 2026.

- The partial compiles with MVC 5.2's Razor. So does `Display.cshtml` with its new branch ([merging.md](merging.md#delivery-page)), against stand-ins copied from the repository's `ContentViewModel`. Run with sample data and a stand-in for `_Layout`: with the new design on, `delivery` (and `Delivery`) showed the new page with `gm-info.css` in the head and not the admin content; `privacy` with the design on, and `delivery` with it off, showed their admin content and no `gm-info.css`.
- The words: every block of the live page's text is on the new page (above).
- In headless Edge: screenshots at 1440 and 390px; nothing wider than the screen at 12 widths from 1440 to 320px (at 320px the email address now breaks rather than running 9px off); the breadcrumb and every section start at the same line.
- Every text colour passes AA, the lowest 4.8:1 (the "Delivery" label on the hero card); the icons' circles 6.4:1 and the ticks 4.3:1 against what's behind them.
- "Track your order" opened the Track Order pop-up, at 1440 and 390px, without changing the address; the photo loaded; no script errors.

Not tested: the page on the test website.
