# Category page

The Optima prototype's category page (`gravel-master-category.html`), rebuilt to show the site's real categories, subcategories and filtered pages. Built on 22 September 2026 and tested in the preview. **Not on the site yet**: wiring it in needs the GravelMasterSoftware repository (see [merging.md](merging.md#category-page)).

## Files

| File | What it is |
|---|---|
| `Views/Shared/_CategoryPage.cshtml` | the new category page, as a partial that shows a `CategoryPageModel` |
| `ViewModels/Common/CategoryPageModels.cs` | `CategoryPageModel` and its parts, and `CategoryDescription.Parse` |
| `css/gm-category.css` | its styles, scoped to `.gm-category`, with a shield against the old site's CSS |
| `js/gm-category.js` | Sort by, and the phone filter drawer |
| `img/gm-cat-*` | the four "Ideal for" icons and the two backgrounds |
| `Views/Shared/_BulkEnquiryModal.cshtml`, `css/gm-enquiry.css`, `js/gm-enquiry.js` | the bulk delivery pop-up, shared with the homepage |

The partial takes a small model of its own, rather than the category controller's view model, so it could be built and previewed without the repository. The category view fills it from its own data (see [merging.md](merging.md#category-page)).

## What the live category pages do, and where each part went

Checked on six live pages on 22 September 2026: Gravels & Chippings, its Slate Chippings subcategory, Gravels & Chippings filtered to Black, Topsoil and Mulches, Accessories, and Bulbs.

| Live page | New page |
|---|---|
| Breadcrumb (a subcategory links back to its parent) | The prototype's breadcrumb, starting from Home |
| `h1`, and the description from the database: "Ideal for: ..." heading, intro, and a longer part behind **Read More / Read Less** | The intro band: heading, intro, the longer part behind **Read more / Read less**, and the "Ideal for" uses as the prototype's icon list |
| Filters (Colour, Price Range, Size, depending on the category). Each option is a link; choices stack up in the address (`/garden-chippings/products/filter-colour-black-2/filter-size-10mm-55`), and a chosen option's link takes it off. Some filtered pages have their own heading and description | The same links, shown as the prototype's checkboxes, in groups that open and close. "Clear all filters" goes back to the unfiltered page. Filtered pages keep their own heading and description |
| **Sort by**: Relevance, Name, Price (Low to High), Price (High to Low), posted back to the same address | The same form. It now shows the sort in use (the old one always went back to "Relevance") |
| Product tiles: photo, name, short description, "From" customer and trade prices, trade badge, "Shop now". All products on one page | The prototype's cards with the same content. `_Layout`'s `/product/istrade` check shows the right price and the "Trade price" badge |
| "Order before 12:00PM for next day delivery" | The prototype's delivery box, with the same message |
| PayPal's Pay in 3 message | The same, in the prototype's payment spot |
| Six promo images in the left column (delivery, a turf article, Instagram, play sand, ITV, the blog) | Left out: the prototype has the trade card there instead. See [open-questions.md](open-questions.md) |
| Phones: a Filter button opening a slide-in menu, and a Sort dropdown | The prototype's sticky "Filters" bar and drawer; Sort by stays above the products |

New from the prototype: the trade card ("Get trade prices", linking to trade sign-up), the promo card in the grid, and the "Ordering 10 tonnes or more?" banner, which opens the same bulk enquiry pop-up as the homepage.

## Choices

- **"Ideal for" icons.** The prototype has four (mulch, aquatics, landscaping, pond and water features), made for Slate Chippings, whose uses match them exactly. Other categories' uses (e.g. Driveways, Pathways, Borders) get the icon for a matching word, or a tick. The list is at the top of `_CategoryPage.cshtml`.
- **Splitting "Ideal for".** "Schools, Nurseries and Home Play Areas" becomes three uses. A list with no commas stays whole ("Construction and Landscaping Projects"), because its "and" may be part of a single use.
- **Promo card.** Each category can highlight one product (listed at the top of `_CategoryPage.cshtml`): Flamenco Gravel on Gravels & Chippings, as in the prototype, and the homepage offers' picks for Slate Chippings, Topsoil and Mulches, and Cobbles (and Scottish). It takes that product's place, after the first five cards, and says "FROM" as on the homepage. It only shows on the unfiltered page in the default order, so filtered and sorted pages list exactly what was asked for.
- **Klarna** is left out: the prototype shows it, but the live category pages don't mention it.
- **The countdown.** The prototype's "Order in the next 2h 50m for delivery on Wednesday 11th March" is a placeholder. The page shows the live site's fixed message until there's a real cut-off rule to count down to.
- **No JavaScript needed** for Read more and the filter groups (they're `<details>`), or for the filters themselves (links).

## Found and fixed while building it

- **The old base CSS hides every `<nav>` below 900px wide.** It turns `nav` into an off-canvas panel (`position: fixed; left: -100%`), and from 900px up fixes it at 50px tall. The new header already guarded against this; the category page's shield now does the same for its breadcrumb. Without it the breadcrumb would have vanished on phones and tablets.
- **PayPal hid its message** in the 280px sidebar, because the inline-logo style needs 350px. The message now puts the logo above the text, which fits.
- **The old page's PayPal message** was set up with `data-pp-amount="ENTER_VALUE_HERE"`, a leftover placeholder. The new page doesn't send an amount.

## Accessibility

- Breadcrumb as an ordered list, with the current page marked.
- Chosen filters say "(chosen, select to remove)" to screen readers.
- The phone filter drawer moves focus to its close button, keeps Tab inside while open, closes with Escape or the backdrop, and returns focus to the Filters button. While closed, its links can't be reached with Tab.
- Visible focus outlines on links, buttons, Read more and Sort by.
- A hidden "Products" heading keeps the page's heading order.

## Tested

- `CategoryPageModels.cs` compiled with the .NET Framework 4 C# compiler (warnings as errors). `CategoryDescription.Parse` was checked on the six live descriptions, with and without the old wrapper, and edge cases.
- The saved page (`preview/category.html`) was compared with the prototype at 1440, 1100, 860 and 375px wide. Sidebar, grid columns, cards, promo card, banner and breakpoints match; heights differ only where the real text is longer.
- In the whole-website preview, against the live site: all 8 categories and 4 subcategories, a three-filter page and a price filter; choosing and removing filters; Clear all; Sort by (cheapest first after "Price (Low to High)"); the phone filter bar and drawer; PayPal's message; customer prices shown and trade prices hidden when not logged in as trade; no script errors from the new page.
- A filter combination with no products shows "No products match these filters" with a Clear all link (tested offline; no live filter combination was empty).

Not tested yet: a trade login (the preview never logs in), and the page inside the real site (needs the repository).
