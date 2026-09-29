# Price Match Promise page

The site's `/price-match` page in the new design. There's no Optima prototype for it, so it's in the information pages' style. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#price-match-promise-page).

## Files

| File | What it is |
|---|---|
| `Views/Content/_PriceMatchPromisePage.cshtml` | the new page, as a partial with no model: its words are written into it, as the delivery page's are |
| `css/gm-info.css` | its styles (`.gm-pricematch`), with the other information pages' |

## Where the page comes from

`/price-match` has no view of its own: `Display.cshtml` shows the admin site's `price-match` content, as it did the delivery page's. The new page has those words written in, in the same order, so a change to them now needs a developer ([open question](open-questions.md#the-last-pages)). `Display.cshtml` shows it only for the `price-match` key with the new design on.

## What the old page shows, and where each part went

| Old page | New page |
|---|---|
| "Price Match Guarantee" and two paragraphs | The same, under the breadcrumb, with the phone number as a link and a "Call 0330 058 5068" button |
| "Our price match promise", "We'll Match Any Price!", a paragraph and 4 numbered steps | The same words, the steps as four numbered cards (one above another on phones), then the next paragraph |
| "Important Info!", "Gravel Master Price Match Promise", a paragraph and 4 numbered conditions ("1. UK-Based Retailers Only: We match ...") | The same, each condition as a heading and its sentence |
| "Products you may like": 4 square pictures linking to Gravels & Chippings, Play Area, Topsoil and Mulches and Winter Salt & Fuel, and 2 more pictures (cobbles, slabs) above | The same 4 links as the information pages' link cards, with the header's names; the 2 extra pictures are left out |
| A picture of a delivery at the bottom | Left out |
| Nothing | "Already ordered? You can also send us a price match message from My Account." |

The page is also now in the footer ("Price Match Promise"); nothing in the new header or footer linked to it before.

## Tested

In the whole-website preview (`/price-match`) on 28 September 2026.

- The partial compiles with MVC 5.2's Razor. So does `Display.cshtml` with the new branch, which ran with sample data: `price-match` and `Price-Match` show the new page with `gm-info.css` in the head; the delivery, privacy and other pages are unchanged; with the design off, the admin content.
- The preview's page is the same markup as the compiled partial.
- The words: every heading, paragraph and list item of the live page is on the new page word for word (the lists' numbers and headings compared piece by piece).
- Nothing wider than the screen at 8 widths from 1440 to 320px; screenshots at 1440 and 390px; no script errors.

Not tested: the page on the test website.
