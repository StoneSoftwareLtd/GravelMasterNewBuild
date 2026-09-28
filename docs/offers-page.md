# Special offers page

The site's special offers page, `/special-offers`, in the new design. The new homepage's "Special Offers" banner and the calculator page's card link to it, and it's in the sitemap. There's no Optima prototype for it, so it's the [search results page](search-page.md)'s layout: the category page's intro band and product cards, full width. Built on 28 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#special-offers-page).

## Files

| File | What it is |
|---|---|
| `Views/Product/_OffersPage.cshtml` | the new page, as a partial that shows an `OffersPageModel` |
| `ViewModels/Common/OffersPageModels.cs` | `OffersPageModel`: the products as the category page's cards, and the categories to offer when there are none |
| `css/gm-category.css`, `css/gm-search.css` | the category and search pages' styles, which it shares, so the cards look exactly like theirs |

No script of its own.

## Where the page comes from

`/special-offers` is `ProductController.SpecialOffers`, which renders `Views/Product/SpecialOffers.cshtml` with the products from `GetFavouriteProducts()` (one page of up to 5,000). The view shows them with `DisplayProductsComponentLarge`, the same tiles the old search results use: so the new page reads them the same way as the new search page (in the same order, leaving out any named Top Tee or Pro Turf).

**There are no offers on it.** The 38 products (on 28 September 2026) are popular gravels, slates, soils, bark and salt at their normal "From" prices: no reduced prices, "was" prices or badges, old page or new ([open question](open-questions.md#special-offers-page)).

## What the old page shows, and where each part went

| Old page | New page |
|---|---|
| "Special Offers" (a small heading) | The intro band: breadcrumb, "Special offers" as the page's heading, and how many products |
| The product tiles | The category page's cards, four to a row, with the same products, prices (customer or trade, by `_Layout`'s check) and links |
| An empty grid, if there were no products | "There are no special offers at the moment", with the categories and the phone number |

The page's title is "Special Offers", as on the live page (master's view says "SpecialOffers").

## Tested

In the whole-website preview (`/special-offers`, and `/special-offers?empty=1` for a page with no products) on 28 September 2026.

- The partial compiles with MVC 5.2's Razor. So does `SpecialOffers.cshtml` with its new branch ([merging.md](merging.md#special-offers-page)), against the stand-ins copied from the repository's classes for the search page. Run with sample data (39 products, one of them turf): with the new design on, it built the model with 38 products in the old grid's order (by tax rate, turf left out), their links, photos and prices, the categories in menu order, the title "Special Offers" and both stylesheets in the head; off, the old page.
- The page the preview shows, with the live page's 38 products and with none, is character for character the one the compiled partial makes.
- In headless Edge: screenshots at 1440 and 390px, and with no products; nothing wider than the screen from 1440 to 320px; four, three, two and one cards a row as the page narrows; the photos load; no script errors. The colours are the search page's, which were checked there.

Not tested: the page on the test website, and trade prices with a trade login.
