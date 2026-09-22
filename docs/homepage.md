# Homepage

The Optima prototype's homepage (`home.html`), rebuilt to take the site's real data. Built on 17 September 2026 and tested in the preview. **Not on the site yet**: wiring it in needs the latest GravelMasterSoftware master (see [merging.md](merging.md)).

## Files

| File | What it is |
|---|---|
| `Views/Home/_HomePage.cshtml` | the new homepage, as a partial |
| `css/gm-home.css` | its styles, scoped to `.gm-home`, with a shield against the old site's CSS |
| `js/gm-home.js` | carousels, tabs and calculator |
| `ViewModels/Common/HomePageModels.cs` | `HomeBanner` and `HomeProduct` |
| `img/gm-home-*` | section backgrounds and the eight inspiration gallery photos |
| `Views/Shared/_BulkEnquiryModal.cshtml`, `css/gm-enquiry.css`, `js/gm-enquiry.js` | the bulk delivery pop-up, shared with the category page |

## Sections, and where their content comes from

| Section | Content |
|---|---|
| Hero carousel | the banners managed in the admin site (1400x467). The first loads straight away; the rest load after the page has |
| Shop our offers | 9 cards (Special Offers, Topsoil, Yorkshire Cream, Cotswold Chippings, Play Sand, Scottish Cobbles, Decorative Chippings, Blue Slate 20mm, Bark & Mulch). Photos and "From" prices come from the product data; a card whose product isn't on the site is left out |
| Quantity calculator | the live `/calculator` formulas, and its "Email results" post |
| Our Bestsellers | three tabs (Gravel & Chippings, Topsoil and Mulches, Cobbles and Pebbles) of five products each, priced from the product data |
| Reviews | the real Trustpilot widgets (Mini and Carousel) |
| Inspiration Gallery | eight photos from the prototype |
| Built for everyone | trade account sign-up (`/account/login?isTradeRegister=true`) and `/trade` |
| Supplier introduction | the page's `h1`, with links to `/about-us` and `/contact-us` |
| Bulk delivery pop-up | "Enquire Here", posting the product page quick enquiry's fields to `/basket/sendlooseenquiry` |

Which products the offer cards and bestseller tabs show is set in a list at the top of `_HomePage.cshtml`.

## What it keeps from the old homepage

- **Prices from the product data.** The old homepage had its prices typed in, and some had drifted (Panda Gravel's trade price showed £106, not £100). Customer and trade prices both render; the existing `/product/istrade` check in `_Layout` shows the right one.
- **"From" prices ignore sample products**, so the £25 Sample Box doesn't become the Gravels & Chippings "From" price.
- **The calculator's formulas are the live ones**, checked against the live code on 24 measurements:

  | Type | Formula (as live) | Shows |
  |---|---|---|
  | Gravel & Chippings | 1.7 tonnes per m³ | weight; 1 tonne pallets; bulk bags (count assumes 800kg per bag) |
  | Barks & Mulches | 350kg per m³ | volume; 1m³ bulk bags |
  | Topsoil | 1.5 tonnes per m³ | weight; pallets (1,400kg each); bulk bags |
  | Sand | m³ ÷ 0.0015 kg | weight; one pallet or bulk bag per m³ |

  Two of these look wrong; see [open-questions.md](open-questions.md).
- **The old homepage's tiles** (Deals, Cotswold, Scottish Cobbles, Top Soil) and its 10-tonne phone band are folded into the offers and calculator sections.

## Changes from the prototype

- The offer roundel says **"FROM"**, not "NOW FROM": the prices are the normal product prices, not a reduction.
- The phone-width rule that squashed hero images to 3:4 is removed, because it distorted the real 1400x467 banners.

## Accessibility

- Hidden carousel slides are taken out of the Tab order; the carousel pauses on hover and focus.
- The offers and gallery sliders scroll a focused card into view, and adjust when the window is resized.
- The bestseller tabs use ARIA tab roles and arrow keys.
- The enquiry pop-up moves focus to its first field when it opens, closes with Escape and returns focus to the button that opened it. Tab can still move out of it to the page behind; unlike the mobile menu, it doesn't keep focus inside yet.
- Form messages are announced (`aria-live`).

## Tested

In the preview at 1440, 1100, 1000, 900, 861, 860, 768, 560 and 375px wide: layout, sliders, tabs, the calculator (all four types, every unit) and the enquiry pop-up's checks and the data it sends. The preview blocks the real posts, so the "sent" messages haven't been seen against the live site yet.

## Still to do

Needs the GravelMasterSoftware repository; listed in [merging.md](merging.md#homepage).
