# Progress log

Every step, oldest first. Add a new entry for each step. The commit history has the detail of each change.

## Before 17 September 2026: the new-chrome branch

The GravelMasterSoftware branch **new-chrome** (8 commits) ported the Optima prototype's header, footer and mobile menu into the site behind a `UseNewChrome` setting. Its changed files and a patch were supplied as a zip on 16 September 2026.

Commit: *Add the new-chrome header and footer package as received*.

## 17 September 2026: header and footer reviewed and fixed

Reviewed the package against the live site and fixed five problems, one commit each:

1. Enter in the search box didn't search.
2. `gm-chrome.css` changed Bootstrap's colour variables for the whole page.
3. The closed mobile menu could still be reached with Tab, and focus wasn't managed.
4. The payment cards image was five times too big, and header and footer images had no dimensions.
5. The mega menu read the whole product list 12 times per page.

Each was tested in a static preview at seven widths from 1440px to 375px. Details: [header-and-footer.md](header-and-footer.md#fixes-made-on-17-september-2026).

Also found: the live site's `_Layout.cshtml` is newer than the branch's master, so the branch has to be redone on the latest master before merging. See [merging.md](merging.md).

## 17 September 2026: previews

- **Saved pages for VS Code Live Server**: `preview/tools/build.ps1` builds pages from the `.cshtml` files with the live site's menus, products and stylesheets.
- **Whole-website preview** on http://localhost:8780: live pages with the new header and footer swapped in, read-only, so it's possible to click around the real site. Clicking around found that the "page not found" page has its own copy of the old header ([merging.md](merging.md)).
- **`Start website preview.cmd`** to start it with a double-click.

Details: [preview/README.md](../preview/README.md).

## 17 September 2026: homepage

Rebuilt the prototype's homepage as `_HomePage.cshtml` with real data: admin banners, prices from the product data, the live calculator formulas and enquiry posts, and the real Trustpilot widgets. Tested in the preview at nine widths. Details: [homepage.md](homepage.md).

Raised for a decision: the sand calculator formula, trade prices above retail, 1MB banners, prototype colour contrast and a small gallery photo. See [open-questions.md](open-questions.md).

## 22 September 2026: this repository

- Put the work into this repository, with the history rebuilt as one commit per step from the original zip and the finished files.
- Fixed the preview scripts' text encoding (the saved pages showed "previewâ€¦").
- The "rebuild and watch" task now also rebuilds when the homepage partial changes.
- Wrote these documents.

## 22 September 2026: category page

Rebuilt the prototype's category page as `_CategoryPage.cshtml`, for every category, subcategory and filtered page. Details: [category-page.md](category-page.md).

1. Mapped what the live category pages do (six pages checked) and how each part fits the prototype.
2. Moved the homepage's bulk enquiry pop-up into a shared partial so the category page can use it, and made Tab stay inside it while it's open.
3. Added `CategoryPageModel` and `CategoryDescription.Parse`, which splits a category description into its "Ideal for" uses, intro and "Read more" part. Tested on six live descriptions.
4. Built the page: the live filters (as links, shown as the prototype's checkboxes), Sort by, every product with customer and trade prices, the description with Read more, the promo card, trade card, PayPal message and the bulk banner.
5. The previews now show it on every live category page, and let Sort by through to the live site (the only form they pass on).

Found and fixed along the way:

- the old base CSS hides every `<nav>` below 900px wide, which would have hidden the breadcrumb;
- the promo card broke the order of sorted pages, so it now shows in the default order only;
- PayPal hid its message in the 280px sidebar, so it now uses the style that fits.

Raised for a decision: "Ideal for" icons, which product each promo card shows, the old left-column images, a real delivery countdown, Klarna, and some of the prototype's colours. See [open-questions.md](open-questions.md).

## 23 September 2026: page weight and colour contrast

Answering open questions: the prices and the quantity calculator stay exactly as they are.

- **Page weight.** The header logo was 600x200 (78 KB) for a 192x64 space, and is now 384x128 (37 KB). The widest gallery photo is capped at 860px (181 KB to 148 KB) and the advisor photo re-encoded (29 KB to 23 KB). The other gallery photos were left alone: re-encoding them saved less than 15%, which is not worth the quality loss. The gallery photos now carry their sizes so the page does not jump as they load, images decode off the main thread, and the homepage script is deferred.
- **The admin site's banners are the homepage's real weight**: six PNGs, 5.6 MB in total. Optimised JPEGs of the same 1400x467 size, 911 KB in total, are ready to upload; see [open-questions.md](open-questions.md).
- **Colour contrast.** Ten text and icon colours on the homepage and category page, and five in the header, footer and mobile menu, were below WCAG AA. All now pass, measured against the colour behind them. On orange the text is near-black rather than white, which keeps the brand colour and reads better than a darker orange would. The worst was the mobile menu's yellow category name at 1.9:1.
- Left for a decision: white on the header's main green is 3.04:1, and changing it means changing the site's dominant colour.

## 23 September 2026: product page

Rebuilt the prototype's product page (`product2.html`) as `_ProductPage.cshtml`, for every product. The GravelMasterSoftware repository is on this PC now, so the page was mapped from the real code as well as the live pages. Details: [product-page.md](product-page.md). The quantity calculator section is still to do.

1. Mapped what the live product page does, from `Detail.cshtml`, its script, the product controller and the basket's add-to-basket action, checked on eight live pages, and where each part goes in the prototype.
2. Added `ProductPageModel` and `ProductDescription.Parse`. The live descriptions follow the prototype's layout already (intro, a list of "Label: value" lines, then "Colour and Shape" and "Availability"), so Parse splits them into the intro, the specification table, the uses and the other sections. A section that has anything besides those lines is shown as written. Tested on the eight live descriptions and edge cases; `GetPostcodeArea` tested on full, partial and invalid postcodes and areas the site doesn't deliver to.
3. Made each piece of a split description whole. Cutting at the headings split Blue Slate's `<div><h3>Loose Load Deliveries</h3>...</div>`, and the stray `</div>` closed the page's own layout, so the reviews and everything after them fell outside it. `ProductDescription.Balance` drops closing tags with nothing to close and closes what's left open. Also added what the page turned out to need: the basket address, the category name, and each size's code and base price (for the analytics events).
4. Built the page (`_ProductPage.cshtml`, `gm-product.css`, `gm-product.js`, `img/gm-prod-*`): photos with the video and 360&deg; view as extra thumbnails, the three steps (postcode, size, quantity) priced by the live site's own price lookup, the sample, the delivery date, Add to cart posting exactly what the old form posted, the basket pop-up, the description panels, the delivery panel, Trustpilot, and "You might also like". It sends the old page's three Google Analytics events with the same fields. The view was compiled with MVC 5.2's own Razor, which caught two mistakes before they could reach the site.
5. The whole-website preview now shows the new page on every product page, with real prices from the live site's price lookup. `preview/tools/product-page.ps1` reads an old product page and fills in the partial; it runs the real C# model rather than a copy, so the preview can't drift from the site. Ran it over all 153 live products.

6. Wrote up the page, the merge steps and the questions.
7. Recording a walkthrough for Mollie showed blank thumbnails on some products: the 300px photo files only exist for some products, while every photo has a 330px one. Thumbnails now use 330px (preview and merging.md). The preview's check for Razor left in a page now also catches C# statements without an `@`, which it missed once while the preview was running an older script.

Found and fixed along the way:

- the stray `</div>` from splitting descriptions (step 3);
- out-of-stock products with no sizes said "can't be ordered online"; they now say "Out of stock", as the old page does;
- "You might also like" showed the bird feeder twice on Accessories, and a product among its own suggestions;
- keyboard focus was lost after confirming a postcode.

Found on the live site: seven slate descriptions have a phone link that dials a different number from the one shown, and the controller deletes dashes from descriptions ("30-50cm" shows as "3050cm").

Raised for a decision: the random "purchases during last 24 hours" pop-up, the rating, badge and selling points the site has no data for, add-ons, use icons, the delivery panel's wording, the basket pop-up's old styling, the two live content problems, and Blue Slate's photos. See [open-questions.md](open-questions.md#product-page).

## 24 September 2026: getting ready to integrate

Decided to put the three finished pages into the site before building more. Checking the GravelMasterSoftware repository first found:

- this PC can't build or run the site (no Visual Studio, MSBuild, IIS or SQL Server), so the integration can be written and compile-checked here, but tested only on a test website;
- no branch matches the live site: the layout is `stripe`'s, the product page is partly `master`'s. The deployed code needs pushing before the integration starts ([merging.md](merging.md#before-anything-which-code-is-live));
- the test website will use a copy of the live database; where it runs is still to decide.

## 24 September 2026: product page calculator

1. Fixed the preview homepage, which had had no script since 23 September: the homepage's script tag gained `defer`, and the preview's build only looked for the tag without it, so it silently left the script out (no carousels, tabs or calculator). It now accepts attributes and stops with an error if the script is missing. The site's own partial was never affected.
2. Moved the homepage's quantity calculator into a shared partial (`_QuantityCalculator.cshtml`, with `QuantityCalculatorModel`, `gm-calc.css` and `gm-calc.js`), unchanged, so the product page can use it too. The homepage was measured before and after: the same results for 24 calculations (every type and unit), and the calculator's 53 elements in exactly the same place, size and colour at 1440, 860 and 375px.
3. Added the calculator to the product page, between the buy box and the product details, on the products whose live page has one, set to the product's type (`QuantityCalculatorModel.ForProduct`: gravel and slate use the gravel formula, bark the bark and mulch one, soil the topsoil one). Checked on eight products against the calculator their live pages show.
4. On phones the calculator's "Or" was left at the end of the first result's line: the site's real labels ("Pre Packed Pallets (56 x 25L)") are too long for both results to share a line, unlike the prototype's short ones. Below 560px "Or" now has its own line, so the results stack. Checked: unchanged at 1440 and 860px.

## 24 September 2026: About us page

While the live code is being put on a branch, carried on with the prototype's pages that don't depend on it. Rebuilt the prototype's About page (`about.html`) as `Views/Content/_AboutPage.cshtml` for `/about-us`. Details: [about-page.md](about-page.md).

- The live page is text written into its view, with nothing from the database, so the new page is a partial with no model. The live page's paragraphs replace the prototype's placeholder text, word for word.
- The hero and team photos went from 2.1 MB to 208 KB at the same sizes; the inspiration photos are the homepage's.
- White text on the blue band was 2.8:1 and the "Since 2008" badge let the photo show through, so both were darkened just enough to pass AA. Every text colour on the page was measured.
- Fixed two CSS mistakes carried over from the prototype: on phones the trust row sat above the photo instead of below it, and the "About Gravelmaster" label showed as grey body text.
- The team arrows show only when the cards scroll (phones), and follow resizing.
- The preview shows it at `/about-us`. Checked at 1440, 1024, 768 and 390px, and the team arrows clicked through in headless Edge. The partial compiles with MVC 5.2's Razor.

Raised for a decision: the out-of-date "31-years", the hero photo (looks like stock, and small), Harvey Finlayson (not on the live team page), the live content left out, and the blue. See [open-questions.md](open-questions.md#about-us-page).

## Next

- Wire the finished pages into the site, once the code that's live is on a GravelMasterSoftware branch and there's a test site ([merging.md](merging.md#before-anything-which-code-is-live)).
- The prototype's other pages: trade, then basket, checkout and confirmation. The basket and checkout take payments, so they're best built against the live code on a test site.
