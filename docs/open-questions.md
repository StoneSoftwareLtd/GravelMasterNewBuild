# Open questions

Things found along the way that need someone to decide. Nothing here has been changed on the live site.

## Data and pricing

Decided 23 September 2026: the prices and the quantity calculator stay exactly as the live site has them. The notes below are for the business to check, not code changes.

| Found | Detail | Suggestion |
|---|---|---|
| **Sand calculator looks too light** | The live calculator works out sand as m³ ÷ 0.0015 kg, about 667kg per m³. Sand is usually 1,500 to 1,700kg per m³. For 4m x 3m at 2cm deep it says 160kg; at typical sand weights it would be about 400kg. The new homepage copies the live formula. | Confirm the right figure, then fix both calculators |
| **Gravel bulk bag count** | The calculator labels bulk bags "850kg" but counts them at 800kg each (copied from the live calculator). Possibly a deliberate margin. | Confirm it's intended |
| **Trade prices above retail** | Some products' trade "From" price is higher than the customer price, e.g. Cotswold Chippings 20mm: £91 customer, £92 trade. | Check the trade price list |

## Images

| Found | Detail | Suggestion |
|---|---|---|
| **Homepage banners are heavy** (copies ready) | The admin site's banners are PNGs of about 1MB each: 5.6MB for the six on the homepage. | Optimised JPEGs, same 1400x467, 911KB for all six, are in `D:\Users\user\Documents\GravelMaster\Optimised homepage banners`. Upload them in the admin site to replace the PNGs |
| **Gallery photo 8 is small** | `gm-home-insp-8.jpg` is only 225px wide, so it looks soft on large screens. | Find a bigger original |

## Design

| Found | Detail | Suggestion |
|---|---|---|
| **Low-contrast colours** (done 23 September 2026) | Fifteen text and icon colours were below WCAG AA across the homepage, category page, header, footer and mobile menu. The worst was the mobile menu's yellow category name on white, at 1.9:1. | Fixed: on orange the text is now near-black, keeping the brand colour; elsewhere the colour itself was darkened just enough to pass |
| **White on the header's main green** | White text on the main bar (`#5ca458`) is 3.04:1, below the 4.5:1 AA needs. It was left alone because it is the site's dominant colour and the header is already signed off. | Darken it to about `#4a8346` (4.5:1), or keep the green as it is |
| **"NOW FROM" on offer roundels** | Changed to "FROM", because the prices are normal product prices, not a reduction. | Confirm |
| **Delivering to: postcode** | In the prototype's header; not ported. | Keep out, or plan how it would work |
| **LinkedIn icon** | In the prototype's footer; not ported. | Add if GravelMaster has a LinkedIn page |
| **Contact link** | The old header has one; the new header (like the prototype) doesn't. The footer has the contact details. | Decide if the header needs it |

## Category page

| Found | Detail | Suggestion |
|---|---|---|
| **"Ideal for" icons** | The prototype has four icons (mulch, aquatics, landscaping, pond and water features). The live categories' uses are wider (driveways, pathways, borders, schools, planting, gritting...), so most get a tick instead. | Design icons for the common uses, or keep the ticks |
| **Promo card products** | Gravels & Chippings shows Flamenco Gravel (as the prototype). Slate Chippings, Topsoil and Mulches, and Cobbles (and Scottish) show the homepage offers' picks. Other categories have no promo card. | Choose a product per category, or none |
| **The old left-column images** | The live category pages show six promo images down the left (delivery, a turf article, Instagram, play sand, ITV, the blog). The prototype has the trade card there instead, so they're left out. | Keep them out, or find them a place |
| **Delivery countdown** | The prototype counts down to a cut-off ("Order in the next 2h 50m for delivery on..."). The live site shows a fixed "Order before 12:00PM for next day delivery", so that's what the new page shows. | Decide whether a real countdown is wanted (needs the cut-off time, working days and bank holidays) |
| **Klarna** | In the prototype's payment badges, but not on the live category pages. Left out. | Add only if the site offers Klarna |
