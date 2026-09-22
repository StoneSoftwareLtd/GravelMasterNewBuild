# Category page: plan

The next piece: the prototype's category page (`gravel-master-category.html`) in place of the old category pages, keeping everything they do.

## What the live category pages do

Checked on six live pages: Gravels & Chippings, its Slate Chippings subcategory, Gravels & Chippings filtered to Black, Topsoil and Mulches, Accessories, and Bulbs.

- **Breadcrumb**: a top-level category shows just its name; a subcategory links back to its parent.
- **Heading and description**: the `h1`, then the category description from the database: an "Ideal for: ..." heading, an intro paragraph, and a longer part (types, uses, care, related articles) behind a **Read More / Read Less** button.
- **Filters**: the groups depend on the category (Gravels & Chippings: Colour, Price Range, Size; Accessories: Colour, Price Range; Bulbs: none). Each option is a link, and choices stack up in the address, e.g. `/garden-chippings/products/filter-colour-black-2/filter-size-10mm-55`. A chosen option is marked `selected`, and its link takes that filter off. Some filtered pages have their own heading and description, e.g. "Black Gravels & Chippings".
- **Sort by**: Relevance, Name, Price (Low to High), Price (High to Low). Changing it submits a form (POST) to the same address.
- **Product tiles**: photo (lazy-loaded), name, short description, "Price including delivery", "From" customer and trade prices (the site-wide `/product/istrade` check shows the right one), a trade badge for trade customers, and "Shop now". All products are on one page, with no paging: 40 on Gravels & Chippings, 27 on Topsoil and Mulches, 24 on Accessories, 22 on Bulbs, 8 on Slate Chippings.
- **Left column**: "Order before 12:00PM for next day delivery" (the same fixed text on every page), PayPal's "Pay in 3" message, the filters, then six promo images (delivery, a turf article, Instagram, play sand, ITV, the blog).
- **Phones**: a Filter button opens the filters in a slide-in menu, and there's a Sort dropdown.
- **Page script**: `/scripts/Controllers/Root/Brand/DisplayCategory.js` (Read More, the slide-in filter menu, the basket summary). So the view is probably `Views/Brand/DisplayCategory.cshtml`; to confirm in the repository.

## How the prototype's parts map onto it

| Prototype | Plan |
|---|---|
| Breadcrumb and intro band: title, text, "Ideal for" with round icons | Real breadcrumb and `h1`; the intro paragraph from the description; "Ideal for" items taken from the "Ideal for:" heading; the longer description behind "Read more" |
| Delivery countdown (placeholder "Order in the next 2h 50m for delivery on Wednesday 11th March") | The live cut-off message for now. A real countdown needs the cut-off time, working days and bank holidays |
| Filters as checkboxes, with "Clear all filters" | Keep the live filter links, styled as checkboxes: they work without JavaScript and every filtered page keeps its own address. "Clear all" goes to the unfiltered category. Groups collapse and expand |
| Klarna and PayPal badges | PayPal's Pay in 3 message, as now |
| Trade card ("Get trade prices") | Trade sign-up link, as on the homepage |
| "Showing 14 Products" and Sort by | The real count; the live sort form, restyled |
| Product cards, 3 / 2 / 1 columns | The real tiles: photo, name, description, customer and trade "From" price, "Shop now" |
| Promo tile in the grid (Flamenco Gravel, "NOW FROM £117 BULK BAG") | A highlighted product per category, priced from the data, saying "FROM" as on the homepage |
| "Ordering 10 tonnes or more?" banner | Opens the same bulk enquiry pop-up as the homepage |
| Phone filter drawer | Replaces the old slide-in filter menu |

## Decisions needed

- **"Ideal for" icons**: the prototype has four (Mulch, Aquatics, Landscaping, Pond & Water Features), but the live "Ideal for" terms differ per category (e.g. "Driveways, Pathways, Borders and General Garden Use"). Icons are needed for the live terms, or one general icon.
- **Left-column promo images**: not in the prototype. Keep, drop, or move them.
- **The promo tile**: which product each category highlights.
- **Klarna**: the prototype shows it, but the live category pages don't mention it. Leave it out unless the site offers Klarna.

## How it will be built

The same way as the homepage:

- a partial for the page, taking a small model (like `HomeProduct`), so it can be tested in the preview now and connected to the controller later;
- `css/gm-category.css` scoped to the page, and `js/gm-category.js` for Read more, the filter groups and the phone drawer;
- the whole-website preview swaps it into every live category page, filled from that page, so every category, subcategory and filter combination can be clicked through.

The preview blocks every POST, so sorting can't be tried there as things stand. It needs either a read-only exception for the sort form or a test on the real site.
