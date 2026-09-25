# Search results page

The page the header's search box goes to, `/search?searchphrase=…`, in the new design. There's no Optima prototype for it, so it's made from the category page's parts: its intro band and its product cards, four across without the sidebar. Built on 25 September 2026 and tested in the preview. **Not on the site yet**: wiring it in is listed in [merging.md](merging.md#search-results-page).

## Files

| File | What it is |
|---|---|
| `Views/Category/_SearchPage.cshtml` | the new page, as a partial that shows a `SearchPageModel`. It's next to the search's own view, `Views/Category/DisplayProducts.cshtml` |
| `ViewModels/Common/SearchPageModels.cs` | `SearchPageModel`; its products are the category page's `CategoryProduct`s and its category links `CategoryLink`s |
| `css/gm-search.css` | the search page's own styles, scoped to `.gm-search`: the shorter intro band, four columns, and the help panel |
| `js/gm-search.js` | puts what was searched for back into the header's search box |

The page sits inside `.gm-category` as well as `.gm-search`, and loads `css/gm-category.css` before its own stylesheet. So the shield against the old CSS, the intro band and the cards are the category page's own rules, not copies. The card's markup is a copy of the category page's (about a dozen lines, with its own image `sizes` for four columns); a change to one should go to the other.

## How the search works (unchanged)

Read from `CategoryController` (in `Controllers/BrandController.cs`: the two controllers' file names are swapped), `Views/Category/DisplayProducts.cshtml`, `Views/Shared/DisplayProductsComponentLarge.cshtml` and `ProductRepository`. These files are the same on `master` and `stripe`, and the live results match them (checked on ten searches).

- `/search?searchphrase=slate` and `/search/slate` both go to `CategoryController.Search`.
- It lists every product on sale whose **name** contains what was typed, ignoring capitals. It doesn't look at descriptions, and it looks for the whole phrase as typed: "slate chippings" finds the slate chippings, "chippings slate" finds nothing.
- Seven searches ("cement", "post mix", "postmix", "fence crete" and so on) always give Post Mix Concrete.
- It shows one page of at most 100 products. There's no link to a second page, so a search matching more (e.g. "e" matches 132 products) only shows 100.
- The tiles are ordered by `TaxRateID`, and any product named "Top Tee" or "Pro Turf" is left out, so searching "turf" doesn't show the turf ([open question](open-questions.md#search-results-page)).
- Nothing typed (`/search?searchphrase=`) lists the first 100 products. `/search` with nothing after it gives an error page.

The new page shows exactly the products the old one did, in the same order: the old view's code fills the model from the same list ([merging.md](merging.md#search-results-page)).

## What the old page shows, and where each part went

| Old page | New page |
|---|---|
| An empty `<title>` and the meta description ", . Providing a wide variety of affordable " | "Search results for slate \| GravelMaster" and "GravelMaster products matching slate" ("All products" when nothing was typed). Set by the new branch of `DisplayProducts.cshtml` |
| A breadcrumb "Products > Category", whose link goes nowhere (`#`) | "Home > Search results" |
| `'slate'` as the heading, with the search put into the page as it was typed | "Search results for “slate”" and "10 products found". The search is encoded wherever it's shown |
| The old tiles: photo, name, short description, "Prices from" customer and trade prices, "Shop now" | The category page's cards with the same content: "Price (inc. VAT & delivery)", "From" customer and trade prices, and the "Trade price" badge for trade customers (by `_Layout`'s `/product/istrade` check, as on the category page) |
| Nothing at all when nothing matched | "We couldn't find any products matching “xyzzy”", what the search looks at, three example searches (gravel, slate, bark: each finds products), the eight categories and the phone number |
| Nothing to say when more than 100 matched | "Showing the first 99 products" at the top, and the same help under the products ("Looking for something else?") |

## Choices

- **No sidebar.** The category page's sidebar holds its filters, delivery message, PayPal message and trade card. The search has no filters, so the products get the full width: four across on a desktop (the cards are the same size as the category page's three beside its sidebar), then three, two and one, at the category page's breakpoints.
- **No Sort by.** The old search had none, and the server ignores a sort for searches.
- **The header's box is filled in** with what was searched for (desktop and the mobile menu), so a customer can change it and search again. It's left alone if the browser has already put something back in it.
- **The example searches** in the "nothing found" help are links, and each finds products (gravel 9, slate 10, bark 4 on 25 September 2026).
- **Colours** are the category page's. The new category links are white with a dark green edge (4.2:1 against the panel, 4.7:1 against the white inside), and turn the card button's green when pointed at.

## Found while building it

- **Searches aren't hidden from search engines, and have no title.** The live search page has an empty title and a broken description, and nothing asks Google not to list it. The new branch gives it a title and description; whether to add "noindex" is an [open question](open-questions.md#search-results-page).
- **The customer price isn't hidden for trade customers** (live now, on every page with prices). `_Layout`'s `/product/istrade` script hides the customer prices with `style.display = "none !important"`. A browser ignores that value (checked in Edge: it leaves `display` empty), so for a trade customer the customer price stays in its place, invisible, and leaves a gap before the trade price. See [open questions](open-questions.md#search-results-page).
- **Search service keys in the code.** Both controller files have an Azure Search admin key written into them (the search no longer uses Azure Search; the code is commented out or unused). See [open questions](open-questions.md#search-results-page).
- **A search with "<" and a letter in it** (e.g. "<b>") gives an error page on the live site: ASP.NET's own check against unsafe input stops the request before the page. The new page doesn't change that.

## Tested

On 25 September 2026.

- **Compiling.** The partial compiles with MVC 5.2's Razor. So does `DisplayProducts.cshtml` with its new branch ([merging.md](merging.md#search-results-page)), against stand-ins copied from the repository's own `PagedList`, `HtmlExtensions`, `BaseViewModel`, `MasterLayoutViewModel`, `CategoryViewModel`, `ProductViewModel` and `CategoryProductsViewModel`.
- **Running the compiled views** with sample data, outside IIS:
  - the new branch of `DisplayProducts.cshtml`, for 106 products paged at 100: it left out Pro Turf and Top Tee, kept the old order (by `TaxRateID`, otherwise as given), set "more matched", built each photo address and link, put the categories in menu order, took the search from `/search/<phrase>` before `?searchphrase=` (as MVC gives it to the controller), and set the title and description ("Slate " is shown as "Slate");
  - with the new design switched off, it drew the old page;
  - the partial for results, nothing found, nothing typed, more than one page, and a search of `"><script>alert(1)</script> & <b>x</b> 'onmouseover='y`: encoded in the heading, the help and the `data-` attribute.
- **Against the live search**, in the whole-website preview: gravel, xyzzy, post mix, cement, turf, e, nothing typed, `/search/slate` and @home each showed the same products, in the same order, as the live page.
- **In headless Edge** (the preview on port 8781):
  - screenshots at 1440, 1024 and 390px (results, nothing found, the end of a long list, a 60-letter search);
  - nothing wider than the screen at 12 widths from 1440 to 320px, for five searches including the 60-letter one; four, three, two and one columns at the breakpoints;
  - every text colour measured against its background: all pass AA (the lowest is the product names' green, 4.5:1, which as large text needs 3:1); the category links' edges 4.2:1;
  - the header's search box (and the mobile menu's) filled in, including "B&Q "quoted" @home";
  - Tab reaches the example searches, the category links and the cards, each with the category page's focus outline;
  - no script errors on four searches.
- The category preview was byte-for-byte the same on five live category pages and `old-body.html` after its tile reader moved into `ConvertFrom-OldProductTiles`.

Not tested: the page on the real site (the test website), and a trade login (trade prices and the badge; the preview is never signed in).
